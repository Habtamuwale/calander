import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'services/auth_service.dart';
import 'firebase_options.dart'; // Import the generated config
import 'package:timezone/data/latest.dart' as tz;
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initialize();
  
  bool isFirebaseInitialized = false;
  String initError = "";

  try {
    // Use the officially generated options
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    isFirebaseInitialized = true;
  } catch (e) {
    print("Firebase initialization failed: $e");
    initError = e.toString();
    
    // Attempt fallback for non-web platforms if applicable
    try {
      await Firebase.initializeApp();
      isFirebaseInitialized = true;
    } catch (_) {}
  }

  runApp(MyApp(
    isInitialized: isFirebaseInitialized, 
    initError: initError
  ));
}

class MyApp extends StatelessWidget {
  final bool isInitialized;
  final String initError;
  final _auth = AuthService();

  MyApp({required this.isInitialized, required this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibrant Scheduler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: !isInitialized 
        ? InitializationErrorPage(error: initError)
        : ListenableBuilder(
            listenable: _auth,
            builder: (context, _) => StreamBuilder<User?>(
              stream: _auth.user,
              builder: (context, snapshot) {
                // Determine the correct screen based on auth state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return LoadingPage();
                }

                final user = snapshot.data;
                if (user == null) {
                  // Not logged in -> Show Login
                  return LoginScreen();
                } else if (_auth.isOtpVerified) {
                  // Logged in AND OTP Verified -> Show Dashboard
                  return DashboardScreen();
                } else {
                  // Logged in but NOT OTP Verified -> Show OTP Screen
                  return OtpVerificationScreen(email: user.email ?? '');
                }
              },
            ),
          ),
    );
  }
}

class LoadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.indigo),
            SizedBox(height: 20),
            Text("Starting Vibrant Scheduler...", style: TextStyle(color: Colors.indigo)),
          ],
        ),
      ),
    );
  }
}

class InitializationErrorPage extends StatelessWidget {
  final String error;
  InitializationErrorPage({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
            SizedBox(height: 24),
            Text(
              "Firebase Not Configured",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "To run the app on Web, you must provide your Firebase configuration in 'lib/firebase_options_manual.dart'.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
              child: Text(error, style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // In a real app we'd trigger a reload, but for now we'll just show the Dashboard anyway
                // to let the user see the visual progress.
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => DashboardScreen())
                );
              },
              child: Text("Bypass to Dashboard (Demo Mode)"),
            )
          ],
        ),
      ),
    );
  }
}
