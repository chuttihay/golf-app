import os
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import requests # Import for making external API calls
from flask_cors import CORS
from datetime import datetime, timezone, timedelta
from dotenv import load_dotenv
import json

# --- Database Setup ---
basedir = os.path.abspath(os.path.dirname(__file__))

load_dotenv() # Load environment variables from .env file

app = Flask(__name__)
CORS(app)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///' + os.path.join(basedir, 'golf_app.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# --- Database Models ---
class User(db.Model):
    id = db.Column(db.String, primary_key=True) # Firebase UID
    displayName = db.Column(db.String)
    email = db.Column(db.String)
    picks = db.relationship('Pick', backref='user', lazy=True)

class Golfer(db.Model):
    id = db.Column(db.String, primary_key=True)
    name = db.Column(db.String, nullable=False)

class Tournament(db.Model):
    id = db.Column(db.String, primary_key=True)
    name = db.Column(db.String, nullable=False)
    year = db.Column(db.Integer, nullable=False)
    submission_start = db.Column(db.DateTime, nullable=False)
    submission_end = db.Column(db.DateTime, nullable=False)

class Pick(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String, db.ForeignKey('user.id'), nullable=False)
    golfer_id = db.Column(db.String, db.ForeignKey('golfer.id'), nullable=False)
    tournament_id = db.Column(db.String, db.ForeignKey('tournament.id'), nullable=False)

