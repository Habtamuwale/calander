# 🗓️ Vibrant Event Scheduler

A state-of-the-art, cross-platform event scheduling application built with **Flutter** and **Node.js**. This application supports complex recurrence patterns, secure OTP-based authentication, and seamless Firebase integration.

---

## ✨ Features

### 📅 Calendar & Events
- **Syncfusion Visual Calendar**: High-performance interactive calendar with Day, Week, and Month views.
- **Complex Recurrence Patterns**:
    - **Intervals**: "Every 2 weeks", "Every 3 days".
    - **Specific Days**: Select multiple days (e.g., Mon, Wed, Fri).
    - **Relative Scheduling**: "Last Friday of every month", "Third Thursday of June".
- **Drag & Drop**: Easily move events with interactive drag functionality.
- **List View**: A clean, chronological overview of all your upcoming activities.

### 🔐 Authentication & Security
- **Firebase Auth**: Robust login and signup flow.
- **OTP Verification**: Enhanced security for login and password resets using 6-digit One-Time Passwords via email.
- **Password Recovery**: Secure "Forgot Password" flow with automated recovery links and OTPs.

### ☁️ Backend & Sync
- **Real-time Firestore Sync**: Instant data persistence across all devices.
- **Node.js API**: Clean Express backend for handling sensitive operations (OTP, Emailing).
- **Automated Reminders**: Built-in scheduler to send email reminders for upcoming events.

---

## 🏗️ Project Structure

```text
/home/habtamu/schedule/
├── 📂 backend/                   # Node.js + Express Server
│   ├── 📂 routes/               # API Endpoints (Auth, Events)
│   ├── 📂 services/             # Logic (Email, OTP, Firebase Admin)
│   ├── 📂 models/               # Data Structures
│   ├── 📄 server.js             # Entry Point & Middlewares
│   └── 📄 .env                  # Environment Variables (Secrets)
│
├── 📂 frontend_flutter/          # Flutter Cross-Platform App
│   ├── 📂 lib/
│   │   ├── 📂 screens/          # App Views (Login, Home, OTP, etc.)
│   │   ├── 📂 widgets/          # Reusable UI Components
│   │   ├── 📂 services/         # API & Backend Communication
│   │   ├── 📂 models/           # Frontend Data Models
│   │   └── 📄 main.dart         # Flutter Entry Point
│   └── 📄 pubspec.yaml          # Flutter Dependencies
│
└── 📄 README.md                 # Project Documentation
```

---

## 🛠️ Step-by-Step Setup

### 1️⃣ Prerequisites
- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Node.js**: [Install Node.js (v14+)](https://nodejs.org/)
- **Firebase Account**: Create a project in [Firebase Console](https://console.firebase.google.com/)

### 2️⃣ Backend Setup (Node.js)
```bash
cd backend
npm install
```

**Configuration:**
- Create a `.env` file in the `backend/` directory:
  ```env
  PORT=5000
  EMAIL_USER=your-email@gmail.com
  EMAIL_PASS=your-gmail-app-password
  ```
- Download your **Service Account Key** (JSON) from Firebase Console:
  1. Project Settings > Service Accounts.
  2. Click **Generate New Private Key**.
  3. Rename it to `serviceAccountKey.json` and place it in the `backend/` folder.

**Run Backend:**
```bash
npm start
```

### 3️⃣ Frontend Setup (Flutter)
```bash
cd frontend_flutter
flutter pub get
```

**Configuration:**
- Configure Firebase for the app:
  - Run `flutterfire configure` OR
  - Manually add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective folders.

**Run Frontend:**
```bash
# To run on Chrome (Web)
flutter run -d chrome

# To run on Desktop (Linux)
flutter run -d linux
```

---

## 🧪 Testing the OTP System
1. Start the **Backend** and **Frontend**.
2. Go to the **Signup** or **Forgot Password** screen in the app.
3. Enter your email and click "Request OTP".
4. Check your email for the 6-digit code.
5. Check the **Backend Terminal** to see the logs if the email isn't arriving.

---

## 📜 License
This project is licensed under the ISC License.

---
*Created with ❤️ by the Vibrant Scheduler Team*
