import os
import sys
import requests
from datetime import datetime, timedelta, timezone

from dotenv import load_dotenv
from sqlalchemy import create_engine, Column, String, Integer, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker, declarative_base
from sqlalchemy.exc import SQLAlchemyError

# --- Setup Project Path ---
# This allows the script to be run from anywhere and still find the DB
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(project_root)

# --- Database Model Definitions ---
# We need to redefine the models here so the script is self-contained
Base = declarative_base()

class Tournament(Base):
    __tablename__ = 'tournament'
    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    year = Column(Integer, nullable=False)
    submission_start = Column(DateTime, nullable=False)
    submission_end = Column(DateTime, nullable=False)

class TournamentResult(Base):
    __tablename__ = 'tournament_result'
    id = Column(Integer, primary_key=True)
    tournament_id = Column(String, ForeignKey('tournament.id'), nullable=False) # Not linking to Golfer table to keep script simple
    golfer_id = Column(String, nullable=False) 
    earnings = Column(Integer)

# --- Main Script Logic ---
def update_recent_tournament_earnings():
    """
    Finds tournaments that ended in the last 7 days, checks if their results
    have been loaded, and if not, fetches and stores them.
    """
    print(f"--- Script started at {datetime.now(timezone.utc).isoformat()} ---")

    # --- Database Connection ---
    db_path = os.path.join(os.path.dirname(__file__), 'golf_app.db')
    engine = create_engine(f'sqlite:///{db_path}')
    Session = sessionmaker(bind=engine)
    session = Session()

    # --- Load Environment Variables ---
    load_dotenv()
    rapidapi_key = os.getenv('RAPIDAPI_KEY')
    rapidapi_host = os.getenv('RAPIDAPI_HOST')

    if not rapidapi_key or not rapidapi_host:
        print("Error: RapidAPI key or host not configured in .env file.")
        return

    try:
        # --- Find Recently Ended Tournaments ---
        # Consider tournaments that ended up to 7 days ago and before now
        one_week_ago = datetime.now(timezone.utc) - timedelta(days=7)
        now = datetime.now(timezone.utc)

        recently_ended_tournaments = session.query(Tournament).filter(
            Tournament.submission_end >= one_week_ago,
            Tournament.submission_end <= now
        ).all()

        if not recently_ended_tournaments:
            print("No recently ended tournaments found to update.")
            return

        print(f"Found {len(recently_ended_tournaments)} recently ended tournament(s).")

        for t in recently_ended_tournaments:
            print(f"\nChecking tournament: {t.name} ({t.id})")

            # --- Check if Results Already Exist ---
            # Check if any results exist for this tournament
            result_exists = session.query(TournamentResult).filter_by(tournament_id=t.id).first()
            if result_exists:
                print(f"Results for tournament {t.id} already exist. Skipping.")
                continue

            print(f"No results found for {t.id}. Fetching from API...")

            # --- Fetch Earnings from API ---
            url = f"https://{rapidapi_host}/earnings"
            headers = {
                "x-rapidapi-key": rapidapi_key,
                "x-rapidapi-host": rapidapi_host
            }
            params = {
                "tournId": t.id,
                "year": str(t.year)
            }

            try:
                response = requests.get(url, headers=headers, params=params, timeout=30)
                response.raise_for_status()
                data = response.json()

                if 'leaderboard' not in data or not data['leaderboard']:
                    print(f"Warning: No leaderboard/earnings found for tournament {t.id} from external API.")
                    continue

                # --- Process and Store Results ---
                updated_count = 0
                for player_result in data['leaderboard']:
                    golfer_id = player_result.get('playerId')
                    earnings = player_result.get('earnings', {}).get('$numberInt')

                    if not golfer_id or earnings is None:
                        continue
                    
                    new_result = TournamentResult(
                        tournament_id=t.id,
                        golfer_id=golfer_id,
                        earnings=int(earnings)
                    )
                    session.add(new_result)
                    updated_count += 1
                
                session.commit()
                print(f"Successfully loaded earnings for {updated_count} golfers for tournament {t.id}.")

            except requests.exceptions.RequestException as e:
                print(f"Error fetching earnings from external API for tournament {t.id}: {e}")
                session.rollback()
                continue # Move to the next tournament

    except SQLAlchemyError as e:
        print(f"Database error: {e}")
        if 'session' in locals() and session.is_active:
            session.rollback()
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        if 'session' in locals() and session.is_active:
            session.rollback()
    finally:
        if 'session' in locals():
            session.close()
        print(f"--- Script finished at {datetime.now(timezone.utc).isoformat()} ---")


if __name__ == '__main__':
    update_recent_tournament_earnings()