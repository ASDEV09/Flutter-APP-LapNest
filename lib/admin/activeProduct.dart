import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'editProductPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_drawer.dart';
import 'package:google_fonts/google_fonts.dart';

class Activeproduct extends StatefulWidget {
  const Activeproduct({super.key});

  @override
  State<Activeproduct> createState() => _ActiveproductState();
}

class _ActiveproductState extends State<Activeproduct> {
  String? userRole;
  bool loadingRole = true;
  User? currentUser;

  String searchQuery = ""; // 🔍 Search text

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    if (currentUser == null) {
      setState(() {
        userRole = null;
        loadingRole = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
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

  Future<void> _deleteProduct(String productId) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .delete();
  }

  Future<void> _toggleProductStatus(
    String productId,
    bool currentStatus,
  ) async {
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({"isActive": !currentStatus});
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
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "You do not have permission to access this page.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
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
                'Active Products',
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

      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by title, brand, or price",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('isActive', isEqualTo: true) // ✅ Sirf active products
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No active products found",
                        style: TextStyle(color: Colors.white)),
                  );
                }

                // 🔎 Client-side filtering
                final products = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data['title'] ?? '').toString().toLowerCase();
                  final brand = (data['brand'] ?? '').toString().toLowerCase();
                  final price = (data['price'] ?? '').toString().toLowerCase();

                  return title.contains(searchQuery) ||
                      brand.contains(searchQuery) ||
                      price.contains(searchQuery);
                }).toList();

                if (products.isEmpty) {
                  return const Center(
                    child: Text("No matching products found",
                        style: TextStyle(color: Colors.white)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final doc = products[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final imageUrl = data['image'] ?? '';
                    final isActive = data['isActive'] ?? true;

                    return Slidable(
                      key: ValueKey(doc.id),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProductPage(
                                    docId: doc.id,
                                    productData: data,
                                  ),
                                ),
                              );

                              if (result == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Product updated successfully"),
                                  ),
                                );
                                setState(() {});
                              }
                            },
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'Edit',
                            flex: 2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          SlidableAction(
                            onPressed: (_) async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E293B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    "Delete Product",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    "Are you sure you want to delete this product?",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text("Cancel",
                                          style: TextStyle(color: Colors.grey)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 12),
                                      ),
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text("Delete",
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _deleteProduct(doc.id);
                              }
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                            flex: 2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ],
                      ),

                      child: Card(
                        color: const Color(0xFF1E293B),
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error,
                                                stackTrace) =>
                                            const Icon(
                                                Icons.image_not_supported,
                                                size: 80,
                                                color: Colors.grey),
                                      ),
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      size: 80, color: Colors.grey),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Brand: ${data['brand'] ?? ''}",
                                      style: const TextStyle(
                                          fontSize: 16, color: Colors.white),
                                    ),
                                    Text(
                                      "Price: Rs. ${data['price'] ?? '0'}",
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () => _toggleProductStatus(
                                          doc.id, isActive),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green[200]
                                              : Colors.red[200],
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.green[900]
                                                : Colors.red[900],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
        ],
      ),
    );
  }
}
