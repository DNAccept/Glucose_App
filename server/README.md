# Glucose Monitor - Online Database Localhost Server

A lightweight Python + SQLite REST database server to host the cloud database locally on your machine.

## How to Run

1. Open PowerShell or Terminal in the repository root (`c:\Glucose_App`).
2. Run:
   ```bash
   python server/online_db_server.py
   ```
3. The server will start listening on:
   - **Localhost**: `http://localhost:8080` or `http://127.0.0.1:8080`
   - **Android Emulator**: `http://10.0.2.2:8080`
   - **Local Wi-Fi Network**: `http://<your-laptop-ip>:8080`

The database will be automatically created at `server/online_database.sqlite`.

## REST API Endpoints

- `GET /api/health` - Ping server health
- `POST /api/register` - Create a cloud user account
- `POST /api/login` - Cloud user authentication
- `POST /api/readings/push` & `GET /api/readings/pull?user_id=X` - Sync glucose readings
- `POST /api/references/push` & `GET /api/references/pull?user_id=X` - Sync finger-prick reference log
- `POST /api/settings/push` & `GET /api/settings/pull?user_id=X` - Sync user settings
