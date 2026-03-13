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
    final emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty) {
      _emailError = 'Email is required.';
      valid = false;
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = 'Enter a valid email address.';
      valid = false;
    } else {
      _emailError = null;
    }

    if (password.isEmpty) {
      _passwordError = 'Password is required.';
      valid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters.';
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
      await _auth.signIn(_emailController.text, _passwordController.text);
      // On success, we don't reset _isLoading to avoid flickering the form 
      // before the StreamBuilder switches to the OTP screen.
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
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
