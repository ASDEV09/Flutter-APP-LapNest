import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditUserPage extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const EditUserPage({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController contactController;
  late TextEditingController addressController;

  DateTime? dateOfBirth;
  String? gender;
  String? role;

  String? base64Image;
  Uint8List? imageBytes;

  final List<String> genderOptions = ["Male", "Female", "Other"];
  final List<String> roleOptions = ["admin", "user"];

  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.userData['name'] ?? '');
    emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    contactController =
        TextEditingController(text: widget.userData['contactNumber'] ?? '');
    addressController =
        TextEditingController(text: widget.userData['address'] ?? '');

    gender = genderOptions.contains(widget.userData['gender'])
        ? widget.userData['gender']
        : null;
    role = roleOptions.contains(widget.userData['role'])
        ? widget.userData['role']
        : null;

    base64Image = widget.userData['profileImageBase64'];
    if (base64Image != null && base64Image!.isNotEmpty) {
      imageBytes = base64Decode(base64Image!);
    }

    if (widget.userData['dateOfBirth'] != null) {
      dateOfBirth = (widget.userData['dateOfBirth'] as Timestamp).toDate();
    }

    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    addressController.dispose();
    _animController.dispose();
    super.dispose();
  }

 InputDecoration inputDecoration(String hint, IconData icon, {Color iconColor = Colors.white, Color hintColor = Colors.white}) {
  return InputDecoration(
    prefixIcon: Icon(icon, color: iconColor),   
    hintText: hint,
    hintStyle: TextStyle(color: hintColor),   
    filled: true,
    fillColor: Colors.white.withOpacity(0.08),
    contentPadding:
        const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}



  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        imageBytes = bytes;
        base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({
      'name': nameController.text.trim(),
      'email': emailController.text.trim(),
      'contactNumber': contactController.text.trim(),
      'address': addressController.text.trim(),
      'gender': gender,
      'role': role,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'profileImageBase64': base64Image ?? '',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("✅ Profile updated successfully",
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Edit User",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ScaleTransition(
        scale: _scaleAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Hero(
                  tag: "profile_${widget.userId}",
                  child: GestureDetector(
                    onTap: pickImage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.7),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundImage:
                            imageBytes != null ? MemoryImage(imageBytes!) : null,
                        backgroundColor: Colors.deepPurple.withOpacity(0.2),
                        child: imageBytes == null
                            ? const Icon(Icons.person,
                                size: 70, color: Colors.white70)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap to change picture',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: nameController,
                  decoration: inputDecoration('Full Name', Icons.person_outline),
                  style: const TextStyle(color: Colors.white),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Name required' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: emailController,
                  decoration: inputDecoration('Email', Icons.email_outlined),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email required';
                    if (!RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$').hasMatch(val)) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: contactController,
                  decoration:
                      inputDecoration('Contact Number', Icons.phone_outlined),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20),

                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateOfBirth ?? DateTime(2000),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Colors.deepPurple,
                              onPrimary: Colors.white,
                              surface: Color(0xFF0A0F2C),
                              onSurface: Colors.white,
                            ),
                            dialogBackgroundColor: Color(0xFF0A0F2C),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => dateOfBirth = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: inputDecoration('Date of Birth', Icons.cake_outlined),
                    child: Text(
                      dateOfBirth != null
                          ? "${dateOfBirth!.day}/${dateOfBirth!.month}/${dateOfBirth!.year}"
                          : "Select Date",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: inputDecoration('Gender', Icons.wc_outlined, ),
                  dropdownColor: const Color(0xFF1E2440),
                  style: const TextStyle(color: Colors.white),
                  value: gender,
                  items: genderOptions
                      .map((g) => DropdownMenuItem(
                          value: g,
                          child:
                              Text(g, style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (val) => setState(() => gender = val),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration:
                      inputDecoration('Role', Icons.admin_panel_settings_outlined),
                  dropdownColor: const Color(0xFF1E2440),
                  style: const TextStyle(color: Colors.white),
                  value: role,
                  items: roleOptions
                      .map((r) => DropdownMenuItem(
                          value: r,
                          child:
                              Text(r, style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (val) => setState(() => role = val),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: addressController,
                  decoration: inputDecoration('Address', Icons.home_outlined),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.deepPurple],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: const Text(
                          "💾 Save Changes",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
