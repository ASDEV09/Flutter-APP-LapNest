import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  _CustomerServicePageState createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
  final _firestore = FirebaseFirestore.instance;
  final _controller = TextEditingController();
  final String currentUser = 'user1'; // Simulate a user ID; replace with actual auth if needed

  void sendMessage(String text) {
    if (text.isNotEmpty) {
      _firestore.collection('messages').add({
        'text': text,
        'sender': currentUser,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _controller.clear();
      // Simulate bot response
      Future.delayed(const Duration(seconds: 1), () {
        _firestore.collection('messages').add({
          'text': getBotResponse(text),
          'sender': 'bot',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    }
  }

  String getBotResponse(String message) {
    message = message.toLowerCase();
    if (message.contains('order') || message.contains('payment')) {
      return 'Of course. Can you tell me the problem you are having? so I can help solve it 😊';
    } else if (message.contains('hello') || message.contains('hi')) {
      return 'Hello! How can I assist you today? 😊';
    } else if (message.contains('refund')) {
      return 'Sure, for refunds, please provide your order ID and reason.';
    } else {
      return "I'm sorry, I didn't understand that. Can you explain your issue? (e.g., order, payment, refund)";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {}),
        title: Text(
          "Customer Service",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!.docs.reversed;
                List<Widget> messageWidgets = [];
                for (var message in messages) {
                  final data = message.data() as Map<String, dynamic>;
                  final messageText = data['text'];
                  final messageSender = data['sender'];
                  final messageWidget = MessageBubble(
                    text: messageText,
                    isMe: messageSender == currentUser,
                  );
                  messageWidgets.add(messageWidget);
                }
                return ListView(
                  reverse: true,
                  children: messageWidgets,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.emoji_emotions), onPressed: () {}),
                IconButton(icon: const Icon(Icons.mic), onPressed: () {}),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const MessageBubble({super.key, required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Material(
            borderRadius: BorderRadius.circular(20),
            color: isMe ? Colors.black : Colors.grey[300],
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontFamily: GoogleFonts.inter().fontFamily,
                ),
              ),
            ),
          ),
          Text(
            '09:41', // Static for simplicity; update with real timestamp if needed
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}