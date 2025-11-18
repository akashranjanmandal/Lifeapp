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
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../../teacher_sign_up/model/board_model.dart';

class PblTextBookMappingPage extends StatefulWidget {
  const PblTextBookMappingPage({super.key});

  @override
  State<PblTextBookMappingPage> createState() => _PblTextBookMappingPageState();
}

class _PblTextBookMappingPageState extends State<PblTextBookMappingPage> {
  int step = 1;
  bool _isLoading = false;
  bool _skippedSubjectGrade = false;
  final List<int> _visibleSteps = [1];

  // Download progress variables
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _currentDownloadFileName = '';

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
      await provider.getPblLanguages();
      await provider.getBoard();

      final boardNameFromDashboard = provider.dashboardModel?.data?.user?.board_name ?? '';
      if (boardNameFromDashboard.isNotEmpty) {
        provider.board = boardNameFromDashboard;
      } else {
        final boards = provider.availableBoards;
        if (boards.isNotEmpty) {
          provider.board = boards.first.name ?? '';
          provider.boardId = boards.first.id ?? 0;
        }
      }

      debugPrint("Initialized: pblLanguageId=${provider.pblLanguageId}, boardId=${provider.boardId}, board=${provider.board}");
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
      // This is now the combined selection step - directly check PBL
      _checkPblForSelectedSubjectGrade();
    }
    // Remove the old step 3 logic completely
  }
  Future<void> _loadSubjects() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
    try {
      await provider.getTeacherSubjectGrade();
      final allPairs = provider.teacherSubjectGradeModel?.subjectGradePairs ?? [];

      if (allPairs.isEmpty) {
        debugPrint("❌ No subject/grade pairs available for this teacher");
        _goToStep(99);
        return;
      }

      // Get unique subject-grade combinations that have PDFs
      Map<String, TeacherSubjectGradePair> uniqueCombinations = {};
      Map<int, List<TeacherSubjectGradePair>> subjectToGradesMap = {};

      for (final pair in allPairs) {
        await provider.getPblTextbookMappings(
          laSubjectId: pair.subject?.id ?? 0,
          laGradeId: pair.grade?.id ?? 0,
        );

        if (provider.pdfMappings.isNotEmpty) {
          final subjectId = pair.subject?.id ?? 0;
          final gradeId = pair.grade?.id ?? 0;
          final combinationKey = '$subjectId-$gradeId';

          // Store unique combination - this ensures no duplicates
          if (!uniqueCombinations.containsKey(combinationKey)) {
            uniqueCombinations[combinationKey] = pair;
          }

          // Map subject to all its grades with PDFs
          if (!subjectToGradesMap.containsKey(subjectId)) {
            subjectToGradesMap[subjectId] = [];
          }

          // Check if this grade already exists for this subject
          final existingGrade = subjectToGradesMap[subjectId]!.firstWhere(
                (existingPair) => existingPair.grade?.id == gradeId,
            orElse: () => TeacherSubjectGradePair(), // Return dummy if not found
          );

          if (existingGrade.grade == null) { // Only add if not already present
            subjectToGradesMap[subjectId]!.add(pair);
          }
        }
      }

      if (uniqueCombinations.isEmpty) {
        debugPrint("❌ No PDFs available for any subject/grade pairs");
        _goToStep(99);
        return;
      }

      provider.subjectGradePairsWithPdf = uniqueCombinations.values.toList();
      provider.setSubjectToGradesMap(subjectToGradesMap);

      debugPrint("✅ Found ${provider.subjectGradePairsWithPdf.length} unique subject-grade combinations with PDFs");

      // If there's only one combination, auto-select and go to PDFs
      if (provider.subjectGradePairsWithPdf.length == 1) {
        final pair = provider.subjectGradePairsWithPdf.first;
        provider.subjectId = pair.subject?.id ?? 0;
        provider.gradeId = pair.grade?.id ?? 0;
        provider.notifyListeners();
        _skippedSubjectGrade = true;

        await _checkPblForSinglePair(provider);
        return;
      } else {
        // Multiple combinations - go to combined selection step
        _goToStep(2);
      }
    } catch (e) {
      debugPrint("Error loading subjects: $e");
      Fluttertoast.showToast(msg: "Failed to load subjects");
      _goToStep(99);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
// Update the _nextStep method
  Future<void> _loadGrades() async {
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
    final gradesForSubject = provider.getGradesForSubject(provider.subjectId);

    if (gradesForSubject.isEmpty) {
      _goToStep(99);
    } else if (gradesForSubject.length == 1) {
      // Only one grade for this subject - auto-select and go to PDFs
      provider.gradeId = gradesForSubject.first.grade?.id ?? 0;
      provider.notifyListeners();
      await _checkPblForSelectedSubjectGrade();
    } else {
      // Multiple grades - show grade selection
      _goToStep(3);
    }
  }

  Future<void> _checkPblForSelectedSubjectGrade() async {
    if (_isLoading) return; // Prevent multiple calls

    setState(() => _isLoading = true);
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
    try {
      await provider.getPblTextbookMappings(
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
    if (_isLoading) return; // Prevent multiple calls

    setState(() => _isLoading = true);
    try {
      await provider.getPblTextbookMappings(
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

// FIXED DOWNLOAD METHOD - Works on all Android & iOS versions
  Future<void> _downloadPdf(String url, String fileName) async {
    if (_isDownloading) return; // Prevent multiple downloads

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _currentDownloadFileName = fileName;
    });

    try {
      debugPrint("Starting download process...");

      // Clean file name
      String cleanFileName = _cleanFileName(fileName);

      // For Android 14+, we need to use app-specific directories
      // This avoids the need for MANAGE_EXTERNAL_STORAGE permission
      final Directory downloadDir = await _getSafeDownloadDirectory();
      final String savePath = "${downloadDir.path}/$cleanFileName";

      debugPrint("Downloading to: $savePath");

      // Show downloading indicator
      Fluttertoast.showToast(
        msg: "Downloading PDF...",
        toastLength: Toast.LENGTH_SHORT,
      );

      // Download file with progress tracking
      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint("Download progress: $progress%");
          }
        },
      );

      // Verify the file was downloaded
      final File downloadedFile = File(savePath);
      if (await downloadedFile.exists()) {
        final fileSize = await downloadedFile.length();
        debugPrint("✅ Download successful! File size: ${fileSize} bytes");

        // Show success message
        Fluttertoast.showToast(
          msg: "Download completed successfully!",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Try to open the file
        await _openDownloadedFile(savePath, cleanFileName);
      } else {
        throw Exception("Downloaded file not found");
      }

    } catch (e) {
      debugPrint("❌ Download error: $e");
      Fluttertoast.showToast(
        msg: "Download failed: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _currentDownloadFileName = '';
        });
      }
    }
  }

