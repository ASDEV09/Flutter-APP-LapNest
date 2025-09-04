import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_drawer.dart';

class AddBrand extends StatefulWidget {
  const AddBrand({Key? key}) : super(key: key);

  @override
  State<AddBrand> createState() => _AddBrandState();
}

class _AddBrandState extends State<AddBrand> {
  final CollectionReference brands =
      FirebaseFirestore.instance.collection('brands');
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');

  final TextEditingController brandController = TextEditingController();

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

  Future<void> addBrand() async {
    if (brandController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a brand name"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await brands.add({
        'name': brandController.text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      brandController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Brand added successfully ✔"),
          backgroundColor: Colors.deepPurple,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  Future<void> editBrand(String id, String oldName) async {
    final TextEditingController editController =
        TextEditingController(text: oldName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2440),
        title: const Text("Edit Brand", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter new brand name",
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.deepPurple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (editController.text.isNotEmpty) {
                await brands.doc(id).update({'name': editController.text});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Brand updated successfully ✔"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteBrand(String id) async {
    await brands.doc(id).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Brand deleted successfully ❌"),
        backgroundColor: Colors.red,
      ),
    );
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
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Add Brand',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildLabel("Brand Name"),
                      TextField(
                        controller: brandController,
                        style: const TextStyle(color: Colors.white),
                        decoration: darkInputDecoration(
                            "Enter brand name", Icons.branding_watermark),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: addBrand,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Add Brand",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "All Brands",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: brands.orderBy('createdAt').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No brands added yet",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              );
                            }

                            return ListView(
                              children: snapshot.data!.docs.map((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;
                                final name = data['name'] ?? 'Unnamed';
                                return Card(
                                  color: const Color(0xFF1E2440),
                                  child: ListTile(
                                    title: Text(
                                      name,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              editBrand(doc.id, name),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () =>
                                              deleteBrand(doc.id),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  @override
  void dispose() {
    brandController.dispose();
    super.dispose();
  }
}





