import 'dart:convert';
import 'dart:typed_data';
import 'package:app/signInScreen.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_bottom_nav_bar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final user = FirebaseAuth.instance.currentUser;

  bool isLoading = true;
  int _selectedIndex = 3;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController contactController;
  late TextEditingController addressController;

  String? base64Image;
  Uint8List? imageBytes;

  DateTime? dateOfBirth;
  String? gender;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    contactController = TextEditingController();
    addressController = TextEditingController();
    fetchUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    addressController.dispose();
    super.dispose();
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
        nameController.text = data['userName'] ?? user!.displayName ?? '';
        contactController.text = data['contactNumber'] ?? '';
        addressController.text = data['address'] ?? '';
        gender = data['gender'];
        base64Image = data['profileImageBase64'];
        if (base64Image != null && base64Image!.isNotEmpty) {
          imageBytes = base64Decode(base64Image!);
        }
        if (data['dateOfBirth'] != null) {
          Timestamp ts = data['dateOfBirth'];
          dateOfBirth = ts.toDate();
        }
      } else {
        nameController.text = user!.displayName ?? '';
        contactController.text = '';
        addressController.text = '';
        gender = null;
        base64Image = null;
        imageBytes = null;
        dateOfBirth = null;
      }
    } catch (e) {
      nameController.text = user!.displayName ?? '';
      contactController.text = '';
      addressController.text = '';
      gender = null;
      base64Image = null;
      imageBytes = null;
      dateOfBirth = null;
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        imageBytes = bytes;
        base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> saveUserData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'userName': nameController.text.trim(),
        'contactNumber': contactController.text.trim(),
        'address': addressController.text.trim(),
        'gender': gender ?? '',
        'profileImageBase64': base64Image ?? '',
        'dateOfBirth': dateOfBirth != null
            ? Timestamp.fromDate(dateOfBirth!)
            : null,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error saving profile')));
    } finally {
      setState(() {
        isLoading = false;
      });
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
        break;
    }
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF0A0F2C),
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            child: const Text('You are not logged in. Please login.'),
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
          child: Builder(
            builder: (context) => AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Edit Profile',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: imageBytes != null
                      ? MemoryImage(imageBytes!)
                      : null,
                  backgroundColor: Colors.grey.shade300,
                  child: imageBytes == null
                      ? const Icon(Icons.person, size: 60, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap image to change',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration('Name', Icons.person_outline),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Name required' : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: contactController,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration(
                  'Contact Number',
                  Icons.phone_outlined,
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Contact number required';
                  }
                  if (!RegExp(r'^\+?\d{7,15}$').hasMatch(val.trim())) {
                    return 'Enter valid contact number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              FormField<DateTime>(
                validator: (val) {
                  if (dateOfBirth == null) {
                    return 'Date of Birth required';
                  }
                  return null;
                },
                builder: (field) {
                  return InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dateOfBirth ?? DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          dateOfBirth = picked;
                          field.didChange(picked);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: inputDecoration(
                        'Date of Birth',
                        Icons.cake_outlined,
                      ).copyWith(errorText: field.errorText),
                      child: Text(
                        dateOfBirth != null
                            ? "${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}"
                            : 'Select Date',
                        style: TextStyle(
                          color: dateOfBirth != null
                              ? Colors.white
                              : Colors.grey,
                          fontSize: 16,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF0A0F2C),
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration('', Icons.wc_outlined),
                hint: const Text(
                  'Gender',
                  style: TextStyle(color: Colors.grey),
                ),
                value: gender,
                items: genderOptions
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                          g,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    gender = val;
                  });
                },
                validator: (val) =>
                    val == null || val.isEmpty ? 'Gender required' : null,
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: addressController,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration('Address', Icons.home_outlined),
                maxLines: 3,
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Address required'
                    : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: saveUserData,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignInScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
