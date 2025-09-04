import 'dart:convert';
import 'dart:typed_data';
import 'package:app/signInScreen.dart';
import 'package:app/user/FullScreenGallery.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:intl/intl.dart';
import 'app_bar.dart';
import 'custom_bottom_nav_bar.dart';
import 'AllProducts.dart';
import 'wishlistPage.dart';
import 'cart_page.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? name;

  const ProductDetailPage({Key? key, required this.data, this.name})
    : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool isInWishlist = false;
  List<Map<String, dynamic>> reviews = [];
  bool loadingReviews = true;

  @override
  void initState() {
    super.initState();
    checkIfInWishlist();
    fetchReviews();
  }

  Future<void> checkIfInWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wishlistSnapshot = await FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user.uid)
        .collection('items')
        .where('productId', isEqualTo: widget.data['docId'])
        .get();

    if (wishlistSnapshot.docs.isNotEmpty) {
      setState(() {
        isInWishlist = true;
      });
    }
  }

  Future<void> fetchReviews() async {
    final productTitle = widget.data['title'] ?? '';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('productTitle', isEqualTo: productTitle)
          .get();

      final fetchedReviews = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      setState(() {
        reviews = fetchedReviews;
        loadingReviews = false;
      });
    } catch (e) {
      setState(() {
        loadingReviews = false;
      });
    }
  }

  Future<void> toggleWishlist(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
      return;
    }

    final wishlistRef = FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user.uid)
        .collection('items');

    final querySnapshot = await wishlistRef
        .where('productId', isEqualTo: widget.data['docId'])
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      await wishlistRef.doc(querySnapshot.docs.first.id).delete();
      setState(() {
        isInWishlist = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from wishlist')));
    } else {
      await wishlistRef.add({
        'productId': widget.data['docId'],
        'title': widget.data['title'],
        'price': widget.data['price'],
        'description': widget.data['description'],
        'image': widget.data['image'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        isInWishlist = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to wishlist')));
    }
  }

  Future<void> addToCart(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('carts')
          .doc(user.uid)
          .collection('items')
          .where('productId', isEqualTo: widget.data['docId'])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This product is already in your cart.'),
          ),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('carts')
            .doc(user.uid)
            .collection('items')
            .add({
              'productId': widget.data['docId'],
              'title': widget.data['title'],
              'price': widget.data['price'],
              'description': widget.data['description'],
              'image': widget.data['image'],
              'timestamp': FieldValue.serverTimestamp(),
              'quantity': 1,
            });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to cart')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error adding to cart')));
    }
  }

  @override
  Widget build(BuildContext context) {
    var isActiveRaw = widget.data['isActive'];
    double getAverageRating() {
      if (reviews.isEmpty) return 0.0;
      double total = 0;
      for (var r in reviews) {
        total += (r['rating'] ?? 0).toDouble();
      }
      return total / reviews.length;
    }

    bool isActive = false;
    if (isActiveRaw is bool) {
      isActive = isActiveRaw;
    } else if (isActiveRaw is String) {
      isActive = isActiveRaw.toLowerCase() == 'true';
    } else if (isActiveRaw is int) {
      isActive = isActiveRaw == 1;
    }

    if (!isActive) {
      return Scaffold(
        appBar: const CustomAppBar(title: ""),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No product available',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllProducts(),
                    ),
                  );
                },
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      );
    }

    List<String> base64Images = [];

    if (widget.data['images'] != null && widget.data['images'] is List) {
      base64Images = List<String>.from(widget.data['images']);
    } else if (widget.data['image'] != null) {
      base64Images = [widget.data['image']];
    }

    List<String> descriptionPoints = [];
    if (widget.data['description_points'] != null &&
        widget.data['description_points'] is List) {
      descriptionPoints = List<String>.from(widget.data['description_points']);
    }

    String brandName = 'N/A';
    if (widget.data.containsKey('brand')) {
      final brandField = widget.data['brand'];
      if (brandField is String) {
        brandName = brandField;
      } else if (brandField is Map<String, dynamic> &&
          brandField.containsKey('name')) {
        brandName = brandField['name'].toString();
      }
    }

    return Scaffold(
      backgroundColor: Color(0xFF0A0F2C),
      appBar: const CustomAppBar(title: ""),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          print("Tapped index: $index");
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
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CartPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cs.CarouselSlider(
              items: base64Images.map((imgUrl) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenGallery(
                          imageUrls: base64Images,
                          initialIndex: base64Images.indexOf(imgUrl),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 100),
                    ),
                  ),
                );
              }).toList(),
              options: cs.CarouselOptions(
                height: 250,
                enlargeCenterPage: false,
                viewportFraction: 1.0,
                enableInfiniteScroll: base64Images.length > 1,
                autoPlay: base64Images.length > 1,
              ),
            ),

            const SizedBox(height: 20),
            Text(
              widget.data['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.data['description'] ?? 'No Description',
              style: const TextStyle(
                fontSize: 16,
                color: Color.fromARGB(255, 228, 228, 228),
              ),
            ),
            const SizedBox(height: 5),

            Text(
              "Brand: $brandName",
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 228, 228, 228),
              ),
            ),

            const SizedBox(height: 5),
            Text(
              "Price: Rs ${widget.data['price'] ?? 'N/A'}",
              style: TextStyle(
                fontSize: 18,
                color: Color.fromARGB(255, 228, 228, 228),
              ),
            ),

            if (descriptionPoints.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Product Description:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...descriptionPoints.map(
                    (point) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "• ",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 228, 228, 228),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromARGB(255, 228, 228, 228),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            if (!loadingReviews && reviews.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Rating:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Row(
                    children: [
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < getAverageRating().round()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${getAverageRating().toStringAsFixed(1)} (${reviews.length} reviews)",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 10),

            const Text(
              "Reviews",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            loadingReviews
                ? const Center(child: CircularProgressIndicator())
                : reviews.isEmpty
                ? const Center(
                    child: Text(
                      "No reviews yet",
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Column(
                    children: reviews.map((review) {
                      int rating = review['rating'] ?? 0;
                      String comment = review['review'] ?? '';
                      String userName = review['userName'] ?? 'Anonymous';
                      final ts = review['timestamp'] as Timestamp?;
                      String dateString = ts != null
                          ? DateFormat(
                              'dd MMM yyyy',
                            ).format(ts.toDate().toLocal())
                          : '';

                      return Card(
                        color: const Color(0xFF121633),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(review['userId'])
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                        );
                                      }

                                      if (!snapshot.hasData ||
                                          !snapshot.data!.exists) {
                                        return const CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                        );
                                      }

                                      final userData =
                                          snapshot.data!.data()
                                              as Map<String, dynamic>;
                                      final base64Img =
                                          userData['profileImageBase64'];

                                      if (base64Img != null &&
                                          base64Img.isNotEmpty) {
                                        try {
                                          return CircleAvatar(
                                            radius: 20,
                                            backgroundImage: MemoryImage(
                                              base64Decode(base64Img),
                                            ),
                                          );
                                        } catch (_) {
                                          return const CircleAvatar(
                                            radius: 20,
                                            backgroundColor: Colors.grey,
                                            child: Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                          );
                                        }
                                      } else {
                                        return const CircleAvatar(
                                          radius: 20,
                                          backgroundColor: Colors.grey,
                                          child: Icon(
                                            Icons.person,
                                            color: Colors.white,
                                          ),
                                        );
                                      }
                                    },
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          userName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          dateString,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < rating
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),
                              Text(
                                comment,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color.fromARGB(255, 230, 230, 230),
                                ),
                              ),

                              const SizedBox(height: 10),
                              if (review['images'] != null &&
                                  review['images'] is List)
                                SizedBox(
                                  height: 90,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        (review['images'] as List).length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      String base64Img =
                                          review['images'][index];
                                      Uint8List? imgBytes;
                                      try {
                                        imgBytes = base64Decode(base64Img);
                                      } catch (_) {
                                        imgBytes = null;
                                      }
                                      return GestureDetector(
                                        onTap: () {
                                          List<Uint8List> galleryImages =
                                              (review['images']
                                                      as List<dynamic>)
                                                  .map((b64) {
                                                    try {
                                                      return base64Decode(b64);
                                                    } catch (_) {
                                                      return Uint8List(0);
                                                    }
                                                  })
                                                  .where(
                                                    (img) => img.isNotEmpty,
                                                  )
                                                  .toList();

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  FullScreenGalleryBase64(
                                                    images: galleryImages,
                                                    initialIndex: index,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: imgBytes != null
                                              ? Image.memory(
                                                  imgBytes,
                                                  width: 90,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  width: 90,
                                                  height: 90,
                                                  color: Colors.grey,
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Material(
        color: const Color(0xFF0A0F2C),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.data['quantity'] == 0
                          ? Colors
                                .red // 🔴 Wishlist ke liye red background
                          : Colors
                                .deepPurple, // 🟣 Cart ke liye purple background
                      foregroundColor: Colors.white, // ✅ text aur icon white
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      if (widget.data['quantity'] == 0) {
                        // ✅ Quantity zero → wishlist add
                        toggleWishlist(context);
                      } else {
                        // ✅ Quantity available → cart add
                        addToCart(context);
                      }
                    },
                    icon: Icon(
                      widget.data['quantity'] == 0
                          ? Icons.favorite_border
                          : Icons.add_shopping_cart,
                      color: Colors.white,
                    ),
                    label: Text(
                      widget.data['quantity'] == 0
                          ? 'Add to Wishlist'
                          : 'Add to Cart',
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // ❤️ Heart icon sirf tab show hoga jab quantity > 0 ho
                if (widget.data['quantity'] != 0)
                  IconButton(
                    icon: Icon(
                      isInWishlist ? Icons.favorite : Icons.favorite_border,
                      color: isInWishlist ? Colors.red : Colors.white,
                      size: 32,
                    ),
                    onPressed: () => toggleWishlist(context),
                  ),

                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 32),
                  onPressed: () {
                    String title = widget.data['title'] ?? 'Product';
                    String description = widget.data['description'] ?? '';
                    String price = widget.data['price']?.toString() ?? 'N/A';
                    String imageUrl = widget.data['image'] ?? '';

                    String shareText =
                        "🛍️ $title\n\n"
                        "$description\n\n"
                        "💰 Price: Rs $price\n"
                        "${imageUrl.isNotEmpty ? '📷 $imageUrl' : ''}";

                    Share.share(shareText, subject: title);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
