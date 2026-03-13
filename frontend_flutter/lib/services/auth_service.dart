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

  bool get isOtpVerified => _isOtpVerified;
  String? get lastOtpEmail => _lastOtpEmail;
  void setOtpVerified(bool value) {
    if (_isOtpVerified == value) return;
    _isOtpVerified = value;
    notifyListeners();
  }

  Stream<User?> get user => _auth.authStateChanges();

  Future<UserCredential?> signUp(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      // We don't await the OTP request here to allow immediate UI transition.
      // The secondary trigger in OtpVerificationScreen.initState will catch it.
      requestOTP(email).catchError((e) => print("Background OTP Error: $e"));
      return cred;
    } catch (e) {
      print("Signup Error: $e");
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      // Trigger OTP request in background and return immediately
      requestOTP(email).catchError((e) => print("Background OTP Error: $e"));
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
}
