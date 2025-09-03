import 'dart:convert';
import 'dart:typed_data';

import 'package:app/user/AllProducts.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/my_tabs.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:app/user/ProductDetailPageById.dart'; // <-- Add this import and adjust path if needed
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'custom_bottom_nav_bar.dart';

class MyReview extends StatefulWidget {
  const MyReview({Key? key}) : super(key: key);

  @override
  _MyReviewState createState() => _MyReviewState();
}

class _MyReviewState extends State<MyReview> {
  List<ReviewItem> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    fetchMyReviews();
  }

  Future fetchMyReviews() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('reviews')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<ReviewItem> loaded = snap.docs.map((doc) {
        final data = doc.data();
        final String productImage = data['productImage'] ?? '';
        final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
        final List<String>? images = (data['images'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList();

        return ReviewItem(
          docId: doc.id,
          productTitle: data['productTitle'] ?? '',
          orderId: data['orderId'] ?? '',
          productId: data['productId'] ?? '', // NEW field
          rating: (data['rating'] is int)
              ? data['rating']
              : (data['rating'] as num).toInt(),
          review: data['review'] ?? '',
          productImage: productImage,
          timestamp: timestamp.toDate(),
          images: images,
        );
      }).toList();

      setState(() {
        _reviews = loaded;
        _loading = false;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showEditDialog(ReviewItem item) async {
    final controller = TextEditingController(text: item.review);
    int newRating = item.rating;
    List<String> imageBase64List = List<String>.from(item.images ?? []);
    final ImagePicker picker = ImagePicker();

    String getRatingDescription(int rating) {
      switch (rating) {
        case 5:
          return "Excellent";
        case 4:
          return "Good";
        case 3:
          return "Average";
        case 2:
          return "Poor";
        case 1:
          return "Very Poor";
        default:
          return "";
      }
    }

    Future<void> pickNewImages(StateSetter setStateDialog) async {
      final List<XFile> pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.length + imageBase64List.length > 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("You can only upload up to 3 images.")),
        );
        return;
      }

      for (var file in pickedFiles) {
        final bytes = await file.readAsBytes();
        final base64Str = base64Encode(bytes);
        setStateDialog(() {
          imageBase64List.add(base64Str);
        });
      }
    }

    void removeImage(int index, StateSetter setStateDialog) {
      setStateDialog(() {
        imageBase64List.removeAt(index);
      });
    }

    await showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Color(0xFF0A0F2C),
              title: Text(
                'Edit Review for ${item.productTitle}',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      style: const TextStyle(
                        color: Colors.white,
                      ), // input text white
                      decoration: InputDecoration(
                        labelText: 'Review',
                        labelStyle: const TextStyle(
                          color: Colors.white,
                        ), // label text white
                        enabledBorder: const OutlineInputBorder(
                          // normal border white
                          borderSide: BorderSide(color: Colors.white),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          // focused border white
                          borderSide: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Rating: ', style: TextStyle(color: Colors.white)),
                        ...List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < newRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setStateDialog(() {
                                newRating = index + 1;
                              });
                            },
                          );
                        }),
                      ],
                    ),
                    if (newRating > 0)
                      Text(
                        getRatingDescription(newRating),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Review Images (max 3):",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ...imageBase64List.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final base64Str = entry.value;
                          Uint8List bytes = base64Decode(base64Str);
                          return Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor),
                                ),
                                child: Image.memory(bytes, fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: GestureDetector(
                                  onTap: () => removeImage(idx, setStateDialog),
                                  child: Container(
                                    color: Colors.deepPurple,
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        if (imageBase64List.length < 3)
                          GestureDetector(
                            onTap: () => pickNewImages(setStateDialog),
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Color(0xFF1E293B),
                              child: Icon(
                                Icons.add_a_photo,
                                size: 36,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                  onPressed: () async {
                    String newReview = controller.text.trim();
                    if (newReview.isEmpty) return;

                    try {
                      await FirebaseFirestore.instance
                          .collection('reviews')
                          .doc(item.docId)
                          .update({
                            'review': newReview,
                            'rating': newRating,
                            'images': imageBase64List,
                            'timestamp': Timestamp.now(),
                          });

                      setState(() {
                        int index = _reviews.indexWhere(
                          (e) => e.docId == item.docId,
                        );
                        if (index != -1) {
                          _reviews[index] = _reviews[index].copyWith(
                            review: newReview,
                            rating: newRating,
                            images: imageBase64List,
                            timestamp: DateTime.now(),
                          );
                        }
                      });

                      Navigator.of(context).pop();
                    } catch (e) {
                      print('Error updating review: $e');
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _canEdit(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inDays < 7; // 7 din ke andar edit allowed
  }

  int _selectedIndex = 0;

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

  @override
  Widget build(BuildContext context) {
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
            // Use Builder to get correct context for Scaffold
            builder: (context) => AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'My Review',
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
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
      body: Column(
        children: [
          OrderTabsWidget(selectedIndex: 3),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                ? const Center(child: Text('No reviews yet.'))
                : ListView.builder(
                    itemCount: _reviews.length,
                    itemBuilder: (context, index) {
                      final r = _reviews[index];
                      final canEdit = _canEdit(r.timestamp);
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPageById(
                                    productId: r.productId,
                                  ),
                                ),
                              );
                            },
                            child: _buildProductImage(r.productImage),
                          ),
                          title: Text(
                            'Product: ${r.productTitle}',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Review: ${r.review}',
                                style: TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Rating: ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  ...List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < r.rating
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.amber,
                                      size: 20,
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Review Images:',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (r.images != null && r.images!.isNotEmpty)
                                SizedBox(
                                  height: 90,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: r.images!.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, imgIndex) {
                                      try {
                                        Uint8List imgBytes = base64Decode(
                                          r.images![imgIndex],
                                        );
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.memory(
                                            imgBytes,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      } catch (_) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey,
                                          child: const Icon(Icons.broken_image),
                                        );
                                      }
                                    },
                                  ),
                                ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canEdit
                                  ? Colors.deepPurple
                                  : Color(0xFF0A0F2C),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              if (canEdit) {
                                _showEditDialog(r);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Edit time expired'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Edit'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return const Icon(Icons.image_not_supported, color: Colors.white);
    }

    return SizedBox(
      width: 60,
      height: 60,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.broken_image, color: Colors.white);
        },
      ),
    );
  }
}

class ReviewItem {
  final String docId;
  final String productTitle;
  final String orderId;
  final String productId; // added this field
  final int rating;
  final String review;
  final String productImage;
  final DateTime timestamp;
  final List<String>? images;

  ReviewItem({
    required this.docId,
    required this.productTitle,
    required this.orderId,
    required this.productId,
    required this.rating,
    required this.review,
    required this.productImage,
    required this.timestamp,
    this.images,
  });

  ReviewItem copyWith({
    String? productTitle,
    String? orderId,
    String? productId,
    int? rating,
    String? review,
    String? productImage,
    DateTime? timestamp,
    List<String>? images,
  }) {
    return ReviewItem(
      docId: docId,
      productTitle: productTitle ?? this.productTitle,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      productImage: productImage ?? this.productImage,
      timestamp: timestamp ?? this.timestamp,
      images: images ?? this.images,
    );
  }
}
