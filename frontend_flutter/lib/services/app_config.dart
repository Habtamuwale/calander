import 'package:flutter/foundation.dart';
import 'dart:html' as html; // Only works on Web

class AppConfig {
  // Automatically detects if we are on localhost or the live web
  static bool get isLocal {
    if (!kIsWeb) return true; // Default to local for mobile/desktop
    return html.window.location.hostname == 'localhost' || html.window.location.hostname == '127.0.0.1';
  }

  // --- BACKEND URL ---
  static const String localUrl = 'http://localhost:5000';
  static const String remoteUrl = 'https://calander-h6vv.onrender.com';

  static String get baseUrl => isLocal ? localUrl : remoteUrl;

  // --- API ENDPOINTS ---
  static String get authEndpoint => '$baseUrl/api/auth';
  static String get eventsEndpoint => '$baseUrl/api/events';

  // --- HELPER STRINGS ---
  static const String appName = 'Vibrant Scheduler';
}
