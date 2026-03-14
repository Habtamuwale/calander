import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({Key? key, required this.email}) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = AuthService();
  bool _isLoading = false;
  bool _isVerified = false;
  String _error = '';
  String _message = '';

  @override
  void initState() {
    super.initState();
    // Automatically trigger OTP if we just landed here (e.g. app restart)
    // and haven't sent one for this email yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_auth.lastOtpEmail != widget.email) {
        _resendOtp(silent: true);
      }
    });
  }

  void _resendOtp({bool silent = false}) async {
    if (!silent) setState(() { _isLoading = true; _error = ''; _message = ''; });
    try {
      final msg = await _auth.requestOTP(widget.email);
      if (!silent) setState(() => _message = msg);
    } catch (e) {
      if (!silent) setState(() => _error = e.toString());
    } finally {
      if (!silent) setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      setState(() => _error = 'OTP code is required.');
      return;
    }
    if (otp.length != 6 || !RegExp(r'^\d+$').hasMatch(otp)) {
      setState(() => _error = 'Please enter a valid 6-digit number.');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });

    try {
      await _auth.verifyOTP(widget.email, otp);
      
      if (mounted) {
        if (FirebaseAuth.instance.currentUser != null) {
          // Success Feedback
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Email Verified! Logged in successfully."), backgroundColor: Colors.green)
          );
          _auth.setOtpVerified(true);
        } else {
          setState(() {
            _isVerified = true;
            _message = 'OTP Verified! You can now set your new password.';
          });
        }
      }
    } catch (e) {
      setState(() {
        final err = e.toString();
        if (err.contains('expired') || err.contains('expired-otp')) {
          _error = "The OTP has expired. Please request a new one.";
        } else if (err.contains('invalid') || err.contains('incorrect')) {
          _error = "Incorrect OTP. Please check the code and try again.";
        } else {
          _error = err.split(']').last.trim();
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetPassword() async {
    if (_passwordController.text.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() { _isLoading = true; _error = ''; });

    try {
      final msg = await _auth.resetPasswordWithOTP(widget.email, _passwordController.text);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP"), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.indigo),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Container(
            constraints: BoxConstraints(maxWidth: 400),
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isVerified ? Icons.lock_open : Icons.mark_email_unread_outlined, size: 64, color: Colors.indigo),
                SizedBox(height: 16),
                Text(_isVerified ? "New Password" : "Verify OTP", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                SizedBox(height: 8),
                Text(
                  _isVerified ? "Set a strong password for your account." : "Enter the 6-digit code sent to ${widget.email}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 24),
                if (_error.isNotEmpty) Text(_error, style: TextStyle(color: Colors.red)),
                if (_message.isNotEmpty) Text(_message, style: TextStyle(color: Colors.green)),
                SizedBox(height: 16),
                if (!_isVerified && FirebaseAuth.instance.currentUser == null)
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(labelText: '6-Digit OTP'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  )
                else if (FirebaseAuth.instance.currentUser != null)
                   TextField(
                    controller: _otpController,
                    decoration: InputDecoration(labelText: '6-Digit OTP'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  )
                else
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline)),
                    obscureText: true,
                  ),
                SizedBox(height: 32),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        onPressed: (FirebaseAuth.instance.currentUser != null) ? _verifyOtp : (_isVerified ? _resetPassword : _verifyOtp),
                    child: Text((FirebaseAuth.instance.currentUser != null) ? "Verify Login" : (_isVerified ? "Update Password" : "Verify Code")),
                      ),
                if (!_isVerified) ...[
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : () => _resendOtp(),
                    child: Text("Resend OTP Code", style: TextStyle(color: Colors.indigo)),
                  ),
                ],
                if (FirebaseAuth.instance.currentUser != null) ...[
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await _auth.signOut();
                    },
                    child: Text("Sign Out / Change Account", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
