import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();

  // --- Display Name ---
  final _nameController = TextEditingController();
  bool _savingName = false;

  // --- Change Email ---
  final _newEmailController = TextEditingController();
  final _emailPasswordController = TextEditingController();
  bool _savingEmail = false;
  String? _newEmailError;
  String? _emailPasswordError;

  // --- Change Password ---
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _savingPassword = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _nameController.text = _auth.currentUser?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newEmailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ---- Save Display Name ----
  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Display name cannot be empty.', isError: true);
      return;
    }
    setState(() => _savingName = true);
    try {
      await _auth.updateDisplayName(name);
      _showSnack('Display name updated successfully!');
    } catch (e) {
      _showSnack('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  // ---- Update Email ----
  bool _validateEmailForm() {
    bool valid = true;
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    final email = _newEmailController.text.trim();
    setState(() {
      _newEmailError = email.isEmpty
          ? 'New email is required.'
          : !emailRegex.hasMatch(email)
              ? 'Enter a valid email address.'
              : email == _auth.currentUser?.email
                  ? 'This is already your current email.'
                  : null;
      _emailPasswordError = _emailPasswordController.text.isEmpty ? 'Password is required to confirm.' : null;
      if (_newEmailError != null || _emailPasswordError != null) valid = false;
    });
    return valid;
  }

  Future<void> _saveEmail() async {
    if (!_validateEmailForm()) return;
    setState(() => _savingEmail = true);
    try {
      await _auth.updateEmail(
        _newEmailController.text.trim(),
        _emailPasswordController.text,
      );
      _newEmailController.clear();
      _emailPasswordController.clear();
      _showSnack('Verification email sent! Check your inbox to confirm the new email.');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
        setState(() => _emailPasswordError = 'Incorrect password. Please try again.');
      } else {
        _showSnack('Error: $msg', isError: true);
      }
    } finally {
      if (mounted) setState(() => _savingEmail = false);
    }
  }

  // ---- Change Password ----
  bool _validatePasswordForm() {
    bool valid = true;
    final newPwd = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;
    setState(() {
      _currentPasswordError = _currentPasswordController.text.isEmpty ? 'Current password is required.' : null;
      
      if (newPwd.isEmpty) {
        _newPasswordError = 'New password is required.';
      } else if (newPwd.length < 8) {
        _newPasswordError = 'Password must be at least 8 characters.';
      } else if (newPwd == _currentPasswordController.text) {
        _newPasswordError = 'New password cannot be the same as current.';
      } else if (!RegExp(r'[A-Z]').hasMatch(newPwd)) {
        _newPasswordError = 'Include at least one uppercase letter.';
      } else if (!RegExp(r'[0-9]').hasMatch(newPwd)) {
        _newPasswordError = 'Include at least one number.';
      } else if (!RegExp(r'[!@#\$&*~]').hasMatch(newPwd)) {
        _newPasswordError = 'Include one special character (!@#\$&*~).';
      } else {
        _newPasswordError = null;
      }

      _confirmPasswordError = confirm.isEmpty
          ? 'Please confirm your new password.'
          : confirm != newPwd
              ? 'Passwords do not match.'
              : null;
      
      if (_currentPasswordError != null || _newPasswordError != null || _confirmPasswordError != null) {
        valid = false;
      }
    });
    return valid;
  }

  Future<void> _savePassword() async {
    if (!_validatePasswordForm()) return;
    setState(() => _savingPassword = true);
    try {
      await _auth.updatePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _showSnack('Password changed successfully!');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
        setState(() => _currentPasswordError = 'Incorrect current password.');
      } else {
        _showSnack('Error: $msg', isError: true);
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  // ---- Delete Account ----
  void _confirmDeleteAccount() {
    final pwdController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Account', style: TextStyle(color: Colors.red)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This action is permanent and cannot be undone. All your events will be lost.', style: TextStyle(color: Colors.black87)),
            const SizedBox(height: 16),
            TextField(
              controller: pwdController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password to confirm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _auth.deleteAccount(pwdController.text);
              } catch (e) {
                _showSnack('Error: $e', isError: true);
              }
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
            ]),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _auth,
      builder: (context, _) {
        final user = _auth.currentUser;
        final initial = (user?.displayName?.isNotEmpty == true)
            ? user!.displayName![0].toUpperCase()
            : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : '?');

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('My Profile'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView(
            children: [
              // --- Header ---
              Container(
                color: Colors.indigo,
                padding: const EdgeInsets.only(bottom: 32, top: 8),
                child: Column(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    child: Text(initial, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName?.isNotEmpty == true ? user!.displayName! : 'No Name Set',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(user?.email ?? '', style: TextStyle(color: Colors.indigo[100], fontSize: 14)),
                ]),
              ),

              const SizedBox(height: 16),

              // --- Display Name ---
              _sectionCard(
                title: 'Display Name',
                icon: Icons.person_outline,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      onPressed: _savingName ? null : _saveName,
                      icon: _savingName ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                      label: const Text('Save Name'),
                    ),
                  ),
                ],
              ),

              // --- Change Email ---
              _sectionCard(
                title: 'Change Email',
                icon: Icons.email_outlined,
                children: [
                  Text('Current email: ${user?.email ?? ""}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'New Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      errorText: _newEmailError,
                    ),
                    onChanged: (_) { if (_newEmailError != null) setState(() => _newEmailError = null); },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Current Password (to confirm)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      errorText: _emailPasswordError,
                    ),
                    onChanged: (_) { if (_emailPasswordError != null) setState(() => _emailPasswordError = null); },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      onPressed: _savingEmail ? null : _saveEmail,
                      icon: _savingEmail ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.email),
                      label: const Text('Update Email'),
                    ),
                  ),
                ],
              ),

              // --- Change Password ---
              _sectionCard(
                title: 'Change Password',
                icon: Icons.lock_outline,
                children: [
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      errorText: _currentPasswordError,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    onChanged: (_) { if (_currentPasswordError != null) setState(() => _currentPasswordError = null); },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: const OutlineInputBorder(),
                      errorText: _newPasswordError,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    onChanged: (_) { if (_newPasswordError != null) setState(() => _newPasswordError = null); },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: const OutlineInputBorder(),
                      errorText: _confirmPasswordError,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    onChanged: (_) { if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null); },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      onPressed: _savingPassword ? null : _savePassword,
                      icon: _savingPassword ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock),
                      label: const Text('Change Password'),
                    ),
                  ),
                ],
              ),

              // --- Danger Zone ---
              _sectionCard(
                title: 'Danger Zone',
                icon: Icons.warning_amber_outlined,
                children: [
                  const Text(
                    'Deleting your account is permanent. All your events and data will be lost forever.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: _confirmDeleteAccount,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete My Account'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
