import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/pdf_view_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class PblTextBookMappingPage extends StatefulWidget {
  const PblTextBookMappingPage({super.key});

  @override
  State<PblTextBookMappingPage> createState() => _PblTextBookMappingPageState();
}

class _PblTextBookMappingPageState extends State<PblTextBookMappingPage> {
  int step = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    final provider =
    Provider.of<TeacherDashboardProvider>(context, listen: false);
    try {
      // Fetch dashboard and language data
      await provider.getDashboardData(); // get dashboard to populate boardId
      await provider.getLanguage();

      // Set board name from dashboardModel if available, otherwise fallback
      final boardNameFromDashboard =
          provider.dashboardModel?.data?.user?.board_name ?? '';
      if (boardNameFromDashboard.isNotEmpty) {
        provider.board = boardNameFromDashboard;
      } else {
        final boards = provider.boardModel?.data?.boards ?? [];
        if (boards.isNotEmpty) {
          provider.board = boards.first.name ?? '';
        }
      }

      // Set language
      final languages =
          provider.languageModel?.data?.laLessionPlanLanguages ?? [];
      if (languages.isNotEmpty) {
        final englishLang = languages.firstWhere(
              (lang) => (lang.name ?? '').toLowerCase() == 'english',
          orElse: () => languages.first,
        );
        provider.language = englishLang.name ?? '';
        provider.languageId = englishLang.id ?? 0;
      }

      debugPrint(
          "Initialized: languageId=${provider.languageId}, boardId=${provider.boardId}");
      provider.notifyListeners();
    } catch (e) {
      debugPrint("Error initializing data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (step == 1) {
      _loadSubjects();
    } else if (step == 2) {
      _loadGrades();
    } else if (step == 3) {
      _loadPdfMappings();
    }
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final provider =
    Provider.of<TeacherDashboardProvider>(context, listen: false);
    try {
      await provider.getTeacherSubjectGrade();
      setState(() => step = 2);
      debugPrint("Loaded subjects for teacher");
    } catch (e) {
      debugPrint("Error loading subjects: $e");
      Fluttertoast.showToast(msg: "Failed to load subjects");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGrades() async {
    setState(() => step = 3);
    debugPrint("Grades already loaded with subjects");
  }

  Future<void> _loadPdfMappings() async {
    setState(() => _isLoading = true);
    final provider =
    Provider.of<TeacherDashboardProvider>(context, listen: false);
    try {
      await provider.getPblTextbookMappings(
        languageId: provider.languageId,
        laBoardId: provider.boardId,
        laSubjectId: provider.subjectId,
        laGradeId: provider.gradeId,
      );
      setState(() => step = 4);
    } catch (e) {
      debugPrint("Error loading PDFs: $e");
      Fluttertoast.showToast(msg: "Failed to load PDFs");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadPdf(String url, String fileName) async {
    try {
      if (await Permission.manageExternalStorage.request().isDenied) {
        Fluttertoast.showToast(msg: "Storage permission denied");
        return;
      }

      // Public Downloads folder
      final dir = Directory("/storage/emulated/0/Download");
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final savePath = "${dir.path}/$fileName.pdf";

      await Dio().download(url, savePath);

      Fluttertoast.showToast(
        msg: "Downloaded to Downloads/$fileName.pdf",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
      );

      // Open after download
      Future.delayed(const Duration(seconds: 1), () {
        OpenFile.open(savePath);
      });
    } catch (e) {
      debugPrint("Download error: $e");
      Fluttertoast.showToast(msg: "Failed to download PDF: $e");
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherDashboardProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (step > 1) {
          setState(() {
            step--; // Go back one step instead of leaving the page
          });
          return false; // prevent popping the page
        }
        return true; // allow leaving the page when on step 1
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "PBL Textbook Mapping",
            style: TextStyle(
              color: Colors.black, // 👈 forces black text
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (step > 1) {
                setState(() {
                  step--;
                });
              } else {
                Navigator.pop(context); // exit when on step 1
              }
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildStepContent(provider),
              ),
              const SizedBox(height: 16),
              if (step < 4 && !_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isButtonEnabled(provider)
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      onPressed: _isButtonEnabled(provider) ? _nextStep : null,
                      child: const Text(
                        "Next",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isButtonEnabled(TeacherDashboardProvider provider) {
    switch (step) {
      case 1:
        return provider.languageId != 0;
      case 2:
        return provider.subjectId != 0;
      case 3:
        return provider.gradeId != 0;
      default:
        return false;
    }
  }

  Widget _buildStepContent(TeacherDashboardProvider provider) {
    switch (step) {
      case 1:
        return _buildLanguageStep(provider);
      case 2:
        return _buildSubjectStep(provider);
      case 3:
        return _buildGradeStep(provider);
      case 4:
        return _buildPdfStep(provider);
      default:
        return const SizedBox();
    }
  }

  Widget _buildLanguageStep(TeacherDashboardProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "Select Language",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => _showLanguageDropdown(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.language.isNotEmpty
                      ? provider.language
                      : "Select Language",
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageDropdown(
      BuildContext context, TeacherDashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView.builder(
          itemCount:
          provider.languageModel?.data?.laLessionPlanLanguages?.length ?? 0,
          itemBuilder: (context, index) {
            final language =
            provider.languageModel!.data!.laLessionPlanLanguages![index];
            return ListTile(
              title: Text(language.name ?? ''),
              trailing: provider.languageId == language.id
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                provider.language = language.name ?? '';
                provider.languageId = language.id ?? 0;
                provider.notifyListeners();
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubjectStep(TeacherDashboardProvider provider) {
    if (provider.teacherSubjectGradeModel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Deduplicate subjects by title
    final uniqueSubjects = {
      for (var subj in provider.subjects) subj.title!: subj
    }.values.toList();

    if (uniqueSubjects.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.subject, size: 50, color: Colors.grey),
          SizedBox(height: 16),
          Text("No Subjects Available",
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text("Please contact admin if this seems incorrect",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      );
    }

    return ListView.builder(
      itemCount: uniqueSubjects.length,
      itemBuilder: (context, index) {
        final subject = uniqueSubjects[index];
        final isSelected = provider.subjectId == subject.id;
        return InkWell(
          onTap: () {
            provider.subjectId = subject.id ?? 0;
            provider.notifyListeners();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border:
              isSelected ? Border.all(color: Colors.blue, width: 2) : null,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2)
              ],
            ),
            child: Text(
              subject.title ?? '',
              style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.blue : Colors.black87),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGradeStep(TeacherDashboardProvider provider) {
    if (provider.subjectId == 0) {
      return const Center(child: Text("Please select a subject first"));
    }

    // Filter grades for the selected subject
    final grades = provider.grades;
    if (grades.isEmpty) {
      return const Center(child: Text("No grades available for this subject"));
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "Select Grade",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: grades.length,
            itemBuilder: (context, index) {
              final grade = grades[index];
              final isSelected = provider.gradeId == grade.id;
              return InkWell(
                onTap: () {
                  provider.gradeId = grade.id ?? 0;
                  provider.notifyListeners();
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      )
                    ],
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Text(
                    grade.name ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPdfStep(TeacherDashboardProvider provider) {
    final pdfs = provider.pdfMappings;

    if (pdfs.isEmpty) {
      return const Center(
        child: Text(
          "No PDFs available for selected criteria",
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      itemCount: pdfs.length,
      itemBuilder: (context, index) {
        final pdf = pdfs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            title: Text(
              pdf.title,
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              pdf.document.name,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  tooltip: "View PDF",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfPage(
                          url: ApiHelper.imgBaseUrl + pdf.document.url,
                          name: pdf.document.name,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.green),
                  tooltip: "Download PDF",
                  onPressed: () => _downloadPdf(
                    ApiHelper.imgBaseUrl + pdf.document.url,
                    pdf.document.name,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
