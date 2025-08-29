import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_drawer.dart';

class ListOffersScreen extends StatefulWidget {
  const ListOffersScreen({Key? key}) : super(key: key);

  @override
  State<ListOffersScreen> createState() => _ListOffersScreenState();
}

class _ListOffersScreenState extends State<ListOffersScreen> {
  final CollectionReference offers = FirebaseFirestore.instance.collection('offers');
  final ImagePicker picker = ImagePicker();
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
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
            title: Text(
              'Offers List',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
      ),

      // Drawer add kiya
      drawer: AppDrawer(
        user: currentUser,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: offers.orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.deepPurple));
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No offers found.",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                Uint8List? imgBytes;
                if (data['imageBase64'] != null) {
                  try {
                    imgBytes = base64Decode(data['imageBase64']);
                  } catch (_) {}
                }

                return Card(
                  color: const Color(0xFF1E2440),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: imgBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              imgBytes,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image, color: Colors.white, size: 40),
                    title: Text(data['title'] ?? '', style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      "${data['description'] ?? ''}\nDiscount: ${data['discount']}%",
                      style: TextStyle(color: Colors.grey.shade300),
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.deepPurple),
                          onPressed: () {
                            _showEditDialog(context, doc.id, data);
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
                              await offers.doc(doc.id).delete();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Edit Dialog with enhanced input fields and floating labels
  void _showEditDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final editTitle = TextEditingController(text: data['title']);
    final editDesc = TextEditingController(text: data['description']);
    final editDiscount = TextEditingController(text: data['discount']);
    String? editImage = data['imageBase64'];
    Uint8List? editImageBytes;

    if (editImage != null) {
      try {
        editImageBytes = base64Decode(editImage);
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickNewImage() async {
              final XFile? image = await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                final Uint8List byteImage = await image.readAsBytes();
                final String base64img = base64Encode(byteImage);
                setStateDialog(() {
                  editImage = base64img;
                  editImageBytes = byteImage;
                });
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E2440),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text("Edit Offer", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInteractiveTextField(editTitle, "Title"),
                    const SizedBox(height: 16),
                    _buildInteractiveTextField(editDesc, "Description", maxLines: 3),
                    const SizedBox(height: 16),
                    _buildInteractiveTextField(editDiscount, "Discount"),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: pickNewImage,
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.deepPurple),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF1E2440),
                        ),
                        child: editImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(editImageBytes!, fit: BoxFit.cover),
                              )
                            : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: pickNewImage,
                      icon: const Icon(Icons.image),
                      label: const Text("Change Image", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await offers.doc(docId).update({
                      'title': editTitle.text,
                      'description': editDesc.text,
                      'discount': editDiscount.text,
                      'imageBase64': editImage,
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Interactive TextField with focus effects and floating labels
  Widget _buildInteractiveTextField(TextEditingController controller, String label, {int? maxLines}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        filled: true,
        fillColor: const Color(0xFF1E2440),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 1),
        ),
      ),
    );
  }

  // Delete Confirmation Dialog
  Widget _buildDeleteDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2440),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text("Delete Offer", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      content: const Text("Are you sure you want to delete this offer?", style: TextStyle(color: Colors.white)),
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
