# Event Scheduler with Complex Recurrence Patterns

A cross-platform event scheduling application built with **Flutter** and **Node.js**.

## 🚀 Features

- **Single Occurrence Events**: Schedule one-time meetings or tasks.
- **Standard Recurrence**: Daily, Weekly, Monthly, and Yearly patterns.
- **Complex Recurrence**:
    - **Intervals**: Schedule events like "Every 3 days" or "Every 2 weeks".
    - **Specific Weekdays**: Multi-select days (e.g., "Mon, Wed, Fri").
    - **Relative Dates**: Support for "First Monday", "Third Friday", or "Last Weekday".
- **Special Cases**: Achievable patterns include:
    - *"Every third Thursday of the month"* (Monthly + Pos: 3rd + Day: TH)
    - *"The last weekday of the year"* (Yearly + Pos: Last + Days: MO-FR)
- **Visual Calendar**: Powered by **Syncfusion Flutter Calendar**.
- **List View**: Chronological list of upcoming events.
- **Authentication**: Secure login/signup via **Firebase Auth**.
- **Cloud Sync**: Real-time storage in **Firestore**.
- **Advanced Features**: Drag & Drop, Timezone support, and more.

## 🛠 Technology Stack

- **Frontend**: Flutter
- **Backend**: Node.js + Express
- **Database/Auth**: Firebase Firestore & Auth
- **Calendar Logic**: Syncfusion Calendar + rrule

## 📂 Project Structure

```
event_scheduler/
│
├── frontend_flutter/  # Flutter Application
│     ├── lib/
│     │    ├── screens/   # UI Screens (Login, Home, etc.)
│     │    ├── widgets/   # Reusable UI widgets
│     │    ├── models/    # Data models (Event)
│     │    ├── services/  # API and Firebase services
│     │    └── main.dart
│
├── backend/           # Node.js API
│     ├── controllers/ # Logic for API endpoints
│     ├── routes/      # Definition of API routes
│     ├── models/      # (Optional) Schema abstractions
│     ├── services/    # External integrations (Firebase Admin)
│     └── server.js    # Entry point
│
└── README.md
```

## 📦 Getting Started

### Backend
1. `cd backend`
2. `npm install`
3. Add your `serviceAccountKey.json` to the `backend/` folder.
4. `npm start`

### Frontend (Flutter)
1. `cd frontend_flutter`
2. `flutter pub get`
3. Configure Firebase using the FlutterFire CLI or manual setup.
4. `flutter run -d chrome` (for web) or target mobile/desktop devices.
# calander
