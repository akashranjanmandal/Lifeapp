import 'package:flutter/material.dart';
import 'package:lifelab3/src/student/home/services/faq_service.dart';

class FaqTestPage extends StatefulWidget {
  const FaqTestPage({super.key});

  @override
  _FaqTestPageState createState() => _FaqTestPageState();
}

class _FaqTestPageState extends State<FaqTestPage> {
  final FaqService _faqService = FaqService();
  List<dynamic> allFaqs = [];
  List<dynamic> displayedFaqs = [];

  String selectedCategory = 'all';
  List<String> categories = ['all'];

  String selectedType = 'all'; // NEW
  List<String> types = ['all', 'student', 'teacher']; // NEW

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  void _loadFaqs() async {
    final faqs = await _faqService.getFaqsByCategory();
    setState(() {
      allFaqs = faqs;
      final categorySet = <String>{};
      for (var faq in allFaqs) {
        if (faq['category'] != null && faq['category']['name'] != null) {
          categorySet.add(faq['category']['name']);
        }
      }
      categories.addAll(categorySet);
      _applyFilter();
    });
  }

  void _applyFilter() {
    setState(() {
      displayedFaqs = allFaqs.where((faq) {
        final matchesAudience = selectedType == 'all'
            ? true
            : (faq['audience'] != null &&
                faq['audience'].toString().toLowerCase() ==
                    selectedType.toLowerCase());

        if (selectedCategory == 'all') {
          return matchesAudience;
        } else {
          final matchesCategory = faq['category'] != null &&
              faq['category']['name'] == selectedCategory;
          return matchesCategory && matchesAudience;
        }
      }).toList();
    });
  }

  void _changeCategory(String category) {
    selectedCategory = category;
    _applyFilter();
  }

  void _changeType(String type) {
    // NEW
    selectedType = type;
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_circle_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('F', style: TextStyle(color: Colors.black26)),
        actions: [
          // Category Dropdown
          DropdownButton<String>(
            value: selectedCategory,
            items: categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (value) {
              if (value != null) _changeCategory(value);
            },
          ),
          // Type Dropdown (NEW)
          DropdownButton<String>(
            value: selectedType,
            items: types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (value) {
              if (value != null) _changeType(value);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView.builder(
        itemCount: displayedFaqs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(displayedFaqs[index]['question'] ?? ""),
            subtitle: Text(displayedFaqs[index]['answer'] ?? ""),
            trailing: Text(
                "${displayedFaqs[index]['category']?['name'] ?? ""} | ${displayedFaqs[index]['audience'] ?? ""}"),
          );
        },
      ),
    );
  }
}
