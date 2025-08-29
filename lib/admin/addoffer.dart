import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'list_offers_screen.dart'; // Import ListOffersScreen
import 'app_drawer.dart';

class AddOffer extends StatefulWidget {
  const AddOffer({Key? key}) : super(key: key);

  @override
  State<AddOffer> createState() => _AddOfferScreenState();
}

class _AddOfferScreenState extends State<AddOffer> {
  final CollectionReference offers = FirebaseFirestore.instance.collection('offers');
  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  final TextEditingController titleController = TextEditingController();
  final TextEditingController desController = TextEditingController();
  final TextEditingController discountController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  String? thumbnailImage;
  String? userRole;
  bool loadingRole = true;
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    if (user == null) return;
    try {
      final doc = await users.doc(user!.uid).get();
      final data = doc.data() as Map<String, dynamic>?;
      setState(() {
        userRole = data?['role'];
        loadingRole = false;
      });
    } catch (e) {
      setState(() {
        userRole = null;
        loadingRole = false;
      });
    }
  }

  Future<void> pickThumbnail() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List byteImage = await image.readAsBytes();
      final String base64img = base64Encode(byteImage);
      setState(() {
        thumbnailImage = base64img;
      });
    }
  }

  Future<void> addOffer() async {
    if (titleController.text.isEmpty ||
        desController.text.isEmpty ||
        discountController.text.isEmpty ||
        thumbnailImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields & add an image"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await offers.add({
        'title': titleController.text,
        'description': desController.text,
        'discount': discountController.text,
        'imageBase64': thumbnailImage,
        'createdAt': FieldValue.serverTimestamp(),
      });

      titleController.clear();
      desController.clear();
      discountController.clear();
      thumbnailImage = null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Offer added successfully ✔"),
          backgroundColor: Colors.deepPurple,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ListOffersScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  InputDecoration darkInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: const Color(0xFF1E2440),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  Widget buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? thumbnailBytes;
    if (thumbnailImage != null) {
      try {
        thumbnailBytes = base64Decode(thumbnailImage!);
      } catch (_) {}
    }
    final currentUser = FirebaseAuth.instance.currentUser;

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
                'Add Offer',
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

      body: loadingRole
          ? const Center(child: CircularProgressIndicator())
          : userRole != 'admin'
              ? const Center(
                  child: Text(
                    "Access Denied",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView(
                    children: [
                      buildLabel("Offer Title"),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: darkInputDecoration("Enter offer title", Icons.title),
                      ),
                      const SizedBox(height: 16),

                      buildLabel("Description"),
                      TextField(
                        controller: desController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: darkInputDecoration("Enter description", Icons.description),
                      ),
                      const SizedBox(height: 16),

                      buildLabel("Discount (%)"),
                      TextField(
                        controller: discountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: darkInputDecoration("Enter discount", Icons.percent),
                      ),
                      const SizedBox(height: 20),

                      buildLabel("Offer Image"),
                      Center(
                        child: InkWell(
                          onTap: pickThumbnail,
                          child: Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2440),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.deepPurple),
                            ),
                            child: thumbnailBytes != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      thumbnailBytes,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.white),
                                      SizedBox(height: 8),
                                      Text("Upload Image", style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: addOffer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          "Add Offer",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    desController.dispose();
    discountController.dispose();
    super.dispose();
  }
}
