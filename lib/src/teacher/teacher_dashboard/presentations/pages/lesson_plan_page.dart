import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/custom_button.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class LessonPlanPage extends StatefulWidget {
  final String type;
  const LessonPlanPage({super.key, required this.type});

  @override
  State<LessonPlanPage> createState() => _LessonPlanPageState();
}

class _LessonPlanPageState extends State<LessonPlanPage> {
  late DateTime _startTime;

  @override
  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
      provider.clearLessonPlan();
      provider.getBoard();
      provider.getLanguage().then((_) {
        // Check if we have any languages available
        if (provider.languageModel?.data?.laLessionPlanLanguages == null ||
            provider.languageModel!.data!.laLessionPlanLanguages!.isEmpty) {
          return;
        }

        // Find English or use first language
        var selectedLanguage = provider.languageModel!.data!.laLessionPlanLanguages![0];
        for (final lang in provider.languageModel!.data!.laLessionPlanLanguages!) {
          if (lang.name?.toLowerCase() == 'english') {
            selectedLanguage = lang;
            break;
          }
        }

        provider.language = selectedLanguage.name ?? 'English';
        provider.languageId = selectedLanguage.id ?? 0;
        provider.notifyListeners();
      });
      MixpanelService.track("LessonPlanLanguagePage_View");
    });
  }
  @override
  void dispose() {
    final duration = DateTime.now().difference(_startTime).inSeconds;
    MixpanelService.track("LessonPlanLanguagePage_ActivityTime", properties: {
      "duration_seconds": duration,
    });
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    MixpanelService.track("LessonPlanLanguagePage_BackClicked");
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherDashboardProvider>(context);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: commonAppBar(context: context, name: "Lesson Plan"),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Language Selection
              const Text(
                "Language",
                style: TextStyle(
                  color: ColorCode.textBlackColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showLanguageDropdown(context, provider),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.language.isNotEmpty
                                ? provider.language
                                : "Select Language",
                            style: TextStyle(
                              fontSize: 16,
                              color: provider.language.isNotEmpty
                                  ? Colors.black
                                  : Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Colors.grey.shade700,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),
              CustomButton(
                height: 50,
                width: double.infinity,
                name: StringHelper.submit,
                onTap: () {
                  if (provider.language.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a language")));
                    return;
                  }
                  MixpanelService.track("LessonPlanLanguagePage_SubmitClicked", properties: {
                    "selected_language": provider.language,
                    "selected_language_id": provider.languageId,
                    "type": widget.type,
                  });
                  provider.submitPlan(context: context, type: widget.type);
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDropdown(BuildContext context, TeacherDashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              "Select Language",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: provider.languageModel?.data?.laLessionPlanLanguages?.length ?? 0,
                itemBuilder: (context, index) {
                  final language = provider.languageModel!.data!.laLessionPlanLanguages![index];
                  return ListTile(
                    title: Text(
                      language.name!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: provider.language == language.name
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: provider.language == language.name
                            ? Colors.blueAccent
                            : Colors.black,
                      ),
                    ),
                    trailing: provider.language == language.name
                        ? Icon(
                      Icons.check,
                      color: Theme.of(context).primaryColor,
                    )
                        : null,
                    onTap: () {
                      MixpanelService.track("LessonPlanLanguagePage_LanguageSelected", properties: {
                        "language_name": language.name,
                        "language_id": language.id,
                      });
                      provider.language = language.name!;
                      provider.languageId = language.id!;
                      provider.notifyListeners();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}