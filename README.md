# PT App

Personal Trainer app built with Flutter + FastAPI + MySQL.

## Project Structure
app_pt/
├── backend/    → FastAPI backend
└── frontend/   → Flutter frontend

## Requirements

- Python 3.10+
- Flutter 3.0+
- MySQL 8.0+

---

## Backend Setup

### 1 — Install MySQL

**Linux:**
```bash
sudo apt install mysql-server
sudo systemctl start mysql
sudo mysql_secure_installation
```

**Windows:**
Download and install from [mysql.com](https://dev.mysql.com/downloads/installer/)

### 2 — Create the database

**Linux:**
```bash
sudo mysql -u root -p
```

**Windows:**
```bash
mysql -u root -p
```

```sql
CREATE DATABASE pt_app;
CREATE USER 'ptuser'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON pt_app.* TO 'ptuser'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3 — Clone the repository

```bash
git clone https://github.com/sousa-24/pt_app.git
cd pt_app
```

### 4 — Create virtual environment

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

### 5 — Install dependencies

```bash
pip install -r requirements.txt
```

### 6 — Create .env file

Create a file called `.env` inside the `backend/` folder. Ask the project owner for the actual values:

### 7 — Run the backend

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
- ✅ Workout plans with exercises
- ✅ Training sessions
- ✅ Progress tracking
- ⬜ Nutrition plans
- ⬜ Real-time chat
- ⬜ Trainer dashboard
- ⬜ Client dashboard

---

## Notes

- The `.env` file is not included in the repository for security reasons. Ask the project owner for the credentials.
- Each developer runs their own local MySQL database.
- Always pull before starting work to avoid conflicts.