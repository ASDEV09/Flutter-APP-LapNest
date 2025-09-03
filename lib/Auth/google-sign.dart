import 'package:app/admin/adminScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../user/AllProducts.dart';

Future<void> signInWithGoogle(BuildContext context) async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) return; 

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    final user = userCredential.user;
    if (user != null) {
      print('Signed in as: ${user.displayName}, Email: ${user.email}');

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      final docSnapshot = await userDocRef.get();

      String role = "user";

      if (!docSnapshot.exists) {
        await userDocRef.set({
          'userName': user.displayName ?? '',
          'email': user.email ?? '',
          'role': 'user',
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      } else {
        final data = docSnapshot.data() as Map<String, dynamic>;
        role = data['role'] ?? 'user';

        await userDocRef.update({
          'lastSignIn': FieldValue.serverTimestamp(),
        });
      }

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdminPanelScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AllProducts()),
        );
      }
    }
  } catch (e) {
    print("Error during Google Sign-In: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Google Sign-In failed",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
