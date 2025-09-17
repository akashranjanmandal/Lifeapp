import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/teacher_faq_category_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/widgets/teacher_faq_detail.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/service/teacher_faq_service.dart';

class TeacherFaqListview extends StatefulWidget {
  const TeacherFaqListview({super.key});

  @override
  State<TeacherFaqListview> createState() => _TeacherFaqListviewState();
}

class _TeacherFaqListviewState extends State<TeacherFaqListview> {
  final TeacherFaqService _faqService = TeacherFaqService();

  bool _loading = true;
  String? _error;
  List<TeacherFaq> _allFaqs = const [];

  @override
  void initState() {
    super.initState();
    _loadTeacherFaqs();
  }

  Future<void> _loadTeacherFaqs() async {
    try {
      final faqs = await _faqService.getFaqsByCategory();

      //extra safeguard: only keep teacher audience
      final teacherFaqs = faqs.where((f) => f.audience == 'teacher').toList();

      setState(() {
        _allFaqs = teacherFaqs;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Teacher FAQs';
        _loading = false;
      });
    }
  }

  void _openCategory(BuildContext context, TeacherFaqCategory category) {
    final filtered = _allFaqs.where((f) {
      return f.categoryKey == category.key && f.audience == 'teacher';
    }).toList();

    final categoryWithFaqs = category.copyWith(faqItems: filtered);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherFaqDetailPage(category: categoryWithFaqs),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    return ListView.builder(
      itemCount: predefinedTeacherCategories.length,
      itemBuilder: (BuildContext context, int index) {
        final category = predefinedTeacherCategories[index];
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
