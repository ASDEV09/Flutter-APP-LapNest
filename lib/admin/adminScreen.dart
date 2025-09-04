import 'package:app/admin/Adminfaqs.dart';
import 'package:app/admin/activeProduct.dart';
import 'package:app/admin/addoffer.dart';
import 'package:app/admin/addproduct.dart';
import 'package:app/admin/admin_conversations.dart';
import 'package:app/admin/admin_orders_page.dart';
import 'package:app/admin/allproducts.dart';
import 'package:app/admin/deactiveproduct.dart';
import 'package:app/admin/userlist.dart';
import 'package:app/user/AllProducts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app/signInScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/admin/addBrand.dart'; 
import 'app_drawer.dart';

class AdminPanelScreen extends StatefulWidget {
  final String? adminName;
  const AdminPanelScreen({Key? key, this.adminName}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  bool _isAdmin = false;
  String? adminName;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    adminName = widget.adminName ?? 'Admin';
    _fetchAdminName();
  }

  Future<void> _checkAdminRole() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists && doc['role'] == 'admin') {
        setState(() {
          _isAdmin = true;
        });
      }
    } catch (e) {
      debugPrint("Role check error: $e");
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchAdminName() async {
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          adminName = doc['name'] ?? 'Admin';
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const SignInScreen();
    }
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F2C),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F2C),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 50, color: Colors.red),
              const SizedBox(height: 10),
              Text(
                "Access Denied",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                child: const Text(
                  "Go to Login",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildAdminPanelUI();
  }

  Widget _buildAdminPanelUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      drawer: AppDrawer(user: user),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${adminName ?? 'Admin'}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hope you are well',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.3,
                children: [
                  _buildCard(
                    'All Products',
                    Icons.assignment,
                    Colors.deepPurple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProductsList()),
                      );
                    },
                  ),
                  _buildCard('Add Product', Icons.add_box, Colors.cyan, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const Addproduct()),
                    );
                  }),
                  _buildCard(
                    'Active Products',
                    Icons.check_circle,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Activeproduct(),
                        ),
                      );
                    },
                  ),
                  _buildCard('Deactive Products', Icons.cancel, Colors.red, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DeactivatedProductsList(),
                      ),
                    );
                  }),
                  _buildCard('Orders', Icons.shop, Colors.orange, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminOrdersPage(),
                      ),
                    );
                  }),
                  _buildCard('Chat', Icons.chat, Colors.blue, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminConversations(),
                      ),
                    );
                  }),
                  _buildCard('Users', Icons.people, Colors.purple, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserList()),
                    );
                  }),
                  _buildCard('FAQs', Icons.question_answer, Colors.teal, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminFaqPage()),
                    );
                  }),
                  _buildCard(
                    'Offer',
                    Icons.add,
                    const Color.fromARGB(255, 205, 221, 65),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddOffer()),
                      );
                    },
                  ),
                  _buildCard(
                    'Add Brand', // ✅ New Card
                    Icons.branding_watermark,
                    Colors.indigo,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddBrand()),
                      );
                    },
                  ),
                  _buildCard('My App', Icons.home, Colors.pink, () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AllProducts()),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.3), const Color(0xFF1B1F36)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
