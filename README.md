# SMTP Checker API & Flutter App

A comprehensive solution for validating SMTP server credentials, with:
- **FastAPI backend** for server-side checking
- **Flutter mobile app** for easy access
- Batch processing capabilities

## Features

### Backend (FastAPI)
✅ Single SMTP validation  
✅ Batch SMTP checking with configurable threads  
✅ Test email sending capability  
✅ Detailed error reporting  
✅ CORS support for mobile/Web integration  

### Mobile App (Flutter)
📱 Single SMTP verification  
📊 Batch processing of SMTP lists  
📈 Real-time progress tracking  
🎨 Color-coded results (valid/invalid)  
📤 Export results  

## Installation

### Backend Setup

1. Clone the repository:
```bash
git clone https://github.com/yourusername/smtp-checker.git
cd smtp-checker/backend
```

## Install dependencies:
```bash
Copy
pip install -r requirements.txt
```
Run the server:
```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```
The API will be available at http://localhost:8000
API docs: http://localhost:8000/docs

## Mobile App Setup

Navigate to the Flutter project:
```bash
cd ../mobile
```
Install dependencies:
```bash
flutter pub get
```
Run the app:
```bash
flutter run
```
## Configuration

Backend Environment Variables

Create a .env file:
```
# For production
SECRET_KEY=your-secret-key
ALLOWED_ORIGINS=https://yourdomain.com
MAX_THREADS=20
Mobile App Configuration
```
Edit lib/api/smtp_service.dart:

dart
```
static const String baseUrl = "http://your-api-address:8000";
```
Usage Examples

## Single SMTP Check (API)

```bash

curl -X POST "http://localhost:8000/check-single" \
-H "Content-Type: application/json" \
-d '{"host":"smtp.example.com","port":587,"username":"user@example.com","password":"yourpassword"}'
Batch Check (API)
```
```bash
curl -X POST "http://localhost:8000/batch-check" \
-H "Content-Type: application/json" \
-d '{"smtp_list":[{"host":"smtp1.example.com","port":587,"username":"user1","password":"pass1"},{"host":"smtp2.example.com","port":465,"username":"user2","password":"pass2"}],"threads":5}'
```
## Screenshots

Mobile App	API Docs
App Screenshot	API Docs
Project Structure
```
smtp-checker/
├── backend/               # FastAPI implementation
│   ├── main.py            # Core API logic
│   ├── requirements.txt   # Python dependencies
│   └── Result/            # Generated reports
│
├── mobile/                # Flutter application
│   ├── lib/
│   │   ├── api/           # API service classes
│   │   ├── models/        # Data models
│   │   └── screens/       # UI screens
│   └── pubspec.yaml       # Flutter dependencies
│
└── README.md              # This file
```
## Security Considerations

🔒 Important Security Notes:

Never use this tool to check SMTP servers without authorization
In production, always:
Use HTTPS
Implement proper authentication
Restrict CORS origins
Rate limit endpoints
Contributing

Contact

Telegram: @r10xM

