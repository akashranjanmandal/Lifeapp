import 'package:flutter/material.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/teacher_faq_category_model.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/service/faq_test_service.dart';

class FaqTestPage extends StatefulWidget {
  const FaqTestPage({super.key});

  @override
  State<FaqTestPage> createState() => _FaqTestPageState();
}

class _FaqTestPageState extends State<FaqTestPage> {
  final FaqTestService _service = FaqTestService();
  late Future<List<TeacherFaq>> _faqsFuture;

  @override
  void initState() {
    super.initState();
    _faqsFuture = _service.getAllFaqs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FAQ Test (All Audiences)")),
      body: FutureBuilder<List<TeacherFaq>>(
        future: _faqsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No FAQs found"));
          }

          final faqs = snapshot.data!;
          return ListView.builder(
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(faq.question),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faq.answer),
                      const SizedBox(height: 4),
                      Text("Audience: ${faq.audience}"),
                      Text("Category: ${faq.categoryName}"),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
