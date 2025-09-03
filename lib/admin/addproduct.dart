import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:app/admin/app_drawer.dart';
import 'package:google_fonts/google_fonts.dart';
class Addproduct extends StatefulWidget {
  const Addproduct({Key? key}) : super(key: key);

  @override
  _AddproductState createState() => _AddproductState();
}

class _AddproductState extends State<Addproduct> {
  final CollectionReference products = FirebaseFirestore.instance.collection('products');
  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  final TextEditingController titleController = TextEditingController();
  final TextEditingController desController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController pointController = TextEditingController();

  List<String> descriptionPoints = [];
  final ImagePicker picker = ImagePicker();
  List<String> selectedCategories = [];
  final List<String> availableCategories = [
    "Gaming",
    "Business",
    "Education",
    "Accessories",
  ];

  String? thumbnailFilePath;
  List<String> imagePaths = [];

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
    if (user == null) {
      setState(() {
        userRole = null;
        loadingRole = false;
      });
      return;
    }

    try {
      final doc = await users.doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        setState(() {
          userRole = data?['role'];
          loadingRole = false;
        });
      } else {
        setState(() {
          userRole = null;
          loadingRole = false;
        });
      }
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

  Future<void> addProduct() async {
    if (titleController.text.isEmpty ||
        desController.text.isEmpty ||
        priceController.text.isEmpty ||
        brandController.text.isEmpty ||
        thumbnailFilePath == null ||
        imagePaths.isEmpty ||
        descriptionPoints.isEmpty ||
        selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all fields, add images, points & category",
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      await products.add({
        'title': titleController.text,
        'brand': brandController.text,
        'description': desController.text,
        'description_points': descriptionPoints,
        'price': double.parse(priceController.text),
        'image': thumbnailFilePath,
        'images': imagePaths,
        'categories': selectedCategories,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      titleController.clear();
      desController.clear();
      priceController.clear();
      brandController.clear();
      pointController.clear();
      thumbnailFilePath = null;
      imagePaths.clear();
      descriptionPoints.clear();
      selectedCategories.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Product added successfully ✔"),
          backgroundColor: Colors.black,
        ),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to add product: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userRole != 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Access Denied"),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            "You do not have permission to access this page.",
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      );
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
          child: Builder(
            builder: (context) => AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Add Product',
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
      drawer: AppDrawer(user: user),
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
                const Text(
                  "Thumbnail Image",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: pickThumbnail,
                  icon: const Icon(Icons.upload, color: Colors.white),
                  label: const Text("Select Thumbnail", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
                const SizedBox(height: 8),
                if (thumbnailFilePath != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "Selected Thumbnail: $thumbnailFilePath",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueAccent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              thumbnailFilePath = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                buildImagePicker("Gallery Images", getImages),
                if (imagePaths.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: imagePaths.map((path) {
                      return _buildFilePreview(path);
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                buildCategorySelector(),
                const SizedBox(height: 24),
                buildInputField("Title", titleController, Icons.title),
                buildInputField("Brand", brandController, Icons.branding_watermark),
                buildInputField("Description", desController, Icons.description, maxLines: 3),
                buildInputField("Price", priceController, Icons.attach_money, keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: buildInputField("Add Feature Point", pointController, Icons.add),
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
                      icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                    ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: addProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Add Product", style: TextStyle(fontWeight: FontWeight.bold
                    , color: Colors.white, )),
                  ),
                ),
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
          label: const Text("Select Images", style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
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
              style: TextStyle(color: isSelected ? Colors.black : Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelected ? Colors.white : Colors.deepPurple,
              foregroundColor: isSelected ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
              deleteIcon: const Icon(Icons.remove_circle, color: Colors.redAccent),
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


  Widget buildInputField(String label, TextEditingController controller, IconData icon,
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

  Widget _buildFilePreview(String path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              "Selected Image: $path",
              style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
            onPressed: () {
              setState(() {
                imagePaths.remove(path);
              });
            },
          ),
        ],
      ),
    );
  }
}
