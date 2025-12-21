import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/common/widgets/loading_widget.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:lifelab3/src/teacher/teacher_tool/presentations/pages/project_page.dart';

class TeacherClassPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const TeacherClassPage({Key? key, this.onBackToHome}) : super(key: key);

  @override
  State<TeacherClassPage> createState() => _TeacherClassPageState();
}

class _TeacherClassPageState extends State<TeacherClassPage> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final provider = Provider.of<ToolProvider>(context, listen: false);

    // Clear previous error state
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    // Fetch data and handle errors
    provider.getTeacherGrade().catchError((error) {
      setState(() {
        _hasError = true;

        // Check if error is due to no internet
        if (error.toString().contains('SocketException') ||
            error.toString().contains('Network') ||
            error.toString().contains('Connection failed') ||
            error.toString().contains('timeout')) {
          _errorMessage = 'No internet connection';
        } else {
          _errorMessage = 'Failed to load classes. Please try again.';
        }
      });
    });

    provider.getLevel().catchError((error) {
      // Only show error if not already showing one
      if (!_hasError) {
        setState(() {
          _hasError = true;
          if (error.toString().contains('SocketException') ||
              error.toString().contains('Network') ||
              error.toString().contains('Connection failed') ||
              error.toString().contains('timeout')) {
            _errorMessage = 'No internet connection';
          } else {
            _errorMessage = 'Failed to load data. Please try again.';
          }
        });
      }
    });
  }

  // ================= ERROR STATE WIDGET =================
  Widget _buildErrorState() {
    final isNoInternet = _errorMessage.toLowerCase().contains('internet');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with red rounded border
            Container(
              width: 80,
              height: 80,
              child: Icon(
                isNoInternet ? Icons.wifi_off : Icons.error_outline,
                size: 80,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isNoInternet
                  ? 'Please check your internet connection and try again'
                  : 'Please try reloading the page',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= NO INTERNET INDICATOR (Banner Style) =================
  Widget _buildNoInternetBanner() {
    if (!_hasError || !_errorMessage.toLowerCase().contains('internet')) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade400,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Exclamation icon with red rounded border
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.red.shade300,
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No Internet Connection",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Please check your connection",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Retry button
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.red.shade700,
            ),
            onPressed: _fetchData,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ToolProvider>(context);

    return Scaffold(
      appBar: commonAppBar(
        context: context,
        name: "Your classroom",
        onBack: () {
          if (widget.onBackToHome != null) {
            widget.onBackToHome!();
          } else {
            Navigator.pop(context);
          }
        },
      ),
      body: Column(
        children: [
          // Show no internet banner at the top if there's an internet error
          if (_hasError && _errorMessage.toLowerCase().contains('internet'))
            _buildNoInternetBanner(),

          // Main content
          Expanded(
            child: _hasError
                ? _buildErrorState()
                : (provider.teacherGradeSectionModel != null
                ? ListView.builder(
              shrinkWrap: true,
              itemCount: provider.teacherGradeSectionModel!.data!.teacherGrades!.length,
              itemBuilder: (context, index) {
                final gradeSection = provider.teacherGradeSectionModel!.data!.teacherGrades![index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TeacherProjectPage(
                          name: "Class ${gradeSection.grade!.name!} ${gradeSection.section!.name!}",
                          gradeId: gradeSection.grade!.id!.toString(),
                          classId: gradeSection.id!.toString(),
                          sectionId: gradeSection.section!.id.toString(),
                        ),
                      ),
                    );
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.only(left: 15, right: 15, bottom: 20),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          offset: Offset(1, 1),
                          spreadRadius: 1,
                          blurRadius: 1,
                        )
                      ],
                    ),
                    child: Text(
                      "Class ${gradeSection.grade!.name!} ${gradeSection.section!.name!}",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            )
                : const LoadingWidget()),
          ),
        ],
      ),
    );
  }
}