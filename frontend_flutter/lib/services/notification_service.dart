// import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  // final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permissions and setup listeners
  }

  Future<void> scheduleReminder(String title, DateTime time) async {
    // Implement local or push notifications logic
    print("Scheduled reminder for $title at $time");
  }
}
