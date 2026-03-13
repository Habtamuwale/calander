import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isOtpVerified = false;
  String? _lastOtpEmail;

  /// Whether the user has successfully verified the OTP after authentication.
  bool get isOtpVerified => _isOtpVerified;
  
  /// The email address for which the last OTP was requested.
  String? get lastOtpEmail => _lastOtpEmail;

  /// Updates the OTP verification state and notifies listeners for UI updates.
  void setOtpVerified(bool value) {
    if (_isOtpVerified == value) return;
    _isOtpVerified = value;
    notifyListeners();
  }

  Stream<User?> get user => _auth.authStateChanges();

  /// Registers a new user with Firebase and triggers a background OTP request.
  Future<UserCredential?> signUp(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      // Trigger background OTP request so the user finds it in their inbox 
      // by the time they reach the verification screen.
      requestOTP(email).catchError((e) {
        print("Background OTP Error: $e");
        return "";
      });
      return cred;
    } catch (e) {
      print("Signup Error: $e");
      rethrow;
    }
  }

  /// Logs in an existing user and triggers a 2FA-like OTP request.
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      // Trigger background OTP to verify the device/session.
      requestOTP(email).catchError((e) {
        print("Background OTP Error: $e");
        return "";
      });
      return cred;
    } catch (e) {
      print("Signin Error: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    setOtpVerified(false);
  }

  Future<String?> getToken() async {
    return await _auth.currentUser?.getIdToken();
  }

  Future<String> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return data['message'] ?? 'Check your email for a reset link.';
      } else {
        throw data['error'] ?? 'Failed to send reset email';
      }
    } catch (e) {
      print("Password Reset Error: $e");
      rethrow;
    }
  }

  Future<String> requestOTP(String email) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _lastOtpEmail = email;
        return data['message'];
      }
      throw data['error'] ?? 'Failed to request OTP';
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyOTP(String email, String otp) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return true;
    throw data['error'] ?? 'Invalid OTP';
  }

  Future<String> resetPasswordWithOTP(String email, String newPassword) async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/auth/reset-password-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) return data['message'];
    throw data['error'] ?? 'Reset failed';
  }

  // --- Profile Management ---

  User? get currentUser => _auth.currentUser;

  Future<void> updateDisplayName(String name) async {
    final token = await getToken();
    if (token == null) throw 'Not authenticated';

    // 1. Update local Firebase Auth record
    await _auth.currentUser?.updateDisplayName(name);
    
    // 2. Call backend to update Firestore and central Auth record
    final response = await http.post(
      Uri.parse('http://localhost:5000/api/auth/update-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'displayName': name}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw data['error'] ?? 'Failed to sync profile update';
    }

    await _auth.currentUser?.reload();
    notifyListeners();
  }

  Future<void> updateEmail(String newEmail, String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user logged in';
    // Re-authenticate before sensitive operation
    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.verifyBeforeUpdateEmail(newEmail);
    notifyListeners();
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user logged in';
    // Re-authenticate before sensitive operation
    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user logged in';
    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.delete();
    setOtpVerified(false);
  }
}

