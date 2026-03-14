class AppConfig {
  // --- BACKEND URL ---
  // Use 'http://localhost:5000' for Web/Desktop/iOS
  // Use 'http://10.0.2.2:5000' for Android Emulator
  static const String baseUrl = 'http://localhost:5000'; 

  // --- API ENDPOINTS ---
  static const String authEndpoint = '$baseUrl/api/auth';
  static const String eventsEndpoint = '$baseUrl/api/events';

  // --- HELPER STRINGS ---
  static const String appName = 'Vibrant Scheduler';
}
