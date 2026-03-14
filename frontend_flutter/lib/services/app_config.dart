class AppConfig {
  // --- REMOTE BACKEND URL ---
  // When you host your backend (e.g., on Render or Railway), 
  // put the URL here. Example: 'https://my-api.onrender.com'
  static const String baseUrl = 'http://localhost:5000'; 

  // --- API ENDPOINTS ---
  static const String authEndpoint = '$baseUrl/api/auth';
  static const String eventsEndpoint = '$baseUrl/api/events';

  // --- HELPER STRINGS ---
  static const String appName = 'Vibrant Scheduler';
}
