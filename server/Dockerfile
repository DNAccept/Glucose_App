FROM python:3.11-slim

WORKDIR /app

# Install gunicorn production WSGI web server
RUN pip install --no-cache-dir gunicorn

# Copy backend server files
COPY online_db_server.py wsgi.py ./

# Environment configuration defaults
ENV PORT=8080
ENV DATABASE_PATH=/data/online_database.sqlite
ENV ALLOWED_ORIGINS=*

# Volume for SQLite database persistence
VOLUME /data

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--timeout", "60", "wsgi:application"]
