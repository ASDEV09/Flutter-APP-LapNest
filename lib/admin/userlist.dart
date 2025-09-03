import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_drawer.dart';
import 'edit_user_page.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final ValueNotifier<int> hoveredIndex = ValueNotifier(-1);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: Colors.white,
                width: 1.0,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                int userCount = 0;
                if (snapshot.hasData) {
                  userCount = snapshot.data!.docs.length;
                }
                return Text(
                  'Users Count $userCount',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
      ),

      drawer: AppDrawer(user: currentUser),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No users found", style: TextStyle(color: Colors.white70)),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;

              Uint8List? imgBytes;
              if (data['profileImageBase64'] != null) {
                try {
                  imgBytes = base64Decode(data['profileImageBase64']);
                } catch (_) {}
              }

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => hoveredIndex.value = index,
                onExit: (_) => hoveredIndex.value = -1,
                child: ValueListenableBuilder<int>(
                  valueListenable: hoveredIndex,
                  builder: (context, value, child) {
                    final isHovered = value == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      transform: isHovered
                          ? (Matrix4.identity()
                            ..translate(0, -6, 0)
                            ..scale(1.02))
                          : Matrix4.identity(),
                      decoration: BoxDecoration(
                        gradient: isHovered
                            ? const LinearGradient(
                                colors: [Color(0xFF2B3560), Color(0xFF1E2440)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [Color(0xFF1E2440), Color(0xFF1A1F35)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: isHovered
                                ? Colors.deepPurple.withOpacity(0.6)
                                : Colors.black.withOpacity(0.4),
                            blurRadius: isHovered ? 16 : 8,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      margin: const EdgeInsets.only(bottom: 14),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        leading: imgBytes != null
                            ? CircleAvatar(radius: 26, backgroundImage: MemoryImage(imgBytes))
                            : const CircleAvatar(radius: 26, child: Icon(Icons.person, size: 28)),
                        title: Text(
                          data['name'] ?? 'No Name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          data['email'] ?? 'No Email',
                          style: TextStyle(color: Colors.grey[300], fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.deepPurple),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditUserPage(userId: doc.id, userData: data),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => _buildDeleteDialog(context),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(doc.id)
                                      .delete();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Delete confirmation dialog
  Widget _buildDeleteDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2440),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Delete User",
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      content: const Text(
        "Are you sure you want to delete this user?",
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel", style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
