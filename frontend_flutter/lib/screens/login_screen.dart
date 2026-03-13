import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';

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

  void _login() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await _auth.signIn(_emailController.text, _passwordController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
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
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                SizedBox(height: 32),
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
                SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48),
                    side: BorderSide(color: Colors.indigo),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context, 
                    MaterialPageRoute(builder: (context) => DashboardScreen())
                  ),
                  child: Text("Try Demo Mode (Bypass Auth)", style: TextStyle(color: Colors.indigo)),
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
