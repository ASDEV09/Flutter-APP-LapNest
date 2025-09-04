import 'dart:convert';
import 'dart:typed_data';
import 'package:app/signInScreen.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/user/FullScreenGallery.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'app_bar.dart';
import 'custom_bottom_nav_bar.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailPageById extends StatefulWidget {
  final String productId;

  const ProductDetailPageById({Key? key, required this.productId})
    : super(key: key);

  @override
  State<ProductDetailPageById> createState() => _ProductDetailPageByIdState();
}

class _ProductDetailPageByIdState extends State<ProductDetailPageById> {
  Map<String, dynamic>? productData;
  bool loadingProduct = true;
  bool loadingReviews = true;
  List<Map<String, dynamic>> reviews = [];
  bool isInWishlist = false;

  @override
  void initState() {
    super.initState();
    fetchProductData();
  }

  Future<void> fetchProductData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['isActive'] == true) {
          productData = data;
          setState(() {
            loadingProduct = false;
          });
          await checkIfInWishlist();
          await fetchReviews();
        } else {
          setState(() {
            loadingProduct = false;
            productData = null;
          });
        }
      } else {
        setState(() {
          loadingProduct = false;
          productData = null;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product not found')));
      }
    } catch (e) {
      setState(() {
        loadingProduct = false;
        productData = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading product: $e')));
    }
  }

  Future<void> checkIfInWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || productData == null) return;

    final wishlistSnapshot = await FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user.uid)
        .collection('items')
        .where('productId', isEqualTo: widget.productId)
        .get();

    setState(() {
      isInWishlist = wishlistSnapshot.docs.isNotEmpty;
    });
  }

  Future<void> fetchReviews() async {
    if (productData == null) {
      setState(() {
        loadingReviews = false;
      });
      return;
    }

    final productTitle = productData!['title'] ?? '';

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
    if (user == null || productData == null) {
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
        .where('productId', isEqualTo: widget.productId)
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
        'productId': widget.productId,
        'title': productData!['title'],
        'price': productData!['price'],
        'description': productData!['description'],
        'image': productData!['image'],
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
    if (user == null || productData == null) {
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
          .where('productId', isEqualTo: widget.productId)
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
              'productId': widget.productId,
              'title': productData!['title'],
              'price': productData!['price'],
              'description': productData!['description'],
              'image': productData!['image'],
              'timestamp': FieldValue.serverTimestamp(),
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
    if (loadingProduct) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (productData == null) {
      return Scaffold(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AllProducts()),
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
    if (productData!['images'] != null && productData!['images'] is List) {
      base64Images = List<String>.from(productData!['images']);
    } else if (productData!['image'] != null) {
      base64Images = [productData!['image']];
    }
    String brandName = 'N/A';
    if (productData!.containsKey('brand')) {
      final brandField = productData!['brand'];
      if (brandField is String) {
        brandName = brandField;
      } else if (brandField is Map<String, dynamic> &&
          brandField.containsKey('name')) {
        brandName = brandField['name'].toString();
      }
    }

    List<String> descriptionPoints = [];
    if (productData!['description_points'] != null &&
        productData!['description_points'] is List) {
      descriptionPoints = List<String>.from(productData!['description_points']);
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
        padding: const EdgeInsets.all(16),
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
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 100,
                        color: Colors.white,
                      ),
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
              productData!['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              productData!['description'] ?? 'No Description',
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
              "Price: Rs ${productData!['price'] ?? 'N/A'}",
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
                          ? ts.toDate().toLocal().toString().split(' ')[0]
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
                // ✅ agar quantity == 0 hai to "Add to Wishlist"
                if ((productData!['quantity'] ?? 0) == 0)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // 🔴 red background
                        foregroundColor: Colors.white, // 🤍 white text
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => toggleWishlist(context),
                      icon: const Icon(Icons.favorite, color: Colors.white),
                      label: const Text('Add to Wishlist'),
                    ),
                  )
                else
                  // ✅ warna "Add to Cart" dikhaye
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => addToCart(context),
                      icon: const Icon(
                        Icons.add_shopping_cart,
                        color: Colors.white,
                      ),
                      label: const Text('Add to Cart'),
                    ),
                  ),

                const SizedBox(width: 16),

                // ✅ Heart (wishlist icon) sirf tab dikhaye jab quantity > 0 ho
                if ((productData!['quantity'] ?? 0) > 0)
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
                    String title = productData!['title'] ?? 'Product';
                    String description = productData!['description'] ?? '';
                    String price = productData!['price']?.toString() ?? 'N/A';
                    String imageUrl = productData!['image'] ?? '';

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
