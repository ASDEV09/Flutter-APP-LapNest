import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

class SortFilterScreen extends StatefulWidget {
  final List<String> categories;
  final double minPrice;
  final double maxPrice;
  final double selectedMinPrice;
  final double selectedMaxPrice;

  const SortFilterScreen({
    Key? key,
    this.categories = const [],
    this.minPrice = 0,
    this.maxPrice = 10000,
    double? selectedMinPrice,
    double? selectedMaxPrice,
  }) : selectedMinPrice = selectedMinPrice ?? minPrice,
       selectedMaxPrice = selectedMaxPrice ?? maxPrice,
       super(key: key);

  @override
  _SortFilterScreenState createState() => _SortFilterScreenState();
}

class _SortFilterScreenState extends State<SortFilterScreen> {
  String selectedCategory = "All";
  late double minVal;
  late double maxVal;
  String selectedSort = "";
  int selectedRating = 0;

  @override
  void initState() {
    super.initState();
    minVal = widget.selectedMinPrice;
    maxVal = widget.selectedMaxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0F2C),

              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Sort & Filter",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Categories",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildCategoryChip("All"),
                    ...widget.categories.map((cat) => _buildCategoryChip(cat)),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Price Range",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                FlutterSlider(
                  values: [minVal, maxVal],
                  rangeSlider: true,
                  max: widget.maxPrice,
                  min: widget.minPrice,
                  handler: FlutterSliderHandler(
                    decoration: const BoxDecoration(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  rightHandler: FlutterSliderHandler(
                    decoration: const BoxDecoration(),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  trackBar: FlutterSliderTrackBar(
                    activeTrackBar: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    inactiveTrackBar: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onDragging: (handlerIndex, lowerValue, upperValue) {
                    setState(() {
                      minVal = lowerValue;
                      maxVal = upperValue;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rs ${minVal.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Rs ${maxVal.toStringAsFixed(0)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Sort by",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSortChip("Popular"),
                    _buildSortChip("Most Recent"),
                    _buildSortChip("Price Low → High"),
                    _buildSortChip("Price High → Low"),
                  ],
                ),

                const SizedBox(height: 20),
                const Text(
                  "Rating",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildRatingChip(0, "All"),
                    _buildRatingChip(5, "5"),
                    _buildRatingChip(4, "4"),
                    _buildRatingChip(3, "3"),
                    _buildRatingChip(2, "2"),
                    _buildRatingChip(1, "1"),
                  ],
                ),

                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedCategory = "All";
                            minVal = widget.minPrice;
                            maxVal = widget.maxPrice;
                            selectedSort = "";
                            selectedRating = 0;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: Colors.white,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Reset",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, {
                            "category": selectedCategory,
                            "minPrice": minVal,
                            "maxPrice": maxVal,
                            "sort": selectedSort,
                            "rating": selectedRating,
                            "filterApplied": true,
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Apply"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = selectedCategory == category;
    return ChoiceChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedCategory = category;
        });
      },
      selectedColor: Colors.black,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildSortChip(String sortOption) {
    final isSelected = selectedSort == sortOption;
    return ChoiceChip(
      label: Text(sortOption),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedSort = sortOption;
        });
      },
      selectedColor: Colors.black,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _buildRatingChip(int rating, String label) {
    final isSelected = selectedRating == rating;
    return ChoiceChip(
      avatar: const Icon(Icons.star, size: 18, color: Colors.black),
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          selectedRating = rating;
        });
      },
      selectedColor: Colors.black,
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}