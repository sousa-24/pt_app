# FITPRO

Personal Trainer management app built with Flutter + FastAPI + MySQL.

Trainers can manage clients, workout plans, group sessions, nutrition plans, progress tracking, chat and payments/invoices. Clients get their own personal area with their plans, sessions, progress and notifications.

## Project Structure
```
app_pt/
├── backend/    → FastAPI backend (app/main.py)
└── frontend/   → Flutter frontend (web/mobile)
```

## Requirements

- Python 3.10+
- Flutter 3.0+

The app uses a shared MySQL database hosted on Railway — no local database setup is needed.

---

## Backend Setup

### 1 — Clone the repository

```bash
git clone https://github.com/sousa-24/pt_app.git
cd pt_app
```

### 2 — Create virtual environment

**Linux:**
```bash
cd backend
python -m venv venv
source venv/bin/activate
```

**Windows:**
```bash
cd backend
python -m venv venv
venv\Scripts\activate
```

### 3 — Install dependencies

```bash
pip install -r requirements.txt
```

### 4 — Create .env file

Create a file called `.env` inside the `backend/` folder with the following keys (ask the project owner for the actual values — these point to the shared Railway database):

```
DB_HOST=
DB_PORT=
DB_USER=
DB_PASSWORD=
DB_NAME=
SECRET_KEY=
CLOUDINARY_CLOUD_NAME=
CLOUDINARY_API_KEY=
CLOUDINARY_API_SECRET=
```

### 5 — Run the backend

```bash
uvicorn app.main:app --reload
```

Backend running at http://127.0.0.1:8000
API docs at http://127.0.0.1:8000/docs

---

## Frontend Setup

### 1 — Install Flutter

Follow the official guide at https://flutter.dev/docs/get-started/install

### 2 — Install dependencies

```bash
cd frontend
flutter pub get
```

### 3 — Run the app

```bash
flutter run -d chrome
```

By default the app points to the production backend on Railway
(`https://backend-production-d7c3c.up.railway.app`). To point it at a local
backend instead, run:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

---

## Deployment

- **Backend:** deployed on [Railway](https://railway.app) (project `protective-courtesy`, service `backend`), together with the MySQL database. Deploy with `railway up --service backend` from the `backend/` folder.
- **Frontend:** built locally (web / Android APK). The API base URL is controlled via the `API_BASE_URL` dart-define in `frontend/lib/app_config.dart`.

---

## Team Workflow

### Before starting work:
```bash
git pull origin master
```

### After making changes:
```bash
git add .
git commit -m "description of what you did"
git push origin master
```

### Working on a feature (recommended):
```bash
git checkout -b feature/your-feature-name
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub for the team to review before merging.

---

## Current Features

- ✅ Authentication (register + login + JWT tokens)
- ✅ Trainer / client profiles with profile picture upload (Cloudinary)
- ✅ Invite codes to link clients with trainers
- ✅ Workout plans with exercises
- ✅ Individual and group training sessions
- ✅ Session feedback
- ✅ Progress tracking
- ✅ Nutrition plans
- ✅ Real-time chat (WebSocket) and contacts
- ✅ Notifications
- ✅ Payments / invoices management

---

## Notes

- The `.env` file is not included in the repository for security reasons. Ask the project owner for the credentials.
- The database is shared (hosted on Railway) — be careful with destructive operations, they affect everyone.
- Always pull before starting work to avoid conflicts.
