// student_faq_detail.dart
import 'package:flutter/material.dart';
import 'package:lifelab3/src/student/home/models/student_faq_category_model.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';

class StudentFaqDetailPage extends StatefulWidget {
  final StudentFaqCategory category;

  const StudentFaqDetailPage({super.key, required this.category});

  @override
  State<StudentFaqDetailPage> createState() => _StudentFaqDetailPageState();
}

class _StudentFaqDetailPageState extends State<StudentFaqDetailPage> {
  late List<bool> expandedStates;

  @override
  void initState() {
    super.initState();
    // Initialize all items as collapsed
    expandedStates =
        List.generate(widget.category.faqItems.length, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQs',
          style: TextStyle(
            color: ColorCode.textBlackColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                widget.category.name,
                style: const TextStyle(
                  color: ColorCode.textBlackColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.category.faqItems.length,
                  itemBuilder: (context, index) {
                    final item = widget.category.faqItems[index];
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          child: Card(
                            elevation: 0,
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide.none,
                            ),
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                onExpansionChanged: (expanded) {
                                  setState(() {
                                    expandedStates[index] = expanded;
                                  });
                                },
                                title: Text(
                                  item.question,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                trailing: Icon(
                                  color: Colors.blue,
                                  size: 35,
                                  expandedStates[index]
                                      ? Icons.remove_circle_outline_outlined
                                      : Icons.add_circle_outline,
                                ),
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: EdgeInsets.zero,
                                children: [
                                  if (expandedStates[index])
                                    const Divider(
                                      color: ColorCode.greywhite,
                                      thickness: 1.5,
                                      height: 32,
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        item.answer,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.5,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (index != widget.category.faqItems.length - 1)
                          const Divider(
                            color: ColorCode.greywhite,
                            thickness: 1.5,
                            height: 32,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
