import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/Auth/google-sign.dart';
import 'package:flutter/material.dart';
import "package:app/signInScreen.dart";
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _isRememberMe = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  InputDecoration customInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.black),
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFFDFDFD),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.5),
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IconButton(
                //   icon: const FaIcon(FontAwesomeIcons.arrowLeft,  color: Colors.white),
                //   onPressed: () =>
                //       Navigator.pushReplacementNamed(context, '/splash'),
                // ),
                const SizedBox(height: 10),
                const Text(
                  'Create your\nAccount',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 15),

                /// Full Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: customInputDecoration(
                        'Full Name',
                        Icons.person_outline,
                      ).copyWith(
                        filled: true,
                        fillColor: const Color(0xFF0A0F2C),
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Colors.grey,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          _nameError =
                              value.isEmpty ? 'Please enter your full name' : null;
                        });
                      },
                    ),
                    if (_nameError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 12),
                        child: Text(
                          _nameError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Email
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: customInputDecoration(
                        'Email',
                        Icons.email_outlined,
                      ).copyWith(
                        filled: true,
                        fillColor: const Color(0xFF0A0F2C),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.grey,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            _emailError = 'Please enter your email';
                          } else if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            _emailError = 'Please enter a valid email address';
                          } else {
                            _emailError = null;
                          }
                        });
                      },
                    ),
                    if (_emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 12),
                        child: Text(
                          _emailError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Password
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: customInputDecoration(
                        'Password',
                        Icons.lock_outline,
                      ).copyWith(
                        filled: true,
                        fillColor: const Color(0xFF0A0F2C),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            _passwordError = 'Please enter a password';
                          } else if (value.length < 6) {
                            _passwordError =
                                'Password must be at least 6 characters long';
                          } else {
                            _passwordError = null;
                          }
                        });
                      },
                    ),
                    if (_passwordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 12),
                        child: Text(
                          _passwordError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Confirm Password
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: customInputDecoration(
                        'Confirm Password',
                        Icons.lock_outline,
                      ).copyWith(
                        filled: true,
                        fillColor: const Color(0xFF0A0F2C),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.grey,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {
                        setState(() {
                          if (value.isEmpty) {
                            _confirmPasswordError =
                                'Please confirm your password';
                          } else if (value != _passwordController.text) {
                            _confirmPasswordError = 'Passwords do not match';
                          } else {
                            _confirmPasswordError = null;
                          }
                        });
                      },
                    ),
                    if (_confirmPasswordError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5, left: 12),
                        child: Text(
                          _confirmPasswordError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                /// Remember Me
                Row(
                  children: [
                    Checkbox(
                      value: _isRememberMe,
                      onChanged: (val) => setState(() => _isRememberMe = val!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: Colors.deepPurple, // theme color
                      checkColor: Colors.white,
                    ),
                    const Text(
                      "Remember me",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// OR divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey.shade400),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or continue with',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey.shade400),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// Google Sign-In Styled Like Input
                GestureDetector(
                  onTap: () => signInWithGoogle(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/google.svg',
                          height: 24,
                          width: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                /// Bottom Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            fontFamily: 'Roboto',
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSignup() async {
    setState(() {
      _nameError = _nameController.text.trim().isEmpty
          ? 'Please enter your full name'
          : null;
      _emailError = _emailController.text.trim().isEmpty
          ? 'Please enter your email'
          : !RegExp(
              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ).hasMatch(_emailController.text.trim())
              ? 'Please enter a valid email address'
              : null;
      _passwordError = _passwordController.text.trim().isEmpty
          ? 'Please enter a password'
          : _passwordController.text.trim().length < 6
              ? 'Password must be at least 6 characters long'
              : null;
      _confirmPasswordError = _confirmPasswordController.text.trim().isEmpty
          ? 'Please confirm your password'
          : _confirmPasswordController.text.trim() !=
                  _passwordController.text.trim()
              ? 'Passwords do not match'
              : null;
    });

    if (_nameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await userCredential.user?.updateDisplayName(
          _nameController.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user?.uid)
            .set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Sign-up successful!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            elevation: 6,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignInScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            elevation: 6,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
