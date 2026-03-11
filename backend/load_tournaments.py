import json
import requests
from datetime import datetime, timedelta, timezone

def load_tournaments():
    """
    Reads the schedule from schedule_2026.txt, calculates submission windows,
    and posts each tournament to the backend API.
    """
    api_url = "http://127.0.0.1:5000/api/tournaments"
    headers = {"Content-Type": "application/json"}

    try:
        with open("backend/schedule_2026.txt", "r") as f:
            schedule_data = json.load(f)
    except FileNotFoundError:
        print("Error: schedule_2026.txt not found in the backend directory.")
        return
    except json.JSONDecodeError:
        print("Error: Could not decode JSON from schedule_2026.txt.")
        return

    year = schedule_data.get("year")
    if not year:
        print("Error: 'year' not found in schedule data.")
        return

    for tournament in schedule_data.get("schedule", []):
        tourn_id = tournament.get("tournId")
        name = tournament.get("name")
        try:
            start_timestamp_ms = int(tournament["date"]["start"]["$date"]["$numberLong"])
            start_date = datetime.fromtimestamp(start_timestamp_ms / 1000, tz=timezone.utc)
        except (KeyError, TypeError, ValueError) as e:
            print(f"Skipping tournament '{name}' due to invalid start date data: {e}")
            continue

        if not tourn_id or not name:
            print(f"Skipping tournament with missing 'tournId' or 'name'.")
            continue

        # Calculate submission_start (Sunday before the tournament starts)
        days_to_subtract_for_sunday = (start_date.weekday() + 1) % 7
        if days_to_subtract_for_sunday == 0: # If start date is a Sunday, go back a full week
            days_to_subtract_for_sunday = 7
        submission_start = (start_date - timedelta(days=days_to_subtract_for_sunday)).replace(hour=0, minute=0, second=0, microsecond=0)


        # Calculate submission_end (Wednesday 11:59:59 PM the day before the start)
        submission_end_day = start_date - timedelta(days=1)
        submission_end = submission_end_day.replace(hour=23, minute=59, second=59, microsecond=0)


        payload = {
            "id": tourn_id,
            "name": name,
            "year": int(year),
            "submission_start": submission_start.isoformat().replace('+00:00', 'Z'),
            "submission_end": submission_end.isoformat().replace('+00:00', 'Z'),
        }

        try:
            response = requests.post(api_url, headers=headers, data=json.dumps(payload))
            response.raise_for_status()
            print(f"Successfully added '{name}'. Response: {response.json()}")
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 409:
                print(f"Tournament '{name}' already exists. Skipping.")
            else:
                print(f"Error adding '{name}': {e.response.status_code} - {e.response.text}")
        except requests.exceptions.RequestException as e:
            print(f"Error connecting to the backend to add '{name}': {e}")


if __name__ == "__main__":
    load_tournaments()
