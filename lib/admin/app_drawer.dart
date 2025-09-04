import 'dart:convert';
import 'dart:typed_data';
import 'package:app/admin/editprofile.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/admin/activeProduct.dart';
import 'package:app/admin/adminScreen.dart';
import 'package:app/admin/allproducts.dart';
import 'package:app/admin/list_offers_screen.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/admin/Adminfaqs.dart';
import 'package:app/admin/addoffer.dart';
import 'package:app/admin/admin_conversations.dart';
import 'package:app/admin/addproduct.dart';
import 'package:app/admin/deactiveProduct.dart';
import 'package:app/admin/admin_orders_page.dart';
import 'package:app/admin/userlist.dart';
import 'package:app/SignInScreen.dart';
import 'addBrand.dart';
class AppDrawer extends StatefulWidget {
  final User? user;

  const AppDrawer({Key? key, required this.user}) : super(key: key);

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: const Color(0xFF0A0F2C),
      ),
      child: Drawer(
        backgroundColor: const Color(0xFF0A0F2C),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.user?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const DrawerHeader(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const DrawerHeader(
                    child: Center(
                      child: Text(
                        'User not found',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                Uint8List? imageBytes;
                if (userData['profileImageBase64'] != null &&
                    (userData['profileImageBase64'] as String).isNotEmpty) {
                  try {
                    imageBytes = base64Decode(userData['profileImageBase64']);
                  } catch (_) {
                    imageBytes = null;
                  }
                }

                return DrawerHeader(
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey[800],
                            backgroundImage:
                                imageBytes != null ? MemoryImage(imageBytes) : null,
                            child: imageBytes == null
                                ? const Icon(Icons.person, size: 40, color: Colors.white)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditProfile(
                                      userId: widget.user!.uid,
                                      userData: userData,
                                    ),
                                  ),
                                );
                              },
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.edit, size: 12, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userData['name'] ??
                                  widget.user?.displayName ??
                                  'Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              userData['email'] ?? widget.user?.email ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            _buildListTile(
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => _navigate(context, const AdminPanelScreen()),
            ),

_buildExpansionTile(
  title: 'Products',
  icon: Icons.shopping_bag,
  children: [
    _buildMenuItem(
      icon: Icons.list,
      title: 'All Products',
      onTap: () => _navigate(context, const ProductsList()),
    ),
    _buildMenuItem(
      icon: Icons.add,
      title: 'Add Product',
      onTap: () => _navigate(context, const Addproduct()),
    ),
    _buildMenuItem(
      icon: Icons.check_circle,
      title: 'Active Products',
      onTap: () => _navigate(context, const Activeproduct()),
    ),
    _buildMenuItem(
      icon: Icons.cancel,
      title: 'Deactive Products',
      onTap: () => _navigate(context, const DeactivatedProductsList()),
    ),
    _buildMenuItem(
      icon: Icons.branding_watermark, // ✅ brand ka icon
      title: 'Add Brand',
      onTap: () => _navigate(context, const AddBrand()),
    ),
  ],
),
            _buildListTile(
              icon: Icons.question_answer,
              title: 'Add FAQs',
              onTap: () => _navigate(context, const AdminFaqPage()),
            ),

            _buildListTile(
              icon: Icons.chat,
              title: 'Chat Support',
              onTap: () => _navigate(context, const AdminConversations()),
            ),

            _buildListTile(
              icon: Icons.shopping_cart,
              title: 'Orders',
              onTap: () => _navigate(context, const AdminOrdersPage()),
            ),

            _buildListTile(
              icon: Icons.people,
              title: 'User List',
              onTap: () => _navigate(context, const UserList()),
            ),

            _buildExpansionTile(
              title: 'Offers',
              icon: Icons.local_offer,
              children: [
                _buildMenuItem(
                  icon: Icons.list,
                  title: 'Offer List',
                  onTap: () => _navigate(context, const ListOffersScreen()),
                ),
                _buildMenuItem(
                  icon: Icons.add,
                  title: 'Add Offer',
                  onTap: () => _navigate(context, const AddOffer()),
                ),
              ],
            ),

            _buildListTile(
              icon: Icons.store,
              title: 'Visit App',
              onTap: () => _navigate(context, const AllProducts()),
            ),

            const Divider(color: Colors.white24),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF0A0F2C),
      collapsedBackgroundColor: const Color(0xFF0A0F2C),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: [
        Column(children: children),
      ],
      onExpansionChanged: (expanded) {
        setState(() {});
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
