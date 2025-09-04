import 'package:app/signInScreen.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'checkout_page.dart';
import 'custom_bottom_nav_bar.dart';
import 'package:app/user/ProfilePage.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  late CollectionReference cartRef;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      cartRef = FirebaseFirestore.instance
          .collection('carts')
          .doc(currentUser!.uid)
          .collection('items');
    }
  }

  void updateQuantity(String docId, int newQuantity) {
    if (newQuantity > 0) {
      cartRef.doc(docId).update({'quantity': newQuantity});
    } else {
      cartRef.doc(docId).delete();
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AllProducts()),
      );
    } else if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const WishlistPage()),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F2C),

        appBar: AppBar(
          backgroundColor: const Color(0xFF0A0F2C),
          foregroundColor: Colors.white,
          title: const Text("My Cart", style: TextStyle(color: Colors.white)),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Please log in to view your Cart.",
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
                'My Cart',
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

      body: StreamBuilder<QuerySnapshot>(
        stream: cartRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "Your cart is empty.",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          double total = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final quantity = data['quantity'] ?? 1;
            final price = double.tryParse(data['price'].toString()) ?? 0;
            total += quantity * price;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Slidable(
                        key: ValueKey(doc.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.5,
                          children: [
                            SlidableAction(
                              onPressed: (context) async {
                                await FirebaseFirestore.instance
                                    .collection('wishlist')
                                    .doc(currentUser!.uid)
                                    .collection('items')
                                    .add(data);
                                await cartRef.doc(doc.id).delete();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Moved to Wishlist"),
                                  ),
                                );
                              },
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              icon: Icons.favorite_border,
                            ),
                            SlidableAction(
                              onPressed: (context) async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: Color(0xFF1E293B),
                                    title: const Text(
                                      'Remove Item',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: const Text(
                                      'Do you want to remove this item from the cart?',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Remove',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await cartRef.doc(doc.id).delete();
                                }
                              },
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              icon: Icons.delete_outline,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A0F2C),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: Colors.grey, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    data['image'] != null &&
                                        data['image'].toString().isNotEmpty
                                    ? Image.network(
                                        data['image'],
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Image.asset(
                                                  'assets/placeholder.png',
                                                  width: 70,
                                                  height: 70,
                                                  fit: BoxFit.cover,
                                                ),
                                      )
                                    : Image.asset(
                                        'assets/placeholder.png',
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
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
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "RS ${data['price']}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove),
                                                onPressed: () {
                                                  final currentQty =
                                                      data['quantity'] ?? 1;
                                                  updateQuantity(
                                                    doc.id,
                                                    currentQty - 1,
                                                  );
                                                },
                                              ),
                                              Text(
                                                '${data['quantity'] ?? 1}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () async {
                                                  final currentQty =
                                                      data['quantity'] ?? 1;

                                                  // 🔹 Get available stock from products collection
                                                  final productSnap =
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                            'products',
                                                          )
                                                          .doc(
                                                            data['productId'],
                                                          )
                                                          .get();

                                                  if (productSnap.exists) {
                                                    final availableQty =
                                                        productSnap['quantity'] ??
                                                        0;

                                                    if (currentQty <
                                                        availableQty) {
                                                      updateQuantity(
                                                        doc.id,
                                                        currentQty + 1,
                                                      );
                                                    } else {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Not enough stock available",
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F2C),

                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total price",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "Rs ${total.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
                      onPressed: () async {
                        List<Map<String, dynamic>> outOfStockItems = [];

                        // 🔹 Check all cart items
                        for (var doc in docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          final productSnap = await FirebaseFirestore.instance
                              .collection('products')
                              .doc(data['productId'])
                              .get();

                          if (productSnap.exists) {
                            final availableQty = productSnap['quantity'] ?? 0;

                            if (availableQty == 0) {
                              outOfStockItems.add({
                                "id": doc.id,
                                "title": data['title'] ?? 'Unknown Product',
                              });
                            }
                          }
                        }

                        if (outOfStockItems.isNotEmpty) {
                          // 🚫 Show dialog with out-of-stock items + remove option
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: const Color(0xFF1E293B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                title: const Text(
                                  "Out of Stock",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "These products are out of stock:",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    const SizedBox(height: 10),
                                    ...outOfStockItems.map(
                                      (item) => Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "• ${item['title']}",
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                              ),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              // remove from cart
                                              await cartRef
                                                  .doc(item['id'])
                                                  .delete();
                                              Navigator.pop(
                                                context,
                                              ); // close dialog
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "${item['title']} removed from cart",
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              "Remove",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text(
                                      "Close",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          return; // 🚫 Stop checkout
                        }

                        // ✅ Proceed to Checkout
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CheckoutPage(items: docs, total: total),
                          ),
                        );
                      },
                      child: Text(
                        "Checkout",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
