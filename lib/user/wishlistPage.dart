import 'package:app/signInScreen.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:app/user/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'custom_bottom_nav_bar.dart';
import 'product_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  late CollectionReference wishlistRef;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      wishlistRef = FirebaseFirestore.instance
          .collection('wishlist')
          .doc(currentUser!.uid)
          .collection('items');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F2C),

        appBar: AppBar(
          automaticallyImplyLeading: true, // ✅ back button hata diya
          backgroundColor: const Color(0xFF0A0F2C),
          foregroundColor: Colors.white,
          title: const Text(
            "My Wishlist",
            style: TextStyle(color: Colors.white),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(
              color: Colors.grey, // ✅ grey border
              height: 1,
              thickness: 1,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Please log in to view your wishlist.",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Keep scaffold context for snackbars
    final scaffoldContext = context;

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
            // Use Builder to get correct context for Scaffold
            builder: (context) => AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'My Wishlist',
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

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllProducts()),
              );
              break;
            case 1:
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartPage()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
              break;
          }
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: wishlistRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Your wishlist is empty.",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final imageUrl = data['image'] ?? '';
              // if (base64Image != null && base64Image.isNotEmpty) {
              //   try {
              //     imageBytes = base64Decode(base64Image);
              //   } catch (e) {
              //     print("Image decode error: $e");
              //   }
              // }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Slidable(
                  key: ValueKey(doc.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    extentRatio: 0.5,
                    children: [
                      SlidableAction(
                        onPressed: (_) async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text('Please log in to use cart'),
                              ),
                            );
                            return;
                          }
                          final cartRef = FirebaseFirestore.instance
                              .collection('carts')
                              .doc(user.uid)
                              .collection('items');

                          final existing = await cartRef
                              .where(
                                'productId',
                                isEqualTo: data['productId'] ?? data['docId'],
                              )
                              .get();

                          if (existing.docs.isNotEmpty) {
                            await wishlistRef.doc(doc.id).delete();
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Already in cart, removed from wishlist',
                                ),
                              ),
                            );
                            return;
                          }

                          await cartRef.add({
                            'productId': data['productId'] ?? data['docId'],
                            'title': data['title'],
                            'price': data['price'],
                            'description': data['description'],
                            'image': data['image'],
                            'timestamp': FieldValue.serverTimestamp(),
                            'quantity': 1,
                          });

                          await wishlistRef.doc(doc.id).delete();

                          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                            const SnackBar(content: Text('Moved to cart')),
                          );
                        },
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        icon: Icons.shopping_cart,
                      ),
                      SlidableAction(
                        onPressed: (_) async {
                          final confirm = await showDialog<bool>(
                            context: scaffoldContext,
                            builder: (context) => AlertDialog(
                              backgroundColor: isDark
                                  ? Color(0xFF1E293B)
                                  : Color(0xFF1E293B),
                              title: Text(
                                "Remove Item",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              content: Text(
                                "Remove this item from wishlist?",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(
                                    "Cancel",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(
                                    "Remove",
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await wishlistRef.doc(doc.id).delete();
                            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                              const SnackBar(
                                content: Text("Item removed from wishlist"),
                              ),
                            );
                          }
                        },
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey, width: 0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailPage(data: data, name: null),
                              ),
                            );
                          },
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 70, // 🔥 Pehle 50 tha, ab 100 kar diya
                                  height: 70, // 🔥 Image badi ho gayi
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.broken_image,
                                        color: Colors.red,
                                        size: 80, // 🔥 Error icon bhi bada
                                      ),
                                )
                              : const Icon(
                                  Icons.image,
                                  color: Colors.black54,
                                  size: 80,
                                ), // 🔥 placeholder bada
                        ),

                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                data['description'] ?? '',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.grey,
                                ),
                                maxLines:
                                    2, // number of lines to show before truncating
                                overflow: TextOverflow
                                    .ellipsis, // adds "..." at the end
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Rs ${data['price'] ?? 'N/A'}",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
    );
  }
}
