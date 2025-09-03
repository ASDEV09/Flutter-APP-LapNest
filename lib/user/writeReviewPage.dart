import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WriteReviewPage extends StatefulWidget {
  final String orderId;
  final String userName;
  final String productId;
  final String productTitle;
  final String productImageBase64; 

  const WriteReviewPage({
    Key? key,
    required this.orderId,
    required this.userName,
    required this.productId,
    required this.productTitle,
    required this.productImageBase64,  
  }) : super(key: key);

  @override
  _WriteReviewPageState createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<String> _imageBase64List = [];

  String get ratingDescription {
    switch (_rating) {
      case 5:
        return "Excellent";
      case 4:
        return "Good";
      case 3:
        return "Average";
      case 2:
        return "Poor";
      case 1:
        return "Very Poor";
      default:
        return "";
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.length + _imageBase64List.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can only upload up to 3 images.")),
      );
      return;
    }

    for (var file in pickedFiles) {
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      setState(() {
        _imageBase64List.add(base64Str);
      });
    }
    }

  void _removeImage(int index) {
    setState(() {
      _imageBase64List.removeAt(index);
    });
  }

Future<void> _submitReview() async {
  if (_rating == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a rating")),
    );
    return;
  }
  if (_reviewController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please write a review")),
    );
    return;
  }

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You must be logged in to submit a review")),
    );
    return;
  }

  try {
    DocumentSnapshot deliveredOrderDoc = await FirebaseFirestore.instance
        .collection('deliveredOrders')
        .doc(widget.orderId)
        .get();

    String userNameFromOrder = "Anonymous";
    if (deliveredOrderDoc.exists) {
      var data = deliveredOrderDoc.data() as Map<String, dynamic>;
      if (data.containsKey('name')) {
        userNameFromOrder = data['name'] ?? "Anonymous";
      }
    }

    await FirebaseFirestore.instance.collection('reviews').add({
      'orderId': widget.orderId,
      'userId': currentUser.uid,
      'userName': userNameFromOrder, 
      'productId': widget.productId,
      'productTitle': widget.productTitle,
      'productImage': widget.productImageBase64,
      'rating': _rating,
      'review': _reviewController.text,
      'images': _imageBase64List,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Review submitted successfully")),
    );

    Navigator.pop(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to submit review: $e")),
    );
  }
}


  Widget buildStar(int starIndex) {
    return IconButton(
      icon: Icon(
        _rating >= starIndex ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: 32,
      ),
      onPressed: () {
        setState(() {
          _rating = starIndex;
        });
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
      backgroundColor: Color(0xFF0A0F2C),

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
                'Write a Review',
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

    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            "Rate the product:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => buildStar(index + 1)),
          ),
          if (_rating > 0)
            Center(
              child: Text(
                ratingDescription,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 20),
          TextField(
            controller: _reviewController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Write your review",
              labelStyle: const TextStyle(color: Colors.white),
              hintText: "Describe your experience",
              hintStyle: const TextStyle(color: Colors.white),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.white),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Upload up to 3 images:",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Wrap(
            spacing: 8,
            children: [
              ..._imageBase64List.asMap().entries.map((entry) {
                final idx = entry.key;
                final base64Str = entry.value;
                Uint8List bytes = base64Decode(base64Str);
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(top: 8),
                      child: Image.memory(bytes, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () => _removeImage(idx),
                        child: Container(
                          color: Colors.deepPurple,
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                );
              }),
              if (_imageBase64List.length < 3)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(top: 8),
                    color: Color(0xFF1E293B),
                    child: const Icon(Icons.add_a_photo,
                        size: 36, color: Colors.grey),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _submitReview,
            child: const Text("Submit Review"),
          ),
        ],
      ),
    ),
  );
}

}
