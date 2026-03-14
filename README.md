# 🗓️ Vibrant Event Scheduler

A state-of-the-art, cross-platform event scheduling application built with **Flutter** and **Node.js**. This application supports complex recurrence patterns, secure OTP-based authentication, and seamless Firebase integration.

---

## 📸 App Visuals & Gallery

### 🔐 Authentication Flow
| Login | Signup | OTP Verification |
| :---: | :---: | :---: |
| ![Login](./screenshots/login.png) | ![Signup](./screenshots/signup.png) | ![OTP](./screenshots/OTP_screen.png) |
| *Login Screen* | *Signup Screen* | *Secure OTP* |

| Forgot Password | Reset Password | Login (Alt) |
| :---: | :---: | :---: |
| ![Forgot Password](./screenshots/forget_email_screen.png) | ![Reset Password](./screenshots/enter_new_password.png) | ![Login Alt](./screenshots/login%20page.png) |
| *Email Input* | *New Password* | *Alt Login* |

### 📅 Calendar & Event Management
| Main Calendar View | Event Creation Form | Time Picker |
| :---: | :---: | :---: |
| ![Calendar](./screenshots/viewscreen.png) | ![Event Form](./screenshots/Scheduled_form_screen.png) | ![Time Picker](./screenshots/Time_form.png) |
| *Visual Calendar* | *New Event* | *Time Selection* |

| Date Picker | Recurrence Settings | Edit Event |
| :---: | :---: | :---: |
| ![Date Picker](./screenshots/date_form.png) | ![Recurrence](./screenshots/select_daily_month_year.png) | ![Edit Form](./screenshots/sheduled_edit_form.png) |
| *Date Selection* | *Complex Patterns* | *Modify Event* |

| Event Details | Upcoming Schedule | Day Indicator |
| :---: | :---: | :---: |
| ![Details](./screenshots/schedule_details.png) | ![Upcoming](./screenshots/upcoming_scheduled.png) | ![Indicator](./screenshots/scheduled_day_indicater.png) |
| *Event Info* | *List View* | *Day Markers* |

### 👤 Profile & Others
| Profile Settings 1 | Profile Settings 2 | System Screenshot |
| :---: | :---: | :---: |
| ![Profile 1](./screenshots/edite_profile_1.png) | ![Profile 2](./screenshots/edit_profile_2.png) | ![System](./screenshots/Screenshot%20from%202026-03-14%2009-48-50.png) |
| *Personal Info* | *Update Profile* | *Dev Progress* |

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

## 🏛️ System Architecture

The application follows a clean **MVC (Model-View-Controller)** architectural pattern, ensuring a clear separation of concerns between the data, UI, and business logic.

### 🧩 Architecture Overview
- **Model (Data Layer)**: Handles data structures and interactions with **Firebase Firestore**. Located in `backend/models/` and `frontend_flutter/lib/models/`.
- **View (UI Layer)**: Built with **Flutter**, providing a reactive and cross-platform user experience.
- **Controller/API (Logic Layer)**: The **Node.js/Express** backend acts as the controller, managing business logic, authentication flows, and data orchestration.

### 📡 Communication Flow
1. **Frontend**: Sends HTTPS requests to the REST API.
2. **Backend (Controller)**: Validates requests and calls the appropriate **Services** (OTP, Email, Firebase Admin).
3. **Database**: Real-time synchronization is handled through **Firestore**, while sensitive operations go through the secure Node.js backend.

---

## 🏗️ Project Structure (MVC Architecture)

```text
.
├── 📂 backend                  # Controller & API Logic
│   ├── 📂 controllers          # [CONTROLLER] Request handling logic
│   │   └── eventController.js
│   ├── 📂 models               # [MODEL] Data schemas & definitions
│   │   └── Event.js
│   ├── 📂 routes               # API Endpoint Routing
│   │   ├── authRoutes.js
│   │   └── eventRoutes.js
│   ├── 📂 services             # Business Logic & Infrastructure (OTP, Firebase)
│   │   ├── authService.js
│   │   ├── emailService.js
│   │   ├── firebase.js
│   │   ├── otpService.js
│   │   └── scheduler.js
│   ├── server.js               # Entry Point
│   └── serviceAccountKey.json
│
├── 📂 frontend_flutter         # View & Client UI
│   ├── 📂 lib
│   │   ├── 📂 screens          # [VIEW] Application Screens/Pages
│   │   ├── 📂 widgets          # [VIEW] Reusable UI Components
│   │   ├── 📂 models           # [MODEL] Frontend Data objects
│   │   ├── 📂 services         # API Client & Backend Communication
│   │   ├── main.dart           # App Entry Point
│   │   └── firebase_options.dart
│   ├── pubspec.yaml            # Dependencies
│   └── 📂 assets               # Static Visuals
│
└── 📂 screenshots              # Project Documentation Visuals
    ├── (18 images showcasing the MVC flow)
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
1. Create a `.env` file in the `backend/` directory:
   ```env
   PORT=5000
   EMAIL_USER=your-email@gmail.com
   EMAIL_PASS=your-gmail-app-password
   ```
2. Download your **Service Account Key** (JSON) from Firebase Console:
   - Project Settings > Service Accounts.
   - Click **Generate New Private Key**.
   - Rename it to `serviceAccountKey.json` and place it in the `backend/` folder.

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
*Created with ❤️ by Habtamu Wale*
