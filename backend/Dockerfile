FROM python:3.10-slim-buster

WORKDIR /app/backend

COPY requirements.txt . 

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Run the database initialization script during the build
RUN python init_db.py

EXPOSE 5000

ENV FLASK_APP=app.py

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]