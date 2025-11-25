FROM python:3.10-slim-buster

WORKDIR /app/backend

COPY requirements.txt . 

RUN pip install --no-cache-dir -r requirements.txt

COPY . .
COPY docker-entrypoint.sh . # Copy the entrypoint script

EXPOSE 5000

ENV FLASK_APP=app.py

# Use the entrypoint script to run init_db.py and then start Gunicorn
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]