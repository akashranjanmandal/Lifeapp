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

      //
      final teacherFaqs = faqs
          .where((f) => f.audience == 'teacher' || f.audience == 'all')
          .toList();

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

  // Dynamically build categories from FAQs
  List<TeacherFaqCategory> get categories {
    final Map<String, TeacherFaqCategory> map = {};

    for (final faq in _allFaqs) {
      map.putIfAbsent(
        faq.categoryKey,
        () => TeacherFaqCategory(
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

  void _openCategory(BuildContext context, TeacherFaqCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherFaqDetailPage(category: category),
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
