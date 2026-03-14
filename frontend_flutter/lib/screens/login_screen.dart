import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  String _error = '';
  String? _emailError;
  String? _passwordError;

  bool _validateForm() {
    bool valid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    
    // Improved email regex matching the one used in signup
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty) {
      _emailError = 'Email is required.';
      valid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = 'Please enter a valid email address.';
      valid = false;
    } else {
      _emailError = null;
    }

    if (password.isEmpty) {
      _passwordError = 'Password is required.';
      valid = false;
    } else if (password.length < 8) {
      _passwordError = 'Password must be at least 8 characters.';
      valid = false;
    } else {
      _passwordError = null;
    }

    setState(() {});
    return valid;
  }

  void _login() async {
    if (!_validateForm()) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _auth.signIn(_emailController.text.trim(), _passwordController.text);
      // On success, the Main.dart StreamBuilder will handle the switch to 
      // the Dashboard or OTP screen automatically.
    } catch (e) {
      if (mounted) {
        setState(() {
          // Detailed mapping of Firebase error codes to user-friendly messages
          final errorStr = e.toString();
          if (errorStr.contains('invalid-credential') || errorStr.contains('user-not-found') || errorStr.contains('wrong-password')) {
            _error = "Invalid email or password. Please try again.";
          } else if (errorStr.contains('network-request-failed')) {
            _error = "Network error. Please check your internet connection.";
          } else if (errorStr.contains('too-many-requests')) {
            _error = "Too many failed attempts. Please try again later.";
          } else {
            _error = "Login failed: ${e.toString().split(']').last.trim()}";
          }
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Log In",
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.indigo
                  ),
                ),
                SizedBox(height: 24),
                if (_error.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(_error, style: TextStyle(color: Colors.red)),
                  ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: const OutlineInputBorder(),
                    errorText: _emailError,
                  ),
                  onChanged: (_) { if (_emailError != null) setState(() => _emailError = null); },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    errorText: _passwordError,
                  ),
                  obscureText: true,
                  onChanged: (_) { if (_passwordError != null) setState(() => _passwordError = null); },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => ForgotPasswordScreen())
                    ),
                    child: Text("Forgot Password?", style: TextStyle(color: Colors.indigo)),
                  ),
                ),
                SizedBox(height: 16),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _login,
                        child: Text("Login"),
                      ),


                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen())),
                  child: Text("Need an account? Sign Up"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
