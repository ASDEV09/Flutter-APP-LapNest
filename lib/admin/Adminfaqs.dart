import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminFaqPage extends StatefulWidget {
  const AdminFaqPage({Key? key}) : super(key: key);

  @override
  State<AdminFaqPage> createState() => _AdminFaqPageState();
}

class _AdminFaqPageState extends State<AdminFaqPage> {
  final CollectionReference faqsRef =
      FirebaseFirestore.instance.collection('faqs');
  User? currentUser;

  final List<String> categories = [
    "General",
    "Account",
    "Service",
    "Payment",
    "Shipping",
    "Returns",
  ];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _showFaqDialog({DocumentSnapshot? doc}) async {
    final qCtrl = TextEditingController(text: doc?.get('question') ?? '');
    final aCtrl = TextEditingController(text: doc?.get('answer') ?? '');
    String selectedCategory = doc?.get('category') ?? categories.first;
    bool isPublished = doc?.get('isPublished') ?? false;
    int? existingOrder = doc?.data() != null ? doc?.get('order') : null;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFF1E1E2E),
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            title: Text(doc == null ? 'Add FAQ' : 'Edit FAQ'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: qCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Question',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: aCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Answer',
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Category",
                      labelStyle: TextStyle(color: Colors.white),
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedCategory = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Published',
                          style: TextStyle(color: Colors.white)),
                      Switch(
                        value: isPublished,
                        activeColor: Colors.deepPurple,
                        onChanged: (v) {
                          setStateDialog(() {
                            isPublished = v;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final data = {
                    'question': qCtrl.text.trim(),
                    'answer': aCtrl.text.trim(),
                    'category': selectedCategory,
                    'isPublished': isPublished,
                  };

                  if (doc == null) {
                    data['order'] = DateTime.now().millisecondsSinceEpoch;
                    data['createdAt'] = FieldValue.serverTimestamp();
                    await faqsRef.add(data);
                  } else {
                    data['order'] =
                        existingOrder ?? DateTime.now().millisecondsSinceEpoch;
                    data['updatedAt'] = FieldValue.serverTimestamp();
                    await faqsRef.doc(doc.id).update(data);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Stream<int> _getCount(String cat) {
    return faqsRef.where('category', isEqualTo: cat).snapshots().map((s) => s.size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Admin - FAQs',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ElevatedButton.icon(
              onPressed: () => _showFaqDialog(),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Add", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: AppDrawer(user: currentUser),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categories.length, (i) {
                final bool isSelected = selectedIndex == i;

                return StreamBuilder<int>(
                  stream: _getCount(categories[i]),
                  builder: (context, snap) {
                    final count = snap.data ?? 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isSelected
                              ? Colors.deepPurple
                              : const Color(0xFF1E293B),
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.black),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedIndex = i;
                          });
                        },
                        child: Text(
                          "${categories[i]} ($count)",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: faqsRef
                  .where('category', isEqualTo: categories[selectedIndex])
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snap.hasData || snap.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No FAQs in ${categories[selectedIndex]}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }

                final docs = snap.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final q = doc.get('question') ?? '';
                    final a = doc.get('answer') ?? '';
                    final isPublished = doc.get('isPublished') ?? false;

                    return Card(
                      color: const Color(0xFF1B1F36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        title: Text(
                          q,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              a,
                              style: GoogleFonts.poppins(color: Colors.grey[300]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        leading: Icon(
                          isPublished
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          color: isPublished ? Colors.deepPurple : Colors.grey,
                          size: 28,
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          color: const Color(0xFF1E293B),
                          onSelected: (v) async {
                            if (v == 'edit') {
                              _showFaqDialog(doc: doc);
                            }
                            if (v == 'toggle') {
                              await faqsRef.doc(doc.id).update({
                                'isPublished': !isPublished,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                            }
                            if (v == 'delete') {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => _buildDeleteDialog(context),
                              );

                              if (confirm == true) {
                                await faqsRef.doc(doc.id).delete();
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(Icons.toggle_on,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Toggle Publish',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Delete',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildDeleteDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2440),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        "Delete FAQ",
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: const Text(
        "Are you sure you want to delete this FAQ?",
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel", style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text("Delete", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
