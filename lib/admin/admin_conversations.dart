import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'admin_chat.dart';
import 'app_drawer.dart';
import '../services/chat_service.dart';

class AdminConversations extends StatelessWidget {
  const AdminConversations({super.key});

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return doc.exists && doc['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return FutureBuilder<bool>(
      future: _isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == false) {
          return const Scaffold(
            body: Center(child: Text("Access Denied — Admins Only")),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0A0F2C),
         appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: Colors.white, width: 1.0)),
          ),
          child: Builder(
            builder: (context) => AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Conversations',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.menu),  
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
        ),
      ),
          drawer: AppDrawer(user: currentUser),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('conversations')
                      .orderBy('lastUpdated', descending: true)
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snap.data!.docs;
                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final d = docs[index];
                        final data = d.data() as Map<String, dynamic>;

                        final unreadCount = data['unreadForAdmin'] ?? 0;
                        final lastMessage = data['lastMessage'] ?? '';
                        final userName =
                            data['userName'] ?? data['userEmail'] ?? 'Unknown';

                        return Card(
                          color: const Color(0xFF1B1F36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 4,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                           leading: FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
  builder: (context, userSnap) {
    if (!userSnap.hasData) {
      return const CircleAvatar(
        radius: 24,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      );
    }

    final userData = userSnap.data!.data() as Map<String, dynamic>?;

    if (userData != null && userData['profileImageBase64'] != null) {
      try {
        final imageBytes = base64Decode(userData['profileImageBase64']);
        return CircleAvatar(
          radius: 24,
          backgroundImage: MemoryImage(imageBytes),
        );
      } catch (e) {
        return CircleAvatar(
          radius: 24,
          backgroundColor: Colors.purple.shade100,
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : "?",
            style: const TextStyle(
              color: Colors.purple,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: Colors.purple.shade100,
      child: Text(
        userName.isNotEmpty ? userName[0].toUpperCase() : "?",
        style: const TextStyle(
          color: Colors.purple,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  },
),

                            title: Text(
                              userName,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage,
                              style: GoogleFonts.poppins(
                                color: Colors.grey[300],
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _formatTime(data['lastUpdated']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                if (unreadCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.purple,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () async {
                              await ChatService.markAsRead(d.id, forAdmin: true);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminChat(
                                    convId: d.id,
                                    userName: userName,
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
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return "";
    final dt = ts.toDate();
    final now = DateTime.now();

    if (dt.day == now.day &&
        dt.month == now.month &&
        dt.year == now.year) {
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else {
      return "${dt.day}/${dt.month}";
    }
  }
}
