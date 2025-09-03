import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static Future<String> getOrCreateConversation() async {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;
    final convRef = FirebaseFirestore.instance.collection('conversations');

    final existing = await convRef.where('userId', isEqualTo: uid).limit(1).get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    } else {
      final doc = await convRef.add({
        'userId': uid,
        'userName': user.displayName ?? user.email ?? 'Unknown User',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastUpdated': FieldValue.serverTimestamp(),
        'unreadForAdmin': 0, 
        'unreadForUser': 0,  
      });
      return doc.id;
    }
  }

  static Future<void> sendMessage(
    String convId,
    String text, {
    String? senderId,
    String? senderName,
    bool isFromAdmin = false,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': senderId ?? user!.uid,
      'senderName': senderName ??
          user?.displayName ??
          user?.email ??
          'User',
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    final convDoc = FirebaseFirestore.instance.collection('conversations').doc(convId);

    await convDoc.update({
      'lastMessage': text,
      'lastUpdated': FieldValue.serverTimestamp(),
      isFromAdmin ? 'unreadForUser' : 'unreadForAdmin': FieldValue.increment(1),
    });
  }

  static Future<void> markAsRead(String convId, {bool forAdmin = false}) async {
    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(convId)
        .update({
      forAdmin ? 'unreadForAdmin' : 'unreadForUser': 0,
    });
  }

  static Stream<QuerySnapshot> messagesStream(String convId) {
    return FirebaseFirestore.instance
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
