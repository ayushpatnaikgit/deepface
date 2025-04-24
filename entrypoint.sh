#!/bin/sh
# filepath: /Users/ayushpatnaik/REPOSITORIES/deepface/entrypoint.sh

echo "Starting Gunicorn on port $PORT..."

# Start Gunicorn server using the PORT environment variable
gunicorn --workers=1 --timeout=7200 --bind=0.0.0.0:${PORT} --log-level=debug --access-logformat='%(h)s - - [%(t)s] "%(r)s" %(s)s %(b)s %(L)s' --access-logfile=- "app:create_app()"
