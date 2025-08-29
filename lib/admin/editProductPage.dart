import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProductPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> productData;

  const EditProductPage({
    Key? key,
    required this.docId,
    required this.productData,
  }) : super(key: key);

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final picker = ImagePicker();

  late TextEditingController titleController;
  late TextEditingController brandController;
  late TextEditingController desController;
  late TextEditingController priceController;
  late TextEditingController pointController;

  List<String> descriptionPoints = [];
  String? thumbnailFilePath;
  List<String> imagePaths = [];

  List<String> selectedCategories = [];
  final List<String> availableCategories = [
    "Gaming",
    "Business",
    "Education",
    "Accessories",
  ];

  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()?['role'] == 'admin') {
      _isAdmin = true;

      // Initialize controllers with product data
      titleController =
          TextEditingController(text: widget.productData['title']);
      brandController =
          TextEditingController(text: widget.productData['brand']);
      desController =
          TextEditingController(text: widget.productData['description']);
      priceController = TextEditingController(
          text: widget.productData['price'].toString());
      pointController = TextEditingController();

      descriptionPoints =
          List<String>.from(widget.productData['description_points'] ?? []);
      thumbnailFilePath = widget.productData['image'];
      imagePaths = List<String>.from(widget.productData['images'] ?? []);
      selectedCategories =
          List<String>.from(widget.productData['categories'] ?? []);
    } else {
      Navigator.pop(context);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> pickThumbnail() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        thumbnailFilePath = "assets/images/${image.name}";
      });
    }
  }

  Future<void> getImages() async {
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      for (var img in images) {
        imagePaths.add("assets/images/${img.name}");
      }
      setState(() {});
    }
  }

  Future<void> updateProduct() async {
    if (titleController.text.isEmpty ||
        brandController.text.isEmpty ||
        desController.text.isEmpty ||
        priceController.text.isEmpty ||
        thumbnailFilePath == null ||
        imagePaths.isEmpty ||
        descriptionPoints.isEmpty ||
        selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields, add images, points & category"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.docId)
          .update({
        'title': titleController.text.trim(),
        'brand': brandController.text.trim(),
        'description': desController.text.trim(),
        'description_points': descriptionPoints,
        'price': double.tryParse(priceController.text) ?? 0,
        'image': thumbnailFilePath,
        'images': imagePaths,
        'categories': selectedCategories,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product updated successfully ✔"),
          backgroundColor: Colors.black,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAdmin) {
      return const SizedBox();
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
    child: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Edit Product',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back), // 🔙 Back button
        onPressed: () {
          Navigator.pop(context); // Go back to previous screen
        },
      ),
    ),
  ),
),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: const Color(0xFF1B1F36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                const Text(
                  "Thumbnail Image",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: pickThumbnail,
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text("Select Thumbnail",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (thumbnailFilePath != null)
                  _buildFilePreview(thumbnailFilePath!, isThumb: true),

                const SizedBox(height: 24),

                // Gallery
                buildImagePicker("Gallery Images", getImages),
                if (imagePaths.isNotEmpty)
                  Column(
                    children: imagePaths.map((path) {
                      return _buildFilePreview(path);
                    }).toList(),
                  ),

                const SizedBox(height: 16),

                // Categories
                buildCategorySelector(),

                const SizedBox(height: 24),
                buildInputField("Title", titleController, Icons.title),
                buildInputField("Brand", brandController, Icons.branding_watermark),
                buildInputField("Description", desController, Icons.description, maxLines: 3),
                buildInputField("Price", priceController, Icons.attach_money,
                    keyboardType: TextInputType.number),

                // Feature points
                Row(
                  children: [
                    Expanded(
                      child: buildInputField(
                          "Add Feature Point", pointController, Icons.add),
                    ),
                    IconButton(
                      onPressed: () {
                        if (pointController.text.trim().isNotEmpty) {
                          setState(() {
                            descriptionPoints.add(pointController.text.trim());
                            pointController.clear();
                          });
                        }
                      },
                      icon: const Icon(Icons.add_circle,
                          color: Colors.deepPurple),
                    )
                  ],
                ),
                if (descriptionPoints.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: descriptionPoints.map((point) {
                      return Chip(
                        label: Text(point),
                        backgroundColor: Colors.deepPurple,
                        labelStyle: const TextStyle(color: Colors.white),
                        onDeleted: () {
                          setState(() {
                            descriptionPoints.remove(point);
                          });
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: updateProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Update Product",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildImagePicker(String label, Function() onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.photo_library, color: Colors.white),
          label:
              const Text("Select Images", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Categories",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: availableCategories.map((category) {
            final isSelected = selectedCategories.contains(category);
            return ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    selectedCategories.remove(category);
                  } else {
                    selectedCategories.add(category);
                  }
                });
              },
              icon: const Icon(Icons.category, color: Colors.white),
              label: Text(
                category,
                style:
                    TextStyle(color: isSelected ? Colors.black : Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSelected ? Colors.white : Colors.deepPurple,
                foregroundColor:
                    isSelected ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (selectedCategories.isNotEmpty)
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: selectedCategories.map((category) {
              return Chip(
                label: Text(
                  category,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.deepPurple,
                deleteIcon:
                    const Icon(Icons.remove_circle, color: Colors.redAccent),
                onDeleted: () {
                  setState(() {
                    selectedCategories.remove(category);
                  });
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget buildInputField(String label, TextEditingController controller,
      IconData icon,
      {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
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
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePreview(String path, {bool isThumb = false}) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              isThumb ? "Thumbnail: $path" : "Selected Image: $path",
              style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                if (isThumb) {
                  thumbnailFilePath = null;
                } else {
                  imagePaths.remove(path);
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
