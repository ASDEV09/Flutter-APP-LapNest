import 'package:app/signInScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _userEmail = user?.email; // 👈 yahan email le li
  }

  Future<void> _resendVerificationEmail() async {
    try {
      setState(() => _isSending = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email resent!"),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerification() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Email verified! 🎉")));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "We sent you a verification email.",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (_userEmail != null) ...[
              const SizedBox(height: 10),
              Text(
                "Email: $_userEmail", // 👈 yahan show hoga
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSending ? null : _resendVerificationEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // 👈 button color
                foregroundColor: Colors.white, // 👈 text + icon color
              ),
              child: _isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Resend Email"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _checkVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // 👈 button color
                foregroundColor: Colors.white, // 👈 text color
              ),
              child: const Text("I Verified, Continue"),
            ),
          ],
        ),
      ),
    );
  }
}
