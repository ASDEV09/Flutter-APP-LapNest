import 'dart:convert';
import 'dart:typed_data';
import 'package:app/signInScreen.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:app/user/app_bar.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/chat_screen.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product_detail_page.dart';
import 'custom_bottom_nav_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'sort_filter_screen.dart';

class AllProducts extends StatefulWidget {
  const AllProducts({Key? key}) : super(key: key);

  @override
  State<AllProducts> createState() => _AllProductsState();
}

class _AllProductsState extends State<AllProducts> {
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  Set<String> wishlistProductIds = {};
  int _selectedIndex = 0;
  final user = FirebaseAuth.instance.currentUser;

  final TextEditingController _searchController = TextEditingController();
  bool isFilterApplied = false;
  bool isLoading = true;
  String? selectedBrand;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage('assets/images/offer.png'), context);
    });
  }

  Future<void> _loadData() async {
    await Future.wait([fetchProducts(), fetchWishlist()]);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products.where((product) {
          final title = (product['title'] ?? '').toString().toLowerCase();
          final description = (product['description'] ?? '')
              .toString()
              .toLowerCase();
          final brand = (product['brand'] ?? '').toString().toLowerCase();
          return title.contains(query) ||
              description.contains(query) ||
              brand.contains(query);
        }).toList();
      }
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllProducts()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WishlistPage()),
        );
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
  }

  Future<double> _computeAverageRatingByProductId(String productId) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) return 0.0;

    double totalRating = 0.0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc['rating'] ?? 0).toDouble();
    }
    return totalRating / reviewsSnapshot.docs.length;
  }

  Future<void> fetchProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('isActive', isEqualTo: true)
        .get();

    final loaded = snapshot.docs.map((doc) {
      final data = doc.data();
      data['docId'] = doc.id;
      return data;
    }).toList();

    for (final p in loaded) {
      try {
        final productId = (p['docId'] ?? '').toString();
        final avg = await _computeAverageRatingByProductId(productId);
        p['averageRating'] = avg;
      } catch (_) {
        p['averageRating'] = 0.0;
      }
    }

    setState(() {
      products = loaded;
      filteredProducts = loaded;
    });
  }

  Future<void> fetchWishlist() async {
    if (user == null) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user!.uid)
        .collection('items')
        .get();
    setState(() {
      wishlistProductIds = snapshot.docs
          .map((doc) => doc['productId'] as String)
          .toSet();
    });
  }

  Future<void> toggleWishlist(
    String productId,
    Map<String, dynamic> data,
  ) async {
    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
      return;
    }
    final wishlistRef = FirebaseFirestore.instance
        .collection('wishlist')
        .doc(user!.uid)
        .collection('items');

    if (wishlistProductIds.contains(productId)) {
      final snapshot = await wishlistRef
          .where('productId', isEqualTo: productId)
          .get();
      for (var doc in snapshot.docs) {
        await wishlistRef.doc(doc.id).delete();
      }
      setState(() {
        wishlistProductIds.remove(productId);
      });
    } else {
      await wishlistRef.add({
        'productId': productId,
        'title': data['title'],
        'price': data['price'],
        'description': data['description'],
        'image': data['image'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        wishlistProductIds.add(productId);
      });
    }
  }

  Future<void> addToCart(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
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
          .doc(user!.uid)
          .collection('items')
          .where('productId', isEqualTo: data['docId'])
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
            .doc(user!.uid)
            .collection('items')
            .add({
              'productId': data['docId'],
              'title': data['title'],
              'price': data['price'],
              'description': data['description'],
              'image': data['image'],
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

  Future<Map<String, dynamic>> fetchAverageRatingAndCount(
    String productTitle,
  ) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('productTitle', isEqualTo: productTitle)
        .get();

    if (reviewsSnapshot.docs.isEmpty) {
      return {"average": 0.0, "count": 0};
    }

    double totalRating = 0;
    for (var doc in reviewsSnapshot.docs) {
      totalRating += (doc['rating'] ?? 0).toDouble();
    }

    double avgRating = totalRating / reviewsSnapshot.docs.length;
    return {"average": avgRating, "count": reviewsSnapshot.docs.length};
  }

  List<String> getCategoriesFromProducts(List<Map<String, dynamic>> products) {
    final categoriesSet = <String>{};
    for (var product in products) {
      final category = product['category'] ?? product['brand'] ?? '';
      if (category.isNotEmpty) {
        categoriesSet.add(category.toString());
      }
    }
    return categoriesSet.toList();
  }

  double getMinPrice(List<Map<String, dynamic>> products) {
    if (products.isEmpty) return 0;
    return products
        .map((p) => (p['price'] ?? 0) as num)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
  }

  double getMaxPrice(List<Map<String, dynamic>> products) {
    if (products.isEmpty) return 10000;
    return products
        .map((p) => (p['price'] ?? 0) as num)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
  }

  void applyFilters(Map<String, dynamic> filters) {
    final String category = filters['category'] ?? 'All';
    final double minPrice = filters['minPrice'] ?? 0;
    final double maxPrice = filters['maxPrice'] ?? double.infinity;
    final String sort = filters['sort'] ?? '';
    final int rating = filters['rating'] ?? 0;

    List<Map<String, dynamic>> tempList = products.where((product) {
      final price = (product['price'] ?? 0) as num;
      final brand = (product['brand'] ?? '').toString();
      final prodRating = (product['averageRating'] ?? 0) as num;

      final inPrice = price >= minPrice && price <= maxPrice;
      final inCategory = (category == 'All' || brand == category);
      final inRating = (rating == 0) ? true : (prodRating >= rating);

      return inPrice && inCategory && inRating;
    }).toList();

    switch (sort) {
      case "Popular":
        tempList.sort(
          (a, b) => ((b['averageRating'] ?? 0) as num).compareTo(
            (a['averageRating'] ?? 0) as num,
          ),
        );
        break;
      case "Most Recent":
        tempList.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp?;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        break;
      case "Price Low → High":
        tempList.sort((a, b) => (a['price'] ?? 0).compareTo(b['price'] ?? 0));
        break;
      case "Price High → Low":
        tempList.sort((a, b) => (b['price'] ?? 0).compareTo(a['price'] ?? 0));
        break;
    }

    setState(() {
      filteredProducts = tempList;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hideExtraSections =
        _searchController.text.isNotEmpty || isFilterApplied;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Color(0xFF0A0F2C),
          appBar: const CustomAppBar(title: "LapNest"),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,

            child: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen()),
              );
            },
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: _selectedIndex,
            onTap: _onBottomNavTapped,
          ),
          body: SingleChildScrollView(
            child: Container(
              color: Color(0xFF0A0F2C),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by title, description or brand...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune),
                          onPressed: () async {
                            final result =
                                await showModalBottomSheet<
                                  Map<String, dynamic>
                                >(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => SortFilterScreen(
                                    categories: getCategoriesFromProducts(
                                      products,
                                    ),
                                    minPrice: getMinPrice(products),
                                    maxPrice: getMaxPrice(products),
                                  ),
                                );

                            if (result != null) {
                              applyFilters(result);
                              isFilterApplied =
                                  result["filterApplied"] ?? false;
                              setState(() {});
                            }
                          },
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  if (!hideExtraSections) ...[
                    const SpecialOffersWidget(),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8,
                      ),
                      child: GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children:
                            [
                              {
                                'icon': Icons.videogame_asset,
                                'label': 'Gaming',
                              },
                              {'icon': Icons.headset, 'label': 'Accessories'},
                              {'icon': Icons.business, 'label': 'Business'},
                              {'icon': Icons.school, 'label': 'Education'},
                            ].map((c) {
                              return GestureDetector(
                                onTap: () {
                                  final selectedCategory = c['label'] as String;

                                  setState(() {
                                    filteredProducts = products.where((p) {
                                      final categories = (p['categories'] ?? [])
                                          .cast<String>();
                                      return categories.contains(
                                        selectedCategory,
                                      );
                                    }).toList();
                                    isFilterApplied = true;
                                  });
                                },
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Color(0xFF1E293B),
                                      child: Icon(
                                        c['icon'] as IconData,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      c['label'] as String,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],

                  isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(50),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.deepPurple,
                            ),
                          ),
                        )
                      : filteredProducts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No products found.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.78,
                              ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final data = filteredProducts[index];
                            final productId = data['docId'];
                            final isWishlisted = wishlistProductIds.contains(
                              productId,
                            );

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailPage(
                                      data: data,
                                      name: null,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                  top: Radius.circular(12),
                                                ),
                                            child:
                                                (data['image'] != null &&
                                                    data['image']
                                                        .toString()
                                                        .isNotEmpty)
                                                ? Image.network(
                                                    data['image'],
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Image.asset(
                                                          'assets/placeholder.png',
                                                          fit: BoxFit.cover,
                                                        ),
                                                  )
                                                : Image.asset(
                                                    'assets/placeholder.png',
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => toggleWishlist(
                                                productId,
                                                data,
                                              ),
                                              child: Icon(
                                                isWishlisted
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isWishlisted
                                                    ? Colors.red
                                                    : Colors.white,
                                                size: 26,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        data['title'] ?? 'No Title',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: FutureBuilder<Map<String, dynamic>>(
                                        future: fetchAverageRatingAndCount(
                                          data['title'],
                                        ),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const SizedBox(height: 16);
                                          }
                                          double uiAvg =
                                              snapshot.data?['average'] ?? 0;
                                          int totalReviews =
                                              snapshot.data?['count'] ?? 0;
                                          final computed =
                                              (data['averageRating'] ?? 0.0)
                                                  .toDouble();
                                          final avgRating = computed > 0
                                              ? computed
                                              : uiAvg;

                                          return Row(
                                            children: [
                                              RatingBarIndicator(
                                                rating: avgRating,
                                                itemBuilder: (context, index) =>
                                                    const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                    ),
                                                itemCount: 5,
                                                itemSize: 16,
                                                unratedColor:
                                                    Colors.grey.shade600,
                                                direction: Axis.horizontal,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${avgRating.toStringAsFixed(1)} ($totalReviews)",
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: Text(
                                        "Rs ${data['price'] ?? 'N/A'}",
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                        ),
                                        onPressed: () =>
                                            addToCart(context, data),
                                        child: const Text(
                                          "Add to Cart",
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SpecialOffersWidget extends StatelessWidget {
  const SpecialOffersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('offers')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final offers = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text(
                'Special Offers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            CarouselSlider.builder(
              itemCount: offers.length,
              options: CarouselOptions(
                height: 200, 
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 3),
                enlargeCenterPage: true,
                viewportFraction: 0.8,
              ),
              itemBuilder: (context, index, realIndex) {
                final data = offers[index].data() as Map<String, dynamic>;

                Uint8List? imageBytes;
                if (data['imageBase64'] != null &&
                    data['imageBase64'].isNotEmpty) {
                  try {
                    imageBytes = base64Decode(data['imageBase64']);
                  } catch (e) {
                    debugPrint("Base64 decode error: $e");
                  }
                }

                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageBytes != null
                          ? Image.memory(imageBytes, fit: BoxFit.cover)
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),

                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.6),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ),

                      Positioned(
                        bottom: 12,
                        left: 12,
                        right: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['discount'] ?? '',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['description'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
