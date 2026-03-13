import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    
    // Linux requires a specific icon
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click
      },
    );
  }

  Future<void> scheduleReminder(String title, DateTime time, {String? body}) async {
    if (kIsWeb) {
      // Logic for web reminders (simplified as browsers have restrictions)
      final now = DateTime.now();
      final delay = time.difference(now);
      if (delay.isNegative) return;

      Future.delayed(delay, () {
        _playNotificationSound();
      });
      return;
    }

    // Local notification logic for Mobile/Desktop
    final scheduledDate = tz.TZDateTime.from(time, tz.local);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'Event remidner notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('notification_sound'), // Optional: custom sound
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(presentSound: true),
      linux: LinuxNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      time.hashCode,
      'Reminder: $title',
      body ?? 'Your event is starting soon!',
      scheduledDate,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/ringtone.mp3'));
    } catch (e) {
      print("Error playing notification sound: $e");
    }
  }

  Future<void> playImmediateSound() async {
     await _playNotificationSound();
  }
}
