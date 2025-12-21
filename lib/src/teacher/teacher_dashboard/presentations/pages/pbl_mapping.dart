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
import '../../model/pbl_loading_state.dart';

class PblTextBookMappingPage extends StatefulWidget {
  const PblTextBookMappingPage({super.key});

  @override
  State<PblTextBookMappingPage> createState() => _PblTextBookMappingPageState();
}

class _PblTextBookMappingPageState extends State<PblTextBookMappingPage> {
  int step = 1;
  bool _isLoading = false;
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
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);
    setState(() => _isLoading = true);
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
      // Directly load all PDFs after language/board selection
      _loadAllPdfs();
    }
  }
  Future<void> _loadAllPdfs() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final provider = Provider.of<TeacherDashboardProvider>(context, listen: false);

    try {
      // Get teacher's subject-grade pairs for reference only
      await provider.getTeacherSubjectGrade();

      // Load ALL PDFs WITHOUT subject/grade filters - ONLY board and language
      await provider.loadAllPblPdfs();

      if (provider.allPblPdfs.isEmpty) {
        debugPrint("❌ No PDFs available for selected board/language");
        _goToStep(99);
        return;
      }

      debugPrint("✅ Loaded ${provider.allPblPdfs.length} PDFs");

      // Go to PDF listing page
      _goToStep(2);

    } catch (e) {
      debugPrint("Error loading PDFs: $e");
      Fluttertoast.showToast(msg: "Failed to load PDFs");
      _goToStep(99);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
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
                  // In the Column children of the build method:
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildStepContent(provider),
                  ),

// Wrap the bottom button section with SafeArea
                  if (step < 2 && step != 99 && !_isLoading)
                    SafeArea(
                      top: false, // Don't add top padding
                      minimum: const EdgeInsets.all(16),
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
      default:
        return false;
    }
  }

  Widget _buildStepContent(TeacherDashboardProvider provider) {
    switch (step) {
      case 1:
        return _buildPblLanguageBoardStep(provider);
      case 2:
        return _buildPdfListingWithFilters(provider);
      case 99:
        return _buildNoDataStep();
      default:
        return const SizedBox();
    }
  }

  // ================= OLD UI STYLE - STEP 1 =================
  Widget _buildPblLanguageBoardStep(TeacherDashboardProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
            "Select PBL Language & Board",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 20),

        // PBL Language Dropdown (OLD STYLE)
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
            onTap: () => _showPblLanguageDropdownOldStyle(context, provider),
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

        // Board Dropdown (OLD STYLE)
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
            onTap: () => _showBoardDropdownOldStyle(context, provider),
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

  // ================= OLD STYLE DROPDOWNS =================
  void _showPblLanguageDropdownOldStyle(BuildContext context, TeacherDashboardProvider provider) {
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

  void _showBoardDropdownOldStyle(BuildContext context, TeacherDashboardProvider provider) {
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

  // ================= PDF LISTING WITH FILTERS (OLD UI STYLE) =================
  Widget _buildPdfListingWithFilters(TeacherDashboardProvider provider) {
    return Column(
      children: [
        // Filter dropdowns with OLD UI style
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildSubjectDropdown(provider),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGradeDropdown(provider),
              ),
            ],
          ),
        ),

        // PDF List with OLD UI style
        Expanded(
          child: _buildPdfList(provider),
        ),
      ],
    );
  }

// Get unique subjects that have PDFs
  Widget _buildSubjectDropdown(TeacherDashboardProvider provider) {
    // Show ALL subjects from the subject list
    final allSubjects = provider.allSubjects;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: provider.filterSubjectId == 0 ? null : provider.filterSubjectId,
          hint: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text("All Subjects"),
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<int>(
              value: 0,
              child: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text("All Subjects"),
              ),
            ),
            ...allSubjects.where((subject) => subject.id != null).map((subject) {
              return DropdownMenuItem<int>(
                value: subject.id!,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(subject.title ?? 'Unknown'),
                ),
              );
            }),
          ],
          onChanged: (value) {
            provider.setFilterSubjectId(value ?? 0);
          },
        ),
      ),
    );
  }

  Widget _buildGradeDropdown(TeacherDashboardProvider provider) {
    // Show ALL grades from the grade list
    final allGrades = provider.allGrades;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: provider.filterGradeId == 0 ? null : provider.filterGradeId,
          hint: const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text("All Grades"),
          ),
          isExpanded: true,
          items: [
            const DropdownMenuItem<int>(
              value: 0,
              child: Padding(
                padding: EdgeInsets.only(left: 12),
                child: Text("All Grades"),
              ),
            ),
            ...allGrades.where((grade) => grade.id != null).map((grade) {
              return DropdownMenuItem<int>(
                value: grade.id!,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(grade.name ?? 'Unknown'),
                ),
              );
            }),
          ],
          onChanged: (value) {
            provider.setFilterGradeId(value ?? 0);
          },
        ),
      ),
    );
  }

  Widget _buildPdfList(TeacherDashboardProvider provider) {
    // Show loading indicator
    if (provider.pblLoadingState == PblLoadingState.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Get filtered PDFs
    final filteredPdfs = provider.getFilteredPdfs();

    if (filteredPdfs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No PDFs found for selected filters",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              "Try selecting different filters or reset filters",
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      itemCount: filteredPdfs.length,
      itemBuilder: (context, index) {
        final pdf = filteredPdfs[index];
        final subjectGradeInfo = provider.getSubjectGradeInfoForPdf(pdf);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    pdf.document.name,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)
                ),
                if (subjectGradeInfo != null)
                  Text(
                    "${subjectGradeInfo.grade?.name ?? ''} - ${subjectGradeInfo.subject?.title ?? ''}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
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
            "Try selecting a different board or language",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}