// SAFE directory method that works on all Android versions
  Future<Directory> _getSafeDownloadDirectory() async {
    if (Platform.isAndroid) {
      try {
        // For Android 14+, we MUST use app-specific directories
        // Try external files directory first (accessible via file managers)
        final Directory? externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final Directory downloadDir = Directory("${externalDir.path}/Download");
          if (await _canCreateDirectory(downloadDir)) {
            debugPrint("✅ Using External Storage Downloads: ${downloadDir.path}");
            return downloadDir;
          }
        }
      } catch (e) {
        debugPrint("❌ External storage failed: $e");
      }

      // Fallback to app documents directory (always works)
      try {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final Directory downloadDir = Directory("${appDocDir.path}/Download");
        if (await _canCreateDirectory(downloadDir)) {
          debugPrint("✅ Using App Documents Directory: ${downloadDir.path}");
          return downloadDir;
        }
      } catch (e) {
        debugPrint("❌ App documents directory failed: $e");
      }
    } else if (Platform.isIOS) {
      // For iOS - Use documents directory (accessible through Files app)
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory downloadDir = Directory("${appDocDir.path}/Download");
      if (await _canCreateDirectory(downloadDir)) {
        debugPrint("✅ Using iOS Documents directory");
        return downloadDir;
      }
    }

    // Final fallback
    final Directory fallbackDir = await getApplicationDocumentsDirectory();
    debugPrint("⚠️ Using final fallback directory: ${fallbackDir.path}");
    return fallbackDir;
  }

  Future<bool> _canCreateDirectory(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // Test write permission
      final testFile = File("${dir.path}/test.tmp");
      await testFile.writeAsString("test");
      await testFile.delete();
      return true;
    } catch (e) {
      debugPrint("Cannot write to directory ${dir.path}: $e");
      return false;
    }
  }

  String _cleanFileName(String fileName) {
    // Remove existing .pdf extension and add it properly
    String nameWithoutExt = fileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');

    return nameWithoutExt
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '') // Remove invalid file name characters
        .replaceAll(RegExp(r'\s+'), ' ') // Replace multiple spaces with single space
        .trim() + ".pdf";
  }

  Future<void> _openDownloadedFile(String filePath, String fileName) async {
    try {
      debugPrint("Opening file: $filePath");

      final result = await OpenFile.open(filePath);

      switch (result.type) {
        case ResultType.done:
          debugPrint("✅ File opened successfully");
          break;
        case ResultType.noAppToOpen:
          _showNoAppDialog(filePath, fileName);
          break;
        case ResultType.fileNotFound:
          Fluttertoast.showToast(msg: "File not found. Please download again.");
          break;
        case ResultType.permissionDenied:
          _showNoAppDialog(filePath, fileName);
          break;
        case ResultType.error:
          _showNoAppDialog(filePath, fileName);
          break;
      }
    } catch (e) {
      debugPrint("❌ Error opening file: $e");
      _showNoAppDialog(filePath, fileName);
    }
  }

  void _showNoAppDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("No PDF Viewer"),
        content: const Text("No PDF viewer app found on your device. Please install a PDF reader app to view the file."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Download Progress Widget
  Widget _buildDownloadProgress() {
    if (!_isDownloading) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.download, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Downloading PDF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    Text(
                      _currentDownloadFileName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _downloadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              _downloadProgress == 1.0 ? Colors.green : Colors.blue,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_downloadProgress * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
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
        body: Stack(
          children: [
            Padding(
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

            // Download progress overlay
            if (_isDownloading)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: _buildDownloadProgress(),
              ),
          ],
        ),
      ),
    );
  }

  bool _isButtonEnabled(TeacherDashboardProvider provider) {
    switch (step) {
      case 1:
        return provider.pblLanguageId != 0 && provider.boardId != 0;
      case 2:
        return provider.subjectId != 0 && provider.gradeId != 0; // Both must be selected
      default:
        return false;
    }
  }
  Widget _buildStepContent(TeacherDashboardProvider provider) {
    switch (step) {
      case 1:
        return _buildPblLanguageBoardStep(provider);
      case 2:
        return _buildCombinedSubjectGradeStep(provider); // Combined step
      case 4:
        return _buildPdfStep(provider);
      case 99:
        return _buildNoDataStep();
      default:
        return const SizedBox();
    }
  }  // The rest of your UI methods remain exactly the same...
  Widget _buildPblLanguageBoardStep(TeacherDashboardProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
            "Select PBL Language & Board",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 20),

        // PBL Language Dropdown
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showPblLanguageDropdown(context, provider),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "PBL Language",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.pblSelectedLanguage.isNotEmpty ? provider.pblSelectedLanguage : "Select PBL Language",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Board Dropdown
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => _showBoardDropdown(context, provider),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Board",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.board.isNotEmpty ? provider.board : "Select Board",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPblLanguageDropdown(BuildContext context, TeacherDashboardProvider provider) {
    final pblLanguages = List.from(provider.availablePblLanguages);

    if (provider.pblLanguageId != null) {
      pblLanguages.sort((a, b) {
        if (a.pblLangId == provider.pblLanguageId) return -1;
        if (b.pblLangId == provider.pblLanguageId) return 1;
        return 0;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select PBL Language",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // List Body
            Expanded(
              child: pblLanguages.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.language, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      "No PBL languages available",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: pblLanguages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final language = pblLanguages[index];
                  final isSelected = provider.pblLanguageId == language.pblLangId;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1).withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                        color: const Color(0xFF6366F1),
                        width: 1.5,
                      )
                          : null,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Icon(
                        Icons.language,
                        color: isSelected
                            ? const Color(0xFF6366F1)
                            : Colors.grey[600],
                      ),
                      title: Text(
                        language.pblLangTitle ?? language.pblLangName ?? 'Unknown Language',
                        style: TextStyle(
                          fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFF6366F1)
                              : Colors.black87,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFF6366F1))
                          : null,
                      onTap: () {
                        provider.setPblLanguage(
                          language.pblLangId ?? 0,
                          language.pblLangTitle ?? language.pblLangName ?? '',
                        );
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBoardDropdown(BuildContext context, TeacherDashboardProvider provider) {
    final boards = provider.availableBoards;
    List<Board> filteredBoards = List.from(boards);
    TextEditingController searchController = TextEditingController();

    if (provider.boardId != null) {
      boards.sort((a, b) {
        if (a.id == provider.boardId) return -1;
        if (b.id == provider.boardId) return 1;
        return 0;
      });
      filteredBoards = List.from(boards);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Board",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: "Search board...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      filteredBoards = boards.where((board) {
                        final boardName = board.name?.toLowerCase() ?? '';
                        return boardName.contains(value.toLowerCase());
                      }).toList();
                    });
                  },
                ),
              ),

              Expanded(
                child: filteredBoards.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.school, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "No boards found",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBoards.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final board = filteredBoards[index];
                    final isSelected = provider.boardId == board.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10B981).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: const Color(0xFF10B981), width: 1.5)
                            : null,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Icon(
                          Icons.school,
                          color: isSelected ? const Color(0xFF10B981) : Colors.grey[600],
                        ),
                        title: Text(
                          board.name ?? 'Unknown Board',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF10B981) : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                            : null,
                        onTap: () {
                          provider.setSelectedBoard(board.id ?? 0, board.name ?? '');
                          Navigator.pop(context);
                        },
                      ),
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

  Widget _buildCombinedSubjectGradeStep(TeacherDashboardProvider provider) {
    // Use subjectGradePairsWithPdf directly since it already contains unique combinations
    final combinedPairs = provider.subjectGradePairsWithPdf;

    if (combinedPairs.isEmpty) return _buildNoDataStep();

    // Debug print to see what we're displaying
    debugPrint("Displaying ${combinedPairs.length} unique combinations:");
    for (final pair in combinedPairs) {
      debugPrint(" - ${pair.grade?.name} - ${pair.subject?.title}");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
            "Select Subject & Grade",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: combinedPairs.length,
            itemBuilder: (context, index) {
              final pair = combinedPairs[index];
              final isSelected = provider.subjectId == pair.subject?.id &&
                  provider.gradeId == pair.grade?.id;
              final subjectName = pair.subject?.title ?? 'Unknown Subject';
              final gradeName = pair.grade?.name ?? 'Unknown Grade';
              final displayText = '$gradeName - $subjectName';

              return InkWell(
                onTap: () {
                  provider.subjectId = pair.subject?.id ?? 0;
                  provider.gradeId = pair.grade?.id ?? 0;
                  provider.notifyListeners();

                  // Debug print to confirm selection
                  debugPrint("Selected: $displayText (Subject ID: ${pair.subject?.id}, Grade ID: ${pair.grade?.id})");
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 2
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayText,
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? Colors.blue : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.blue),
                    ],
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
    if (pdfs.isEmpty) return _buildNoDataStep();

    // Get subject and grade names safely
    String subjectName = '';
    String gradeName = '';

    if (provider.subjectGradePairsWithPdf.isNotEmpty) {
      final subjectPair = provider.subjectGradePairsWithPdf.firstWhere(
            (p) => p.subject?.id == provider.subjectId,
        orElse: () => provider.subjectGradePairsWithPdf.first,
      );
      subjectName = subjectPair.subject?.title ?? '';

      final gradePair = provider.subjectGradePairsWithPdf.firstWhere(
            (p) => p.grade?.id == provider.gradeId,
        orElse: () => provider.subjectGradePairsWithPdf.first,
      );
      gradeName = gradePair.grade?.name ?? '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
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
                        offset: const Offset(0, 4)
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  title: Text(
                      pdf.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                  subtitle: Text(
                      pdf.document.name,
                      style: const TextStyle(fontSize: 14, color: Colors.grey)
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfPage(
                                  url: ApiHelper.imgBaseUrl + pdf.document.url,
                                  name: pdf.document.name
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.green),
                        onPressed: () => _downloadPdf(
                            ApiHelper.imgBaseUrl + pdf.document.url,
                            pdf.document.name
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataStep() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No PDFs available for the selected criteria",
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Try selecting a different board, language, or subject",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}