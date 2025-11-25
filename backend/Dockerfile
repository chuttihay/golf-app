FROM python:3.10-slim-buster

WORKDIR /app/backend

COPY requirements.txt . 

RUN pip install --no-cache-dir -r requirements.txt

# Explicitly copy only the necessary application files
COPY app.py .
COPY init_db.py .
COPY docker-entrypoint.sh .
COPY genesis_invitational_2025_earnings.txt .
COPY schedule_2026.txt .

EXPOSE 5000

ENV FLASK_APP=app.py

# Use the entrypoint script to run init_db.py and then start Gunicorn
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]