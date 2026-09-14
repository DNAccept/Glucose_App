"""
WSGI Application Adapter for Glucose Monitor Backend Server.
Enables hosting online_db_server.py with production WSGI web servers like Gunicorn, Waitress, or uWSGI.
"""

import io
import json
import os
import sys

# Add server directory to module search path
sys.path.insert(0, os.path.dirname(__file__))

from online_db_server import OnlineDatabaseRequestHandler, init_db, DB_FILE

# Initialize database on module load
init_db()


class WSGIRequestWrapper(OnlineDatabaseRequestHandler):
    """
    Subclasses BaseHTTPRequestHandler to handle WSGI environment requests in-memory.
    """

    def __init__(self, environ, start_response):
        self.environ = environ
        self.start_response_func = start_response

        # Request information from WSGI environment
        self.command = environ.get("REQUEST_METHOD", "GET")
        self.path = environ.get("PATH_INFO", "/")
        if environ.get("QUERY_STRING"):
            self.path += "?" + environ["QUERY_STRING"]

        # Request headers
        self.headers = {}
        for key, value in environ.items():
            if key.startswith("HTTP_"):
                header_name = key[5:].replace("_", "-").title()
                self.headers[header_name] = value
            elif key in ("CONTENT_TYPE", "CONTENT_LENGTH"):
                header_name = key.replace("_", "-").title()
                self.headers[header_name] = value

        # Client address
        self.client_address = (environ.get("REMOTE_ADDR", "127.0.0.1"), 0)

        # Input stream
        input_body = environ.get("wsgi.input", io.BytesIO(b""))
        content_length = int(environ.get("CONTENT_LENGTH") or 0)
        if content_length > 0:
            self.rfile = io.BytesIO(input_body.read(content_length))
        else:
            self.rfile = io.BytesIO(b"")

        # Output buffers
        self.response_status = 200
        self.response_headers = []
        self.wfile = io.BytesIO()

        # Execute handler action based on HTTP method
        if self.command == "OPTIONS":
            self.do_OPTIONS()
        elif self.command == "GET":
            self.do_GET()
        elif self.command == "POST":
            self.do_POST()
        else:
            self._send_error("Method Not Allowed", 405)

    def send_response(self, code, message=None):
        self.response_status = code

    def send_header(self, keyword, value):
        self.response_headers.append((keyword, value))

    def end_headers(self):
        pass

    def log_message(self, format, *args):
        # Quiet in WSGI mode or write to stderr
        pass


def application(environ, start_response):
    """Standard WSGI entrypoint callable for Gunicorn/Waitress."""
    wrapper = WSGIRequestWrapper(environ, start_response)

    # Format status code string (e.g., '200 OK')
    status_str = f"{wrapper.response_status} OK"
    if wrapper.response_status == 400:
        status_str = "400 Bad Request"
    elif wrapper.response_status == 401:
        status_str = "401 Unauthorized"
    elif wrapper.response_status == 403:
        status_str = "403 Forbidden"
    elif wrapper.response_status == 404:
        status_str = "404 Not Found"
    elif wrapper.response_status == 405:
        status_str = "405 Method Not Allowed"
    elif wrapper.response_status >= 500:
        status_str = f"{wrapper.response_status} Internal Server Error"

    start_response(status_str, wrapper.response_headers)
    return [wrapper.wfile.getvalue()]
