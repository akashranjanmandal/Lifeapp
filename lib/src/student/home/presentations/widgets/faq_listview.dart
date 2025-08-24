import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/student/home/models/faq_category_model.dart';
import 'package:lifelab3/src/student/home/services/faq_service.dart';
import 'package:lifelab3/src/student/home/presentations/widgets/faq_qa_page.dart';

class FaqListview extends StatefulWidget {
  const FaqListview({super.key});

  @override
  State<FaqListview> createState() => _FaqListviewState();
}

class _FaqListviewState extends State<FaqListview> {
  final FaqService _faqService = FaqService();

  bool _loading = true;
  String? _error;
  List<Faq> _allFaqs = const [];

  @override
  void initState() {
    super.initState();
    _loadAllFaqs();
  }

  Future<void> _loadAllFaqs() async {
    try {
      // fetch everything once; we'll filter per category on tap
      final faqs = await _faqService.getFaqsByCategory();
      setState(() {
        _allFaqs = faqs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load FAQs';
        _loading = false;
      });
    }
  }

  void _openCategory(BuildContext context, FaqCategory category) {
    // filter: selected category + audience student or all
    final filtered = _allFaqs.where((f) {
      final matchesCategory = f.categoryKey == category.key;
      final matchesAudience = f.audience == 'student' || f.audience == 'all';
      return matchesCategory && matchesAudience;
    }).toList();

    final categoryWithFaqs = category.copyWith(faqItems: filtered);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FaqDetailPage(category: categoryWithFaqs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    // your original landing UI with big buttons & emojis
    return ListView.builder(
      itemCount: predefinedCategories.length,
      itemBuilder: (BuildContext context, int index) {
        final category = predefinedCategories[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: GestureDetector(
            onTap: () => _openCategory(context, category),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: ColorCode.buttonColor,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      category.icon,
                      style: const TextStyle(fontSize: 35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
