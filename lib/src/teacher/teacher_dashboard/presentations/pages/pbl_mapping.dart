import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/model/teacher_subject_grade_model.dart';
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
  bool _skippedSubjectGrade = false;
  final List<int> _visibleSteps = [1]; // track steps actually shown

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
    try {
      await provider.getDashboardData();
      await provider.getLanguage();

      final boardNameFromDashboard = provider.dashboardModel?.data?.user?.board_name ?? '';
      if (boardNameFromDashboard.isNotEmpty) {
        provider.board = boardNameFromDashboard;
      } else {
        final boards = provider.boardModel?.data?.boards ?? [];
        if (boards.isNotEmpty) {
          provider.board = boards.first.name ?? '';
        }
      }

      final languages = provider.languageModel?.data?.laLessionPlanLanguages ?? [];
      if (languages.isNotEmpty) {
        final englishLang = languages.firstWhere(
              (lang) => (lang.name ?? '').toLowerCase() == 'english',
          orElse: () => languages.first,
        );
        provider.language = englishLang.name ?? '';
        provider.languageId = englishLang.id ?? 0;
      }

      debugPrint("Initialized: languageId=${provider.languageId}, boardId=${provider.boardId}");
      provider.notifyListeners();
    } catch (e) {
      debugPrint("Error initializing data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToStep(int newStep) {
    step = newStep;
    if (!_visibleSteps.contains(newStep)) _visibleSteps.add(newStep);
    setState(() {});
  }

  void _nextStep() {
    if (step == 1) {
      _loadSubjects();
    } else if (step == 2) {
      _loadGrades();
    } else if (step == 3) {
      _checkPblForSelectedSubjectGrade();
    }
  }

  Future<void> _loadSubjects() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
    try {
      await provider.getTeacherSubjectGrade();
      final pairs = provider.teacherSubjectGradeModel?.subjectGradePairs ?? [];

      if (pairs.isEmpty) {
        debugPrint("❌ No subject/grade pairs available for this teacher");
        _goToStep(99);
        return;
      }

      // Filter pairs that have PDFs
      List<TeacherSubjectGradePair> pairsWithPdf = [];
      for (final pair in pairs) {
        await provider.getPblTextbookMappings(
          languageId: provider.languageId,
          laBoardId: provider.boardId,
          laSubjectId: pair.subject?.id ?? 0,
          laGradeId: pair.grade?.id ?? 0,
        );

        if (provider.pdfMappings.isNotEmpty) {
          pairsWithPdf.add(pair);
        }
      }

      if (pairsWithPdf.isEmpty) {
        debugPrint("❌ No PDFs available for any subject/grade pairs");
        _goToStep(99);
        return;
      }

      provider.subjectGradePairsWithPdf = pairsWithPdf;

      // Auto-select if only one pair
      if (pairsWithPdf.length == 1) {
        final pair = pairsWithPdf.first;
        provider.subjectId = pair.subject?.id ?? 0;
        provider.gradeId = pair.grade?.id ?? 0;
        provider.notifyListeners();
        _skippedSubjectGrade = true;

        await _checkPblForSinglePair(provider);
        return;
      }

      // Multiple subjects → show subject step
      _goToStep(2);
    } catch (e) {
      debugPrint("Error loading subjects: $e");
      Fluttertoast.showToast(msg: "Failed to load subjects");
      _goToStep(99);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGrades() async {
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
    final pair = provider.subjectGradePairsWithPdf.firstWhere(
          (p) => p.subject?.id == provider.subjectId,
      orElse: () => provider.subjectGradePairsWithPdf.first,
    );

    if (pair.grade == null) {
      _goToStep(99);
    } else {
      _goToStep(3);
    }
  }

  Future<void> _checkPblForSelectedSubjectGrade() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
    try {
      await provider.getPblTextbookMappings(
        languageId: provider.languageId,
        laBoardId: provider.boardId,
        laSubjectId: provider.subjectId,
        laGradeId: provider.gradeId,
      );

      if (provider.pdfMappings.isEmpty) {
        _goToStep(99);
      } else {
        _goToStep(4);
      }
    } catch (e) {
      debugPrint("Error checking PBL data: $e");
      _goToStep(99);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkPblForSinglePair(TeacherDashboardProvider provider) async {
    setState(() => _isLoading = true);
    try {
      await provider.getPblTextbookMappings(
        languageId: provider.languageId,
        laBoardId: provider.boardId,
        laSubjectId: provider.subjectId,
        laGradeId: provider.gradeId,
      );

      if (provider.pdfMappings.isEmpty) {
        _goToStep(99);
      } else {
        _goToStep(4);
      }
    } catch (e) {
      debugPrint("Error loading PDFs for single pair: $e");
      _goToStep(99);
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

      final dir = Directory("/storage/emulated/0/Download");
      if (!await dir.exists()) await dir.create(recursive: true);

      final savePath = "${dir.path}/$fileName.pdf";
      await Dio().download(url, savePath);

      Fluttertoast.showToast(
        msg: "Downloaded to Downloads/$fileName.pdf",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
      );

      Future.delayed(const Duration(seconds: 1), () {
        OpenFile.open(savePath);
      });
    } catch (e) {
      debugPrint("Download error: $e");
      Fluttertoast.showToast(msg: "Failed to download PDF: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeacherDashboardProvider>(context);

    return WillPopScope(
      onWillPop: () async {
        if (_visibleSteps.length <= 1) return true;
        _visibleSteps.removeLast();
        step = _visibleSteps.last;
        setState(() {});
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "PBL Textbook Mapping",
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_visibleSteps.length <= 1) {
                Navigator.pop(context);
              } else {
                _visibleSteps.removeLast();
                step = _visibleSteps.last;
                setState(() {});
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
              if (step < 4 && step != 99 && !_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isButtonEnabled(provider) ? Colors.blue : Colors.grey,
                      ),
                      onPressed: _isButtonEnabled(provider) ? _nextStep : null,
                      child: const Text("Next", style: TextStyle(fontSize: 16, color: Colors.white)),
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
      case 99:
        return _buildNoDataStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildLanguageStep(TeacherDashboardProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text("Select Language", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => _showLanguageDropdown(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(provider.language.isNotEmpty ? provider.language : "Select Language",
                    style: const TextStyle(fontSize: 16)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLanguageDropdown(BuildContext context, TeacherDashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: ListView.builder(
          itemCount: provider.languageModel?.data?.laLessionPlanLanguages?.length ?? 0,
          itemBuilder: (context, index) {
            final language = provider.languageModel!.data!.laLessionPlanLanguages![index];
            return ListTile(
              title: Text(language.name ?? ''),
              trailing: provider.languageId == language.id ? const Icon(Icons.check) : null,
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
    final pairsWithPdf = provider.subjectGradePairsWithPdf;
    if (pairsWithPdf.isEmpty) return _buildNoDataStep();

    return ListView.builder(
      itemCount: pairsWithPdf.length,
      itemBuilder: (context, index) {
        final pair = pairsWithPdf[index];
        final isSelected = provider.subjectId == pair.subject?.id;
        return InkWell(
          onTap: () {
            provider.subjectId = pair.subject?.id ?? 0;
            provider.gradeId = pair.grade?.id ?? 0;
            provider.notifyListeners();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2)],
            ),
            child: Text(pair.subject?.title ?? '',
                style: TextStyle(fontSize: 16, color: isSelected ? Colors.blue : Colors.black87)),
          ),
        );
      },
    );
  }

  Widget _buildGradeStep(TeacherDashboardProvider provider) {
    final pair = provider.subjectGradePairsWithPdf.firstWhere(
          (p) => p.subject?.id == provider.subjectId,
      orElse: () => provider.subjectGradePairsWithPdf.first,
    );

    return ListView(
      children: [
        const SizedBox(height: 20),
        const Text("Select Grade", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            provider.gradeId = pair.grade?.id ?? 0;
            provider.notifyListeners();
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: provider.gradeId == pair.grade?.id ? Border.all(color: Colors.blue, width: 2) : null,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 2)],
            ),
            child: Text(pair.grade?.name ?? '',
                style: TextStyle(fontSize: 16, color: provider.gradeId == pair.grade?.id ? Colors.blue : Colors.black87)),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfStep(TeacherDashboardProvider provider) {
    final pdfs = provider.pdfMappings;
    if (pdfs.isEmpty) return _buildNoDataStep();

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
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            title: Text(pdf.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(pdf.document.name, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfPage(url: ApiHelper.imgBaseUrl + pdf.document.url, name: pdf.document.name),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.green),
                  onPressed: () => _downloadPdf(ApiHelper.imgBaseUrl + pdf.document.url, pdf.document.name),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoDataStep() {
    return const Center(
      child: Text("No PDFs available for this teacher", style: TextStyle(fontSize: 16), textAlign: TextAlign.center),
    );
  }
}
