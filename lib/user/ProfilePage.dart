import 'dart:convert';
import 'dart:typed_data';
import 'package:app/passwordrestpro.dart';
import 'package:app/signInScreen.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/user/EditProfilePage.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/faqsListPage.dart';
import 'package:app/user/my_orders.dart';
import 'package:app/user/policy.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_bottom_nav_bar.dart';
import 'package:share_plus/share_plus.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  bool isLoading = true;
  int _selectedIndex = 3;

  String name = '';
  String contact = '';
  String? base64Image;
  Uint8List? imageBytes;

  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        name = data['userName'] ?? user!.displayName ?? '';
        contact = data['contactNumber'] ?? '';
        base64Image = data['profileImageBase64'];
        if (base64Image != null && base64Image!.isNotEmpty) {
          imageBytes = base64Decode(base64Image!);
        }
      } else {
        name = user!.displayName ?? '';
        contact = '';
        base64Image = null;
        imageBytes = null;
      }
    } catch (e) {
      name = user!.displayName ?? '';
      contact = '';
      base64Image = null;
      imageBytes = null;
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllProducts()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WishlistPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartPage()),
        );
        break;
      case 3:
        // already here
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F2C),

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              border: Border(
                bottom: BorderSide(color: Colors.white, width: 1.0),
              ),
            ),
            child: Builder(
              // Use Builder to get correct context for Scaffold
              builder: (context) => AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  'My Profile',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "You are not logged in. Please login.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                child: const Text("Login", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFF0A0F2C),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: Colors.white, width: 1.0)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false, // 🔹 disable back button
            title: Text(
              'Profile',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 32),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: imageBytes != null
                  ? MemoryImage(imageBytes!)
                  : null,
              backgroundColor: Colors.grey.shade300,
              child: imageBytes == null
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              contact,
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6), // spacing
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.edit, color: Colors.grey),
              title: const Text(
                'Edit Profile',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfilePage(),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.grey),
              title: const Text(
                'My Orders',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersPage()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.grey),
              title: const Text(
                'Privacy Policy',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PoliciesPage()),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.help_center, color: Colors.grey),
              title: const Text(
                'Help Center',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpCenterPage(),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.help_center, color: Colors.grey),
              title: const Text(
                'Forgot the password?',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PasswordReset(),
                  ),
                );
              },
            ),
          ),
          Container(
            // thoda gap
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.person_add, color: Colors.grey),
              title: const Text(
                'Invite Friends',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                try {
                  await Share.share(
                    "Hey! 👋 Check out this amazing shopping app: https://play.google.com/store/apps/details?id=com.yourapp",
                    subject: "Download this Shopping App",
                  );
                } catch (e) {
                  print("❌ Share error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error while sharing: $e")),
                  );
                }
              },
            ),
          ),
        
                Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
             onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            ),
          ),
        ],
      ),
    );
  }
}
