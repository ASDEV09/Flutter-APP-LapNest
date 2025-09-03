import 'package:app/signInScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String? convId;
  final _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isButtonEnabled = false;

  List<Map<String, dynamic>> tempBotMessages = [];

  final List<Map<String, String>> defaultQA = [
    {
      'question': 'Order status kaise check karun?',
      'answer':
          'Aapka order status aapke account ke "My Orders" section me mil jayega.',
    },
    {
      'question': 'Delivery ka time kitna hota hai?',
      'answer': 'Delivery usually 3-5 business days me hoti hai.',
    },
    {
      'question': 'Return policy kya hai?',
      'answer':
          'Aap 7 din ke andar product return kar sakte ho agar wo unused ho.',
    },
  ];

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      ChatService.getOrCreateConversation().then((id) {
        setState(() => convId = id);
      });
    }

    _controller.addListener(() {
      setState(() {
        _isButtonEnabled = _controller.text.trim().isNotEmpty;
      });
    });
  }

  void _send([String? textOverride]) {
    final text = (textOverride ?? _controller.text.trim());
    if (text.isEmpty || convId == null) return;
    ChatService.sendMessage(convId!, text);
    if (textOverride == null) _controller.clear();
  }

  void _showBotAnswer(String answer) {
    setState(() {
      tempBotMessages.add({
        'senderName': 'Support Bot',
        'text': answer,
        'createdAt': DateTime.now(),
      });
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 🔒 If user not logged in, show login button
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F2C),
        body: Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            child: const Text(
              'Login to Chat',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      );
    }

    // ⏳ If conversation ID not yet loaded
    if (convId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F2C),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: Colors.white, // border color
                width: 1.0, // border thickness
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Chat Support',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          // Default Questions
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1B1F36),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: defaultQA.map((qa) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _showBotAnswer(qa['answer']!),
                      child: Text(
                        qa['question']!,
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ChatService.messagesStream(convId!),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                final docs = snap.data!.docs
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();
                final allMessages = [...docs, ...tempBotMessages];

                // ⬇️ Auto-scroll when new messages come
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollToBottom(),
                );

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: allMessages.length,
                  itemBuilder: (ctx, i) {
                    final d = allMessages[i];
                    final isMe =
                        d['senderId'] == FirebaseAuth.instance.currentUser?.uid;

                    String time = '';
                    if (d['createdAt'] != null) {
                      final dateTime = d['createdAt'] is DateTime
                          ? d['createdAt']
                          : (d['createdAt'] as Timestamp?)?.toDate();
                      if (dateTime != null) {
                        time = DateFormat('hh:mm a').format(dateTime);
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.deepPurple : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 0),
                              bottomRight: Radius.circular(isMe ? 0 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    d['senderName'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              Text(
                                d['text'] ?? '',
                                style: GoogleFonts.poppins(
                                  color: isMe ? Colors.white : Colors.black,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: isMe ? Colors.white70 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              top: 12,
              bottom: 16,
            ),
            color: const Color(0xFF0A0F2C),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.poppins(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1B1F36),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _isButtonEnabled
                      ? Colors.deepPurple
                      : Color(0xFF1E293B), // ✅
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 22),
                    onPressed: _isButtonEnabled
                        ? _send
                        : null, // ✅ disable if empty
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
