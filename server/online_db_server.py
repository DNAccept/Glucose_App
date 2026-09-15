import datetime
import json
import os
import secrets
import sqlite3
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs, urlparse

import time

DB_FILE = os.environ.get("DATABASE_PATH", os.path.join(os.path.dirname(__file__), "online_database.sqlite"))
ALLOWED_ORIGINS = os.environ.get("ALLOWED_ORIGINS", "*")

def get_db_connection():
    db_dir = os.path.dirname(os.path.abspath(DB_FILE))
    if db_dir and not os.path.exists(db_dir):
        os.makedirs(db_dir, exist_ok=True)
    conn = sqlite3.connect(DB_FILE, timeout=30.0)
    conn.execute("PRAGMA busy_timeout=10000;")
    try:
        conn.execute("PRAGMA journal_mode=WAL;")
    except sqlite3.OperationalError:
        pass
    try:
        conn.execute("PRAGMA foreign_keys=ON;")
    except sqlite3.OperationalError:
        pass
    return conn

_db_initialized = False

def init_db():
    global _db_initialized
    if _db_initialized:
        return

    for attempt in range(5):
        try:
            conn = get_db_connection()
            cursor = conn.cursor()

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    username TEXT UNIQUE NOT NULL,
                    password_hash TEXT NOT NULL,
                    password_salt TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_sessions (
                    token TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    created_at TEXT NOT NULL,
                    expires_at TEXT NOT NULL,
                    FOREIGN KEY(user_id) REFERENCES users(id)
                );
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS readings (
                    uuid TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    timestamp TEXT NOT NULL,
                    mg_dl REAL NOT NULL,
                    glucose_class INTEGER NOT NULL,
                    confidence INTEGER NOT NULL,
                    last_modified TEXT NOT NULL,
                    is_deleted INTEGER DEFAULT 0
                );
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS reference_readings (
                    uuid TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    reference_value_mg_dl INTEGER NOT NULL,
                    reference_class INTEGER NOT NULL,
                    device_mg_dl REAL,
                    device_class INTEGER,
                    device_confidence INTEGER,
                    timestamp TEXT NOT NULL,
                    last_modified TEXT NOT NULL,
                    is_deleted INTEGER DEFAULT 0
                );
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_settings (
                    user_id INTEGER PRIMARY KEY,
                    alerts_enabled INTEGER NOT NULL,
                    cloud_sync_enabled INTEGER NOT NULL,
                    last_modified TEXT NOT NULL
                );
            """)

            conn.commit()
            conn.close()
            _db_initialized = True
            break
        except sqlite3.OperationalError:
            time.sleep(0.5)

def create_session(cursor, user_id):
    token = secrets.token_hex(32)
    now = datetime.datetime.now(datetime.timezone.utc)
    expires = now + datetime.timedelta(days=30)
    now_str = now.isoformat().replace("+00:00", "Z")
    expires_str = expires.isoformat().replace("+00:00", "Z")

    cursor.execute("""
        INSERT INTO user_sessions (token, user_id, created_at, expires_at)
        VALUES (?, ?, ?, ?)
    """, (token, user_id, now_str, expires_str))
    return token

class OnlineDatabaseRequestHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        client_ip = self.client_address[0]
        timestamp = self.log_date_time_string()
        msg = format % args if args else ""
        print(f"[{timestamp}] 📲 [HTTP LOG] Client {client_ip} -> {msg}", flush=True)

    def _set_cors_headers(self):
        self.send_header("Access-Control-Allow-Origin", ALLOWED_ORIGINS)
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")

    def do_OPTIONS(self):
        self.send_response(200)
        self._set_cors_headers()
        self.end_headers()

    def _send_json(self, data, status=200):
        self.send_response(status)
        self._set_cors_headers()
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def _send_error(self, message, status=400):
        self._send_json({"error": message}, status=status)

    def _read_json(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            return {}
        body = self.rfile.read(content_length)
        return json.loads(body.decode("utf-8"))

    def _extract_token(self):
        auth_header = self.headers.get("Authorization", "")
        if auth_header.startswith("Bearer "):
            return auth_header[7:].strip()
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)
        return query.get("token", [None])[0]

    def _authenticate_request(self, cursor, expected_user_id=None):
        token = self._extract_token()
        if not token:
            self._send_error("Missing authentication token in Authorization header.", 401)
            return None

        cursor.execute("SELECT * FROM user_sessions WHERE token = ?", (token,))
        session = cursor.fetchone()
        if not session:
            self._send_error("Invalid or unrecognized authentication token.", 401)
            return None

        token_user_id = session["user_id"]
        if expected_user_id is not None and int(expected_user_id) != int(token_user_id):
            self._send_error("Forbidden: You do not have permission to access records for this user.", 403)
            return None

        return token_user_id

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path
        query = parse_qs(parsed.query)

        conn = get_db_connection()
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        try:
            if path == "/api/health":
                self._send_json({
                    "status": "ok",
                    "server": "Glucose Monitor Online Database (Python + SQLite)",
                    "db": os.path.abspath(DB_FILE)
                })

            elif path == "/api/user":
                user_id = query.get("id", [None])[0]
                if not user_id:
                    return self._send_error("Missing user id parameter")

                if not self._authenticate_request(cursor, expected_user_id=user_id):
                    return

                cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
                row = cursor.fetchone()
                if not row:
                    return self._send_error("User not found", 404)
                self._send_json({
                    "id": row["id"],
                    "username": row["username"],
                    "passwordHash": row["password_hash"],
                    "passwordSalt": row["password_salt"],
                    "createdAt": row["created_at"]
                })

            elif path == "/api/readings/pull":
                user_id = query.get("user_id", [None])[0]
                since = query.get("since", [None])[0]
                if not user_id:
                    return self._send_error("Missing user_id parameter")

                if not self._authenticate_request(cursor, expected_user_id=user_id):
                    return

                if since:
                    cursor.execute(
                        "SELECT * FROM readings WHERE user_id = ? AND last_modified >= ?",
                        (user_id, since)
                    )
                else:
                    cursor.execute("SELECT * FROM readings WHERE user_id = ?", (user_id,))

                rows = cursor.fetchall()
                results = [{
                    "uuid": r["uuid"],
                    "userId": r["user_id"],
                    "timestamp": r["timestamp"],
                    "mgDl": r["mg_dl"],
                    "glucoseClass": r["glucose_class"],
                    "confidence": r["confidence"],
                    "lastModified": r["last_modified"],
                    "isDeleted": bool(r["is_deleted"])
                } for r in rows]
                self._send_json(results)

            elif path == "/api/references/pull":
                user_id = query.get("user_id", [None])[0]
                since = query.get("since", [None])[0]
                if not user_id:
                    return self._send_error("Missing user_id parameter")

                if not self._authenticate_request(cursor, expected_user_id=user_id):
                    return

                if since:
                    cursor.execute(
                        "SELECT * FROM reference_readings WHERE user_id = ? AND last_modified >= ?",
                        (user_id, since)
                    )
                else:
                    cursor.execute("SELECT * FROM reference_readings WHERE user_id = ?", (user_id,))

                rows = cursor.fetchall()
                results = [{
                    "uuid": r["uuid"],
                    "userId": r["user_id"],
                    "referenceValueMgDl": r["reference_value_mg_dl"],
                    "referenceClass": r["reference_class"],
                    "deviceMgDl": r["device_mg_dl"],
                    "deviceClass": r["device_class"],
                    "deviceConfidence": r["device_confidence"],
                    "timestamp": r["timestamp"],
                    "lastModified": r["last_modified"],
                    "isDeleted": bool(r["is_deleted"])
                } for r in rows]
                self._send_json(results)

            elif path == "/api/settings/pull":
                user_id = query.get("user_id", [None])[0]
                if not user_id:
                    return self._send_error("Missing user_id parameter")

                if not self._authenticate_request(cursor, expected_user_id=user_id):
                    return

                cursor.execute("SELECT * FROM user_settings WHERE user_id = ?", (user_id,))
                row = cursor.fetchone()
                if not row:
                    self._send_json(None)
                else:
                    self._send_json({
                        "userId": row["user_id"],
                        "alertsEnabled": bool(row["alerts_enabled"]),
                        "cloudSyncEnabled": bool(row["cloud_sync_enabled"]),
                        "lastModified": row["last_modified"]
                    })
            else:
                self._send_error("Endpoint not found", 404)
        finally:
            conn.close()

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path
        body = self._read_json()

        conn = get_db_connection()
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()

        try:
            if path == "/api/register":
                username = body.get("username", "").strip()
                password_hash = body.get("passwordHash", "")
                password_salt = body.get("passwordSalt", "")
                created_at = body.get("createdAt") or datetime.datetime.now(datetime.timezone.utc).isoformat()

                if not username or not password_hash:
                    return self._send_error("Missing username or passwordHash")

                cursor.execute("SELECT id FROM users WHERE LOWER(username) = LOWER(?)", (username,))
                if cursor.fetchone():
                    return self._send_error("Username already registered in cloud database.")

                cursor.execute(
                    "INSERT INTO users (username, password_hash, password_salt, created_at) VALUES (?, ?, ?, ?)",
                    (username, password_hash, password_salt, created_at)
                )
                user_id = cursor.lastrowid
                token = create_session(cursor, user_id)
                conn.commit()

                self._send_json({
                    "id": user_id,
                    "username": username,
                    "passwordHash": password_hash,
                    "passwordSalt": password_salt,
                    "createdAt": created_at,
                    "token": token
                })

            elif path == "/api/login":
                username = body.get("username", "").strip()
                password_hash = body.get("passwordHash", "")

                cursor.execute("SELECT * FROM users WHERE LOWER(username) = LOWER(?)", (username,))
                user = cursor.fetchone()
                if not user:
                    return self._send_error("Invalid username or password", 401)

                if user["password_hash"] != password_hash:
                    return self._send_error("Invalid username or password", 401)

                user_id = user["id"]
                token = create_session(cursor, user_id)
                conn.commit()

                self._send_json({
                    "id": user_id,
                    "username": user["username"],
                    "passwordHash": user["password_hash"],
                    "passwordSalt": user["password_salt"],
                    "createdAt": user["created_at"],
                    "token": token
                })

            elif path == "/api/readings/push":
                user_id = body.get("userId")
                if not user_id:
                    return self._send_error("Missing userId in request body")

                if not self._authenticate_request(cursor, expected_user_id=user_id):
                    return

                readings = body.get("readings", [])
                synced = []

                for r in readings:
                    uuid = r.get("uuid")
                    cursor.execute("SELECT * FROM readings WHERE uuid = ?", (uuid,))
                    existing = cursor.fetchone()

                    if not existing or r.get("lastModified") > existing["last_modified"]:
                        cursor.execute("""
                            INSERT INTO readings (uuid, user_id, timestamp, mg_dl, glucose_class, confidence, last_modified, is_deleted)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                            ON CONFLICT(uuid) DO UPDATE SET
                                mg_dl=excluded.mg_dl,
                                glucose_class=excluded.glucose_class,
                                confidence=excluded.confidence,
                                last_modified=excluded.last_modified,
                                is_deleted=excluded.is_deleted;
                        """, (
                            uuid,
                            user_id,
                            r.get("timestamp"),
                            r.get("mgDl"),
                            r.get("glucoseClass"),
                            r.get("confidence"),
                            r.get("lastModified"),
                            1 if r.get("isDeleted") else 0
                        ))

                    cursor.execute("SELECT * FROM readings WHERE uuid = ?", (uuid,))
                    updated = cursor.fetchone()
                    synced.append({
                        "uuid": updated["uuid"],
                        "userId": updated["user_id"],
                        "timestamp": updated["timestamp"],
                        "mgDl": updated["mg_dl"],
                        "glucoseClass": updated["glucose_class"],
                        "confidence": updated["confidence"],
                        "lastModified": updated["last_modified"],
                        "isDeleted": bool(updated["is_deleted"])
                    })

                conn.commit()
                self._send_json(synced)

            elif path == "/api/references/push":
                user_id = body.get("userId")
                if not user_id:
                    return self._send_error("Missing userId in request body")

                if not self._authenticate_request(cursor, expected_user_id=user_id):
                    return

                references = body.get("references", [])
                synced = []

                for r in references:
                    uuid = r.get("uuid")
                    cursor.execute("SELECT * FROM reference_readings WHERE uuid = ?", (uuid,))
                    existing = cursor.fetchone()

                    if not existing or r.get("lastModified") > existing["last_modified"]:
                        cursor.execute("""
                            INSERT INTO reference_readings (uuid, user_id, reference_value_mg_dl, reference_class, device_mg_dl, device_class, device_confidence, timestamp, last_modified, is_deleted)
                            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                            ON CONFLICT(uuid) DO UPDATE SET
                                reference_value_mg_dl=excluded.reference_value_mg_dl,
                                reference_class=excluded.reference_class,
                                device_mg_dl=excluded.device_mg_dl,
                                device_class=excluded.device_class,
                                device_confidence=excluded.device_confidence,
                                last_modified=excluded.last_modified,
                                is_deleted=excluded.is_deleted;
                        """, (
                            uuid,
                            user_id,
                            r.get("referenceValueMgDl"),
                            r.get("referenceClass"),
                            r.get("deviceMgDl"),
                            r.get("deviceClass"),
                            r.get("deviceConfidence"),
                            r.get("timestamp"),
                            r.get("lastModified"),
                            1 if r.get("isDeleted") else 0
                        ))

                    cursor.execute("SELECT * FROM reference_readings WHERE uuid = ?", (uuid,))
                    updated = cursor.fetchone()
                    synced.append({
                        "uuid": updated["uuid"],
                        "userId": updated["user_id"],
                        "referenceValueMgDl": updated["reference_value_mg_dl"],
                        "referenceClass": updated["reference_class"],
                        "deviceMgDl": updated["device_mg_dl"],
                        "deviceClass": updated["device_class"],
                        "deviceConfidence": updated["device_confidence"],
                        "timestamp": updated["timestamp"],
                        "lastModified": updated["last_modified"],
                        "isDeleted": bool(updated["is_deleted"])
                    })

                conn.commit()
                self._send_json(synced)

            elif path == "/api/settings/push":
                user_id = body.get("userId")
                if not user_id:
                    return self._send_error("Missing userId in request body")

                if not self._authenticate_request(cursor, expected_user_id=user_id):
                    return

                settings = body.get("settings", {})
                cursor.execute("""
                    INSERT INTO user_settings (user_id, alerts_enabled, cloud_sync_enabled, last_modified)
                    VALUES (?, ?, ?, ?)
                    ON CONFLICT(user_id) DO UPDATE SET
                        alerts_enabled=excluded.alerts_enabled,
                        cloud_sync_enabled=excluded.cloud_sync_enabled,
                        last_modified=excluded.last_modified;
                """, (
                    user_id,
                    1 if settings.get("alertsEnabled") else 0,
                    1 if settings.get("cloudSyncEnabled") else 0,
                    settings.get("lastModified")
                ))
                conn.commit()

                cursor.execute("SELECT * FROM user_settings WHERE user_id = ?", (user_id,))
                row = cursor.fetchone()
                self._send_json({
                    "userId": row["user_id"],
                    "alertsEnabled": bool(row["alerts_enabled"]),
                    "cloudSyncEnabled": bool(row["cloud_sync_enabled"]),
                    "lastModified": row["last_modified"]
                })
            else:
                self._send_error("Endpoint not found", 404)
        finally:
            conn.close()

def get_local_ips():
    import socket
    ips = []
    try:
        hostname = socket.gethostname()
        for ip in socket.gethostbyname_ex(hostname)[2]:
            if not ip.startswith("127."):
                ips.append(ip)
    except Exception:
        pass
    return ips

def run_server(port=8080):
    init_db()
    server_address = ("0.0.0.0", port)
    httpd = HTTPServer(server_address, OnlineDatabaseRequestHandler)
    print("=" * 70)
    print(f"[+] Glucose Monitor Online Database Server RUNNING on port {port}")
    print(f"[+] SQLite database: {os.path.abspath(DB_FILE)}")
    print("-" * 70)
    print("[+] Connection candidates for your app:")
    print(f"    - USB Cable (Physical Android Phone): http://127.0.0.1:{port}")
    print(f"      (Requires running: 'adb reverse tcp:{port} tcp:{port}' on PC)")
    print(f"    - Android Emulator:                 http://10.0.2.2:{port}")
    local_ips = get_local_ips()
    for ip in local_ips:
        print(f"    - Wi-Fi / Local Network:             http://{ip}:{port}")
    print("=" * 70)
    print("[+] Listening for incoming device connections... (Logs will print below)\n", flush=True)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[-] Server shutting down.")
        httpd.server_close()

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    if len(sys.argv) > 1:
        port = int(sys.argv[1])
    run_server(port)
