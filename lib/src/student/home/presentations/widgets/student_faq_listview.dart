import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/student/home/models/student_faq_category_model.dart';
import 'package:lifelab3/src/student/home/presentations/widgets/student_faq_detail.dart';
import 'package:lifelab3/src/student/home/services/student_faq_service.dart';

class StudentFaqListView extends StatefulWidget {
  const StudentFaqListView({super.key});

  @override
  State<StudentFaqListView> createState() => _StudentFaqListViewState();
}

class _StudentFaqListViewState extends State<StudentFaqListView> {
  final StudentFaqService _faqService = StudentFaqService();

  bool _loading = true;
  String? _error;
  List<StudentFaq> _allFaqs = const [];

  @override
  void initState() {
    super.initState();
    _loadStudentFaqs();
  }

  Future<void> _loadStudentFaqs() async {
    try {
      final faqs = await _faqService.getFaqsByCategory();

      // only keep student audience + all
      final studentFaqs = faqs
          .where((f) => f.audience == 'student' || f.audience == 'all')
          .toList();

      setState(() {
        _allFaqs = studentFaqs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Student FAQs';
        _loading = false;
      });
    }
  }

  // Dynamically build categories from FAQs
  List<StudentFaqCategory> get categories {
    final Map<String, StudentFaqCategory> map = {};

    for (final faq in _allFaqs) {
      map.putIfAbsent(
        faq.categoryKey,
        () => StudentFaqCategory(
          key: faq.categoryKey,
          name: faq.categoryName,
        ),
      );

      map[faq.categoryKey] = map[faq.categoryKey]!.copyWith(
        faqItems: [...map[faq.categoryKey]!.faqItems, faq],
      );
    }

    return map.values.toList();
  }

  void _openCategory(BuildContext context, StudentFaqCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentFaqDetailPage(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (BuildContext context, int index) {
        final category = categories[index];

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
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
          ),
        );
      },
    );
  }
}
