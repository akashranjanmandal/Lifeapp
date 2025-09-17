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

      // STRICT: only keep student audience, remove 'all'
      final studentFaqs = faqs.where((f) => f.audience == 'student').toList();

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

  void _openCategory(BuildContext context, StudentFaqCategory category) {
    final filtered =
        _allFaqs.where((f) => f.categoryKey == category.key).toList();

    final categoryWithFaqs = category.copyWith(faqItems: filtered);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentFaqDetailPage(category: categoryWithFaqs),
      ),
    );
  }

  Widget _buildCategoryIcon(String icon) {
    if (icon.endsWith('.png')) {
      return Image.asset(
        icon,
        width: 35,
        height: 35,
        fit: BoxFit.contain,
      );
    }
    return Text(
      icon,
      style: const TextStyle(fontSize: 35),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return ListView.builder(
      itemCount: predefinedStudentCategories.length,
      itemBuilder: (BuildContext context, int index) {
        final category = predefinedStudentCategories[index];
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
                    child: _buildCategoryIcon(category.icon),
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