class TournamentResult(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    tournament_id = db.Column(db.String, db.ForeignKey('tournament.id'), nullable=False)
    golfer_id = db.Column(db.String, db.ForeignKey('golfer.id'), nullable=False)
    earnings = db.Column(db.Integer)

# --- API Endpoints ---
@app.route('/')
def hello_world():
    return 'Hello, World from Flask Backend!'

# --- User Endpoints ---
@app.route('/api/users', methods=['POST'])
def add_user():
    data = request.get_json()
    if not data or not 'id' in data or not 'displayName' in data or not 'email' in data:
        return jsonify({"error": "Missing user ID, display name, or email"}), 400
    
    user = User.query.get(data['id'])
    if user:
        return jsonify({"message": "User already exists"}), 200 # User already registered
    
    new_user = User(id=data['id'], displayName=data['displayName'], email=data['email'])
    db.session.add(new_user)
    db.session.commit()
    return jsonify({"message": "User added successfully", "user": {"id": new_user.id, "displayName": new_user.displayName, "email": new_user.email}}), 201

# --- Golfer Endpoints ---
@app.route('/golfers', methods=['POST'])
def add_golfer():
    data = request.get_json()
    if not data or not 'id' in data or not 'name' in data:
        return jsonify({"error": "Missing golfer ID or name"}), 400
    
    golfer = Golfer.query.get(data['id'])
    if golfer:
        return jsonify({"error": "Golfer with this ID already exists"}), 409

    new_golfer = Golfer(id=data['id'], name=data['name'])
    db.session.add(new_golfer)
    db.session.commit()
    return jsonify({"message": "Golfer added successfully", "golfer": {"id": new_golfer.id, "name": new_golfer.name}}), 201

@app.route('/golfers', methods=['GET'])
def get_golfers():
    golfers = Golfer.query.all()
    return jsonify([{"id": g.id, "name": g.name} for g in golfers])

# --- Tournament Endpoints ---
@app.route('/tournaments', methods=['POST'])
def add_tournament():
    data = request.get_json()
    required_fields = ['id', 'name', 'year', 'submission_start', 'submission_end']
    if not data or not all(field in data for field in required_fields):
        return jsonify({"error": "Missing required tournament fields"}), 400

    tournament = Tournament.query.get(data['id'])
    if tournament:
        return jsonify({"error": "Tournament with this ID already exists"}), 409

    try:
        start_date = datetime.fromisoformat(data['submission_start'].replace('Z', '+00:00'))
        end_date = datetime.fromisoformat(data['submission_end'].replace('Z', '+00:00'))
    except ValueError:
        return jsonify({"error": "Invalid date format. Use ISO 8601 format."}), 400

    new_tournament = Tournament(
        id=data['id'], 
        name=data['name'], 
        year=data['year'],
        submission_start=start_date,
        submission_end=end_date
    )
    db.session.add(new_tournament)
    db.session.commit()
    return jsonify({"message": "Tournament added successfully"}), 201

@app.route('/tournaments', methods=['GET'])
def get_tournaments():
    tournaments = Tournament.query.all()
    return jsonify([{"id": t.id, "name": t.name, "year": t.year} for t in tournaments])

@app.route('/api/available-tournaments', methods=['GET'])
def get_available_tournaments():
    now = datetime.now(timezone.utc)
    available_tournaments = Tournament.query.filter(
        Tournament.submission_start <= now,
        Tournament.submission_end >= now
    ).all()
    
    return jsonify([{
        "id": t.id, 
        "name": t.name, 
        "year": t.year,
        "submission_start": t.submission_start.isoformat(),
        "submission_end": t.submission_end.isoformat()
    } for t in available_tournaments])

@app.route('/load-tournaments', methods=['POST'])
def load_tournaments_from_file():
    try:
        with open(os.path.join(basedir, 'schedule_2026.txt'), 'r') as f:
            schedule_data = json.load(f)
    except FileNotFoundError:
        return jsonify({"error": "schedule_2026.txt not found"}), 404
    except json.JSONDecodeError:
        return jsonify({"error": "Failed to decode JSON from schedule_2026.txt"}), 500

    tournaments_to_load = [
        "THE PLAYERS Championship",
        "Masters Tournament",
        "PGA Championship",
        "U.S. Open",
        "The Open Championship"
    ]
    
    loaded_count = 0
    for tourn in schedule_data.get('schedule', []):
        # Normalize names for comparison
        tourn_name = tourn.get('name', '')
        
        # Special handling for Masters, which doesn't have "The" in its name in some APIs
        if "Masters Tournament" in tournaments_to_load and "Masters Tournament" in tourn_name:
            tourn_name_to_check = "Masters Tournament"
        else:
            tourn_name_to_check = tourn_name

        if any(t.lower() in tourn_name_to_check.lower() for t in tournaments_to_load):
            tourn_id = tourn.get('tournId')
            if not tourn_id:
                continue

            # Check if tournament already exists
            if Tournament.query.get(tourn_id):
                continue

            try:
                # Calculate submission window
                start_timestamp_ms = tourn['date']['start']['$date']['$numberLong']
                tourn_start_date = datetime.fromtimestamp(int(start_timestamp_ms) / 1000, tz=timezone.utc)
                
                # Sunday before the tournament starts (weekday() is 0 for Monday, 6 for Sunday)
                submission_start = tourn_start_date - timedelta(days=(tourn_start_date.weekday() + 1) % 7)
                
                # Wednesday 11:59:59 PM before the tournament
                # Find the Thursday of the tournament week
                thursday_of_week = tourn_start_date + timedelta(days=(3 - tourn_start_date.weekday() + 7) % 7)
                # Wednesday is the day before Thursday
                wednesday_of_week = thursday_of_week - timedelta(days=1)
                submission_end = wednesday_of_week.replace(hour=23, minute=59, second=59)

                new_tournament = Tournament(
                    id=tourn_id,
                    name=tourn_name,
                    year=int(schedule_data.get('year')),
                    submission_start=submission_start,
                    submission_end=submission_end
                )
                db.session.add(new_tournament);
                loaded_count += 1
            except (KeyError, TypeError) as e:
                print(f"Skipping tournament due to missing data: {tourn_name}, Error: {e}")
                continue

    db.session.commit()
    return jsonify({"message": f"Successfully loaded {loaded_count} new tournaments."}), 200

@app.route('/api/tournaments/<string:tournament_id>/update-earnings', methods=['POST'])
def update_earnings_for_tournament(tournament_id):
    rapidapi_key = os.getenv('RAPIDAPI_KEY')
    rapidapi_host = os.getenv('RAPIDAPI_HOST')

    if not rapidapi_key or not rapidapi_host:
        return jsonify({"error": "RapidAPI key or host not configured in environment variables"}), 500

    tournament = Tournament.query.get(tournament_id)
    if not tournament:
        return jsonify({"error": "Tournament not found in local database"}), 404
    
    year = str(tournament.year)
    
    url = f"https://{rapidapi_host}/earnings"
    headers = {
        "x-rapidapi-key": rapidapi_key,
        "x-rapidapi-host": rapidapi_host
    }
    params = {
        "tournId": tournament_id,
        "year": year
    }

    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status()
        data = response.json()

        if 'leaderboard' not in data:
            return jsonify({"error": "No leaderboard/earnings found for this tournament from external API"}), 404

        updated_count = 0
        for player_result in data['leaderboard']:
            golfer_id = player_result.get('playerId')
            # The earnings are nested, so we need to be careful
            earnings_data = player_result.get('earnings', {})
            earnings = earnings_data.get('$numberInt')

            if not golfer_id or earnings is None:
                continue

            # Use 'upsert' logic: update if exists, insert if not
            existing_result = TournamentResult.query.filter_by(
                tournament_id=tournament_id,
                golfer_id=golfer_id
            ).first()

            if existing_result:
                existing_result.earnings = int(earnings)
            else:
                new_result = TournamentResult(
                    tournament_id=tournament_id,
                    golfer_id=golfer_id,
                    earnings=int(earnings)
                )
                db.session.add(new_result)
            
            updated_count += 1
        
        db.session.commit()
        return jsonify({"message": f"Successfully updated earnings for {updated_count} golfers."}), 200

    except requests.exceptions.RequestException as e:
        print(f"Error fetching earnings from external API: {e}")
        return jsonify({"error": f"Failed to fetch earnings from external API: {str(e)}"}), 500
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500

@app.route('/load-earnings', methods=['POST'])
def load_earnings_from_file():
    try:
        with open(os.path.join(basedir, 'genesis_invitational_2025_earnings.txt'), 'r') as f:
            earnings_data = json.load(f)
    except FileNotFoundError:
        return jsonify({"error": "genesis_invitational_2025_earnings.txt not found"}), 404
    except json.JSONDecodeError:
        return jsonify({"error": "Failed to decode JSON from genesis_invitational_2025_earnings.txt"}), 500

    tourn_id = earnings_data.get('tournId')
    if not tourn_id:
        return jsonify({"error": "Tournament ID not found in earnings file"}), 400

    updated_count = 0
    for player_result in earnings_data.get('leaderboard', []):
        golfer_id = player_result.get('playerId')
        earnings = player_result.get('earnings', {}).get('$numberInt')

        if not golfer_id or earnings is None:
            continue

        # Use 'upsert' logic: update if exists, insert if not
        existing_result = TournamentResult.query.filter_by(
            tournament_id=tourn_id,
            golfer_id=golfer_id
        ).first()

        if existing_result:
            existing_result.earnings = int(earnings)
        else:
            new_result = TournamentResult(
                tournament_id=tourn_id,
                golfer_id=golfer_id,
                earnings=int(earnings)
            )
            db.session.add(new_result)
        
        updated_count += 1
    
    db.session.commit()
    return jsonify({"message": f"Successfully loaded/updated earnings for {updated_count} golfers for tournament {tourn_id}."}), 200

@app.route('/api/tournaments/<string:tournament_id>/golfers', methods=['GET'])
def get_golfers_for_tournament(tournament_id):
    print(f"--- Attempting to get golfers for tournament ID: {tournament_id} ---")
    rapidapi_key = os.getenv('RAPIDAPI_KEY')
    rapidapi_host = os.getenv('RAPIDAPI_HOST')

    if not rapidapi_key or not rapidapi_host:
        return jsonify({"error": "RapidAPI key or host not configured in environment variables"}), 500

    # Retrieve year from the Tournament model
    tournament = Tournament.query.get(tournament_id)
    if not tournament:
        return jsonify({"error": "Tournament not found in local database"}), 404
    
    year = str(tournament.year) # Convert year to string for API parameter
    org_id = "1" # Assuming PGA Tour for now, can be made dynamic later

    url = f"https://{rapidapi_host}/tournament"
    headers = {
        "x-rapidapi-key": rapidapi_key,
        "x-rapidapi-host": rapidapi_host
    }
    params = {
        "orgId": org_id,
        "tournId": tournament_id,
        "year": year
    }

    try:
        response = requests.get(url, headers=headers, params=params)
        response.raise_for_status() # Raise an exception for HTTP errors (4xx or 5xx)
        data = response.json()

        if 'players' not in data:
            return jsonify({"error": "No players found for this tournament from external API"}), 404

        golfers_data = []
        for player in data['players']:
            golfer_id = player['playerId']
            first_name = player.get('firstName', '')
            last_name = player.get('lastName', '')
            full_name = f"{first_name} {last_name}".strip()

            # Add golfer to our database if they don't exist
            existing_golfer = Golfer.query.get(golfer_id)
            if not existing_golfer:
                new_golfer = Golfer(id=golfer_id, name=full_name)
                db.session.add(new_golfer)
            
            golfers_data.append({"id": golfer_id, "name": full_name})
        
        db.session.commit() # Commit any new golfers added to our DB

        return jsonify(golfers_data)

    except requests.exceptions.RequestException as e:
        print(f"Error fetching golfers from external API: {e}")
        return jsonify({"error": f"Failed to fetch golfers from external API: {str(e)}"}), 500
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500

# --- Pick Submission Endpoint ---
@app.route('/api/picks', methods=['POST'])
def submit_picks():
    print("--- Executing updated submit_picks function ---") # <--- New print statement
    data = request.get_json()
    required_fields = ['user_id', 'tournament_id', 'golfer_ids']
    if not data or not all(field in data for field in required_fields):
        return jsonify({"error": "Missing user_id, tournament_id, or golfer_ids"}), 400

    user_id = data['user_id']
    tournament_id = data['tournament_id']
    golfer_ids = data['golfer_ids']

    if not isinstance(golfer_ids, list) or len(golfer_ids) != 3:
        return jsonify({"error": "Exactly 3 golfer_ids must be provided as a list"}), 400

    # 1. Check if the submission window is still open
    tournament = Tournament.query.get(tournament_id)
    if not tournament:
        return jsonify({"error": "Tournament not found"}), 404
    
    now = datetime.utcnow() # <--- This is the correct line
    if now > tournament.submission_end:
        return jsonify({"error": "The submission deadline has passed for this tournament."}), 403 # 403 Forbidden

    # 2. Delete any existing picks for this specific tournament
    existing_picks = Pick.query.filter_by(user_id=user_id, tournament_id=tournament_id).all()
    if existing_picks:
        for pick in existing_picks:
            db.session.delete(pick)

    # 3. Validate new picks against picks from OTHER tournaments
    for golfer_id in golfer_ids:
        # Note the addition of `Pick.tournament_id != tournament_id` to the query
        previous_pick = Pick.query.filter(
            Pick.user_id == user_id,
            Pick.golfer_id == golfer_id,
            Pick.tournament_id != tournament_id
        ).first()
        if previous_pick:
            # Fetch the golfer's name for a more user-friendly error message
            golfer = Golfer.query.get(golfer_id)
            golfer_name = golfer.name if golfer else golfer_id
            return jsonify({"error": f"You have already picked {golfer_name} in a previous tournament."}), 409

    # 4. Save the new picks
    try:
        for golfer_id in golfer_ids:
            new_pick = Pick(user_id=user_id, tournament_id=tournament_id, golfer_id=golfer_id)
            db.session.add(new_pick)
        db.session.commit() # This atomically deletes the old picks and adds the new ones
        return jsonify({"message": "Picks submitted successfully"}), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({"error": f"Failed to submit picks: {str(e)}"}), 500

# --- Scoreboard Endpoint ---
@app.route('/api/scoreboard', methods=['GET'])
def get_scoreboard():
    try:
        # This query joins User, Pick, and TournamentResult tables,
        # groups by user, and sums the earnings for each user's picks.
        scoreboard_query = db.session.query(
            User.id,
            User.displayName,
            User.email,
            db.func.sum(TournamentResult.earnings).label('total_score')
        ).join(Pick, User.id == Pick.user_id)\
         .join(TournamentResult, (Pick.golfer_id == TournamentResult.golfer_id) & (Pick.tournament_id == TournamentResult.tournament_id))\
         .group_by(User.id)\
         .order_by(db.func.sum(TournamentResult.earnings).desc())

        results = scoreboard_query.all()

        scoreboard_data = [{
            "id": r.id,
            "displayName": r.displayName,
            "email": r.email,
            "score": r.total_score if r.total_score is not None else 0
        } for r in results]
        
        # To include users who have made no picks yet (with a score of 0)
        users_with_picks = {r['id'] for r in scoreboard_data}
        all_users = User.query.all()
        for user in all_users:
            if user.id not in users_with_picks:
                scoreboard_data.append({
                    "id": user.id,
                    "displayName": user.displayName,
                    "email": user.email,
                    "score": 0
                })

        # Re-sort to ensure correct order after adding users with 0 score
        scoreboard_data.sort(key=lambda x: x['score'], reverse=True)

        return jsonify(scoreboard_data)
    except Exception as e:
        print(f"Error calculating scoreboard: {e}")
        return jsonify({"error": "Failed to calculate scoreboard"}), 500

@app.route('/api/detailed-scoreboard', methods=['GET'])
def get_detailed_scoreboard():
    try:
        # Get all tournaments for which at least one pick has been made
        # Order by submission_end date so current tournaments appear first
        tournaments_with_picks = db.session.query(Tournament)\
                                    .join(Pick, Tournament.id == Pick.tournament_id)\
                                    .distinct()\
                                    .order_by(Tournament.submission_end.desc())\
                                    .all()
        
        tournaments_data = []
        overall_scores = {} # To calculate overall leaderboard

        for t in tournaments_with_picks:
            user_scores_for_tournament = {}
            
            # Get all picks for this tournament, and try to join with results and golfer names
            picks_data = db.session.query(
                User.id,
                User.displayName,
                Pick.golfer_id,
                Golfer.name.label('golfer_name'),
                TournamentResult.earnings # This will be NULL if no result exists
            ).join(User, User.id == Pick.user_id)\
             .join(Golfer, Pick.golfer_id == Golfer.id)\
             .outerjoin(TournamentResult, (Pick.golfer_id == TournamentResult.golfer_id) & (Pick.tournament_id == TournamentResult.tournament_id))\
             .filter(Pick.tournament_id == t.id)\
             .all()

            for pick_entry in picks_data:
                user_id = pick_entry.id
                display_name = pick_entry.displayName
                golfer_name = pick_entry.golfer_name
                earnings = pick_entry.earnings if pick_entry.earnings is not None else 0 # Default to 0 if no earnings yet

                # Aggregate results by user for this specific tournament
                if user_id not in user_scores_for_tournament:
                    user_scores_for_tournament[user_id] = {
                        "user_id": user_id,
                        "displayName": display_name,
                        "total_earnings": 0,
                        "picks": []
                    }
                
                user_scores_for_tournament[user_id]['picks'].append({
                    "golfer_name": golfer_name,
                    "earnings": earnings
                })
                user_scores_for_tournament[user_id]['total_earnings'] += earnings

                # Update overall score (only if earnings are available for this pick)
                if earnings > 0: # Only add to overall score if there are actual earnings
                    if user_id not in overall_scores:
                        overall_scores[user_id] = {
                            "user_id": user_id,
                            "displayName": display_name,
                            "total_score": 0
                        }
                    overall_scores[user_id]['total_score'] += earnings

            tournaments_data.append({
                "id": t.id,
                "name": t.name,
                "user_scores": sorted(user_scores_for_tournament.values(), key=lambda x: x['total_earnings'], reverse=True)
            })

        # Format the overall leaderboard
        overall_leaderboard = sorted(overall_scores.values(), key=lambda x: x['total_score'], reverse=True)

        # Add users who have made picks but have no overall score yet (e.g., all their picks are for pending tournaments)
        all_users_with_picks = db.session.query(User).join(Pick).distinct().all()
        users_in_overall_leaderboard = {u['user_id'] for u in overall_leaderboard}
        for user in all_users_with_picks:
            if user.id not in users_in_overall_leaderboard:
                overall_leaderboard.append({
                    "user_id": user.id,
                    "displayName": user.displayName,
                    "total_score": 0
                })
        
        # Ensure all registered users are in the overall leaderboard, even if they have no picks
        all_registered_users = User.query.all()
        users_in_overall_leaderboard_final = {u['user_id'] for u in overall_leaderboard}
        for user in all_registered_users:
            if user.id not in users_in_overall_leaderboard_final:
                overall_leaderboard.append({
                    "user_id": user.id,
                    "displayName": user.displayName,
                    "total_score": 0
                })
        
        # Re-sort the overall leaderboard after adding users with 0 score
        overall_leaderboard.sort(key=lambda x: x['total_score'], reverse=True)


        return jsonify({
            "tournaments": tournaments_data,
            "overall_leaderboard": overall_leaderboard
        })

    except Exception as e:
        print(f"Error calculating detailed scoreboard: {e}")
        return jsonify({"error": "Failed to calculate detailed scoreboard"}), 500

# --- Main Execution ---
if __name__ == '__main__':
    with app.app_context():
        db.create_all() # Create database tables if they don't exist
    app.run(debug=True, port=5000)

@app.route('/show-routes')
def show_routes():
    import urllib
    output = []
    for rule in app.url_map.iter_rules():
        methods = ','.join(rule.methods)
        line = urllib.parse.unquote(f"{rule.endpoint:50s} {methods:20s} {str(rule)}")
        output.append(line)
    
    return "<pre>" + "\n".join(sorted(output)) + "</pre>"
