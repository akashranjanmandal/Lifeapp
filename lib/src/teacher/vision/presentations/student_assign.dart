import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vision_model.dart';
import '../providers/vision_provider.dart';
import 'assignment_success.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';

class StudentAssignPage extends StatefulWidget {
  final String videoTitle;
  final String videoId;
  final String gradeId;
  final String subjectId;
  final String sectionId;
  final String classId;

  const StudentAssignPage({
    Key? key,
    required this.videoTitle,
    required this.videoId,
    required this.gradeId,
    required this.subjectId,
    required this.sectionId,
    required this.classId,
  }) : super(key: key);

  @override
  State<StudentAssignPage> createState() => _StudentAssignPageState();
}

class _StudentAssignPageState extends State<StudentAssignPage> {
  List<Map<String, dynamic>> _students = [];
  List<bool> _selectedStudents = [];
  bool _selectAll = true;
  DateTime? _dueDate;
  bool _isLoading = false;
  String? _errorMessage;
  late DateTime _pageOpenTime;

  // Grade dropdown state
  String? _selectedGradeId;
  String? _selectedGradeName;
  List<Map<String, dynamic>> _teacherGrades = [];
  bool _hasAssignedGrades = true;

  @override
  void initState() {
    super.initState();
    _pageOpenTime = DateTime.now();
    debugPrint('🎬 StudentAssignPage initialized with:');
    debugPrint('   - videoId: ${widget.videoId}');
    debugPrint('   - videoTitle: ${widget.videoTitle}');
    debugPrint('   - sectionId: ${widget.sectionId}');
    debugPrint('   - gradeId: ${widget.gradeId}');
    debugPrint('   - subjectId: ${widget.subjectId}');

    MixpanelService.track("AssignVisionScreen_View", properties: {
      "video_id": widget.videoId,
      "video_title": widget.videoTitle,
      "grade_id": widget.gradeId,
      "subject_id": widget.subjectId,
      "section_id": widget.sectionId,
      "class_id": widget.classId,
    });

    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkTeacherGrades();
  }

  Future<void> _checkTeacherGrades() async {
    try {
      final toolProvider = Provider.of<ToolProvider>(context, listen: false);

      if (toolProvider.teacherGradeSectionModel == null) {
        toolProvider.getTeacherGrade();
        await Future.delayed(const Duration(milliseconds: 800));
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (toolProvider.teacherGradeSectionModel != null &&
          toolProvider.teacherGradeSectionModel!.data != null &&
          toolProvider.teacherGradeSectionModel!.data!.teacherGrades != null) {

        final grades = toolProvider.teacherGradeSectionModel!.data!.teacherGrades!;

        setState(() {
          _hasAssignedGrades = grades.isNotEmpty;
          _teacherGrades = grades.map((gradeSection) {
            return {
              'id': gradeSection.grade?.id?.toString() ?? '',
              'name': 'Class ${gradeSection.grade?.name ?? ''} ${gradeSection.section?.name ?? ''}',
              'grade_name': gradeSection.grade?.name ?? '',
              'section_name': gradeSection.section?.name ?? '',
              'section_id': gradeSection.section?.id?.toString() ?? '',
              'class_id': gradeSection.id?.toString() ?? '',
            };
          }).toList();
        });

        debugPrint('📊 Teacher grades check:');
        debugPrint('   - Has assigned grades: $_hasAssignedGrades');
        debugPrint('   - Number of grades: ${_teacherGrades.length}');
        debugPrint('   - Widget gradeId: "${widget.gradeId}"');
        debugPrint('   - Widget sectionId: "${widget.sectionId}"');

        // Set initial selection - TRY TO MATCH THE GRADE USER CAME FROM
        if (_teacherGrades.isNotEmpty) {
          _setInitialGradeSelection();

          // Now fetch students with the selected grade
          await _fetchStudents();
        } else {
          debugPrint('❌ No teacher grades available');
          setState(() {
            _errorMessage = 'No grades/classes assigned to this teacher.';
          });
        }
      } else {
        debugPrint('❌ Teacher grades data is null');
        setState(() {
          _hasAssignedGrades = false;
          _errorMessage = 'Unable to load teacher grades. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('❌ Error checking teacher grades: $e');
      setState(() {
        _hasAssignedGrades = false;
        _errorMessage = 'Error loading teacher information: $e';
      });
    }
  }

  void _setInitialGradeSelection() {
    // Try to find the grade that matches the one user came from
    Map<String, dynamic>? matchingGrade;

    if (widget.gradeId.isNotEmpty && widget.sectionId.isNotEmpty) {
      // Try exact match with both gradeId and sectionId
      try {
        matchingGrade = _teacherGrades.firstWhere(
              (grade) => grade['id'] == widget.gradeId && grade['section_id'] == widget.sectionId,
        );
        debugPrint('✅ Found exact match with gradeId and sectionId');
      } catch (e) {
        debugPrint('ℹ️ No exact match found, trying gradeId only');
        try {
          matchingGrade = _teacherGrades.firstWhere(
                (grade) => grade['id'] == widget.gradeId,
          );
          debugPrint('✅ Found match with gradeId only');
        } catch (e) {
          debugPrint('ℹ️ No match found, using first grade');
          matchingGrade = _teacherGrades.first;
        }
      }
    } else if (widget.gradeId.isNotEmpty) {
      // Try match with just gradeId
      try {
        matchingGrade = _teacherGrades.firstWhere(
              (grade) => grade['id'] == widget.gradeId,
        );
        debugPrint('✅ Found match with gradeId only');
      } catch (e) {
        debugPrint('ℹ️ No match found with gradeId, using first grade');
        matchingGrade = _teacherGrades.first;
      }
    } else {
      // Fallback to first grade
      matchingGrade = _teacherGrades.first;
      debugPrint('ℹ️ Using first grade as fallback');
    }

    _selectedGradeId = matchingGrade['id'];
    _selectedGradeName = matchingGrade['name'];

    debugPrint('🎯 Initial grade selection:');
    debugPrint('   - Selected: $_selectedGradeId - $_selectedGradeName');
    debugPrint('   - User came from grade: ${widget.gradeId}');
    debugPrint('   - User came from section: ${widget.sectionId}');
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('🔍 === FETCH STUDENTS DEBUG ===');
      debugPrint('   - Selected gradeId: "$_selectedGradeId"');
      debugPrint('   - Selected sectionId: "$_selectedSectionId"');

      String? effectiveGradeId;
      String? effectiveSectionId;

      if (_selectedGradeId != null && _selectedGradeId!.isNotEmpty) {
        try {
          Map<String, dynamic> selectedGrade = _teacherGrades.firstWhere(
                (grade) => grade['id'] == _selectedGradeId,
          );
          effectiveGradeId = selectedGrade['id'];
          effectiveSectionId = selectedGrade['section_id'];

          debugPrint('   - Using SELECTED grade from dropdown:');
          debugPrint('     - Grade ID: $effectiveGradeId');
          debugPrint('     - Section ID: $effectiveSectionId');
        } catch (e) {
          debugPrint('❌ Selected grade not found, using first grade');
          final firstGrade = _teacherGrades.first;
          effectiveGradeId = firstGrade['id'];
          effectiveSectionId = firstGrade['section_id'];
          _selectedGradeId = firstGrade['id'];
          _selectedGradeName = firstGrade['name'];
        }
      } else if (_teacherGrades.isNotEmpty) {
        final firstGrade = _teacherGrades.first;
        effectiveGradeId = firstGrade['id'];
        effectiveSectionId = firstGrade['section_id'];
        _selectedGradeId = firstGrade['id'];
        _selectedGradeName = firstGrade['name'];

        debugPrint('   - Using FIRST grade as fallback:');
        debugPrint('     - Grade ID: $effectiveGradeId');
        debugPrint('     - Section ID: $effectiveSectionId');
      } else {
        debugPrint('❌ No grades available at all');
        setState(() {
          _errorMessage = 'No grades/classes available. Please contact support.';
          _isLoading = false;
        });
        return;
      }

      if (effectiveSectionId == null || effectiveSectionId.isEmpty) {
        debugPrint('❌ Section ID validation failed');
        setState(() {
          _errorMessage = 'Section information is missing. Please select a different grade.';
          _isLoading = false;
        });
        return;
      }

      final provider = Provider.of<TeacherVisionProvider>(context, listen: false);
      final teacherProvider = Provider.of<TeacherDashboardProvider>(context, listen: false);

      debugPrint('🏫 Getting school information...');
      final schoolId = teacherProvider.dashboardModel?.data?.user?.school?.id;
      debugPrint('   - schoolId: $schoolId');

      if (schoolId == null || schoolId == 0) {
        debugPrint('❌ School ID validation failed');
        setState(() {
          _errorMessage = 'School information is not available. Please refresh the dashboard and try again.';
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> data = {
        "school_id": schoolId,
        "la_section_id": effectiveSectionId,
      };

      if (effectiveGradeId != null && effectiveGradeId.isNotEmpty) {
        data["la_grade_id"] = effectiveGradeId;
        debugPrint('   - Added gradeId: $effectiveGradeId');
      }

      if (widget.subjectId.isNotEmpty) {
        data["la_subject_id"] = widget.subjectId;
        debugPrint('   - Added subjectId: ${widget.subjectId}');
      }

      debugPrint('📤 Sending data to API: $data');

      _students = await provider.getStudentsForAssignment(data);
      _selectedStudents = List.filled(_students.length, true);

      debugPrint('✅ Fetched ${_students.length} students for assignment');

      if (_students.isEmpty) {
        setState(() {
          _errorMessage = 'No students found for the selected section. Please check if students are enrolled in this section.';
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching students: $e');
      setState(() {
        _errorMessage = 'Failed to load students: ${e.toString()}. Please check your internet connection and try again.';
        _students = [];
        _selectedStudents = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String? get _selectedSectionId {
    if (_selectedGradeId == null) return null;
    try {
      final selectedGrade = _teacherGrades.firstWhere(
            (grade) => grade['id'] == _selectedGradeId,
      );
      return selectedGrade['section_id']?.toString();
    } catch (e) {
      debugPrint('❌ Error getting section ID: $e');
      if (_teacherGrades.isNotEmpty) {
        return _teacherGrades.first['section_id']?.toString();
      }
      return null;
    }
  }

  // IMPROVED Grade dropdown widget with better UI
  Widget _buildGradeDropdown() {
    if (_teacherGrades.isEmpty || _teacherGrades.length == 1) {
      // Don't show dropdown if only one grade or none
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.class_, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                "Select Class",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGradeId,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
                iconSize: 24,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(8),
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Choose a class'),
                ),
                items: _teacherGrades.map((grade) {
                  return DropdownMenuItem<String>(
                    value: grade['id'],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        grade['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedGradeId = newValue;
                      _selectedGradeName = _teacherGrades
                          .firstWhere((grade) => grade['id'] == newValue)['name'];
                    });

                    _fetchStudents();

                    MixpanelService.track("AssignVision_GradeSelected", properties: {
                      "video_id": widget.videoId,
                      "grade_id": newValue,
                      "grade_name": _selectedGradeName,
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      for (int i = 0; i < _selectedStudents.length; i++) {
        _selectedStudents[i] = _selectAll;
      }
    });
    MixpanelService.track(_selectAll ? "AssignVision_SelectAllClicked" : "AssignVision_DeselectAllClicked", properties: {
      "video_id": widget.videoId,
      "selected_count": _selectedStudents.where((selected) => selected).length,
    });
  }

  Future<void> _selectDueDate() async {
    MixpanelService.track("AssignVision_SetDueDateButtonClicked", properties: {
      "video_id": widget.videoId,
    });
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
      MixpanelService.track("AssignVision_DueDateSet", properties: {
        "video_id": widget.videoId,
        "due_date": picked.toIso8601String(),
      });
    }
  }

  // IMPROVED Student tile with better UI
  Widget _buildStudentTile(String name, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue[50],
            ),
            child: Icon(
              Icons.person,
              color: Colors.blue[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedStudents[index] = !_selectedStudents[index];
              });
              MixpanelService.track("AssignVision_StudentSelectToggled", properties: {
                "video_id": widget.videoId,
                "student_id": _students[index]['id'].toString(),
                "selected": _selectedStudents[index],
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _selectedStudents[index] ? Colors.green : Colors.transparent,
                border: Border.all(
                  color: _selectedStudents[index] ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _selectedStudents[index]
                  ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.orange[600],
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Students',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _fetchStudents,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignVideoToStudents() async {
    final selectedStudentIds = <String>[];
    for (int i = 0; i < _selectedStudents.length; i++) {
      if (_selectedStudents[i]) {
        selectedStudentIds.add(_students[i]['id'].toString());
      }
    }

    if (selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one student.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a due date before assigning the vision.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    MixpanelService.track("AssignVision_AssignButtonClicked", properties: {
      "video_id": widget.videoId,
      "selected_student_count": selectedStudentIds.length,
      "due_date": _dueDate!.toIso8601String(),
      "grade_id": _selectedGradeId,
    });

    debugPrint('📝 Assigning video to ${selectedStudentIds.length} students');
    debugPrint('   - Selected student IDs: $selectedStudentIds');
    debugPrint('   - Due date: ${_dueDate?.toIso8601String()}');
    debugPrint('   - Grade ID: $_selectedGradeId');

    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<TeacherVisionProvider>(context, listen: false);

      final success = await provider.assignVideoToStudents(
        widget.videoId,
        selectedStudentIds,
        dueDate: _dueDate!.toIso8601String(),
      );

      if (success) {
        final provider = Provider.of<TeacherVisionProvider>(context, listen: false);
        final video = provider.getVideoById(widget.videoId);

        if (video == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Video details not found.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssignmentSuccessScreen(
              assignedCount: selectedStudentIds.length,
              visionVideo: video,
            ),
          ),
        );
      }
      else {
        debugPrint('❌ Assignment failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error assigning video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error assigning video: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          MixpanelService.track("AssignVision_BackIconClicked", properties: {
                            "video_id": widget.videoId,
                          });
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Assign Vision",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (_students.isNotEmpty)
                    GestureDetector(
                      onTap: _toggleSelectAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Text(
                          _selectAll ? "Deselect all" : "Select all",
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Grade Dropdown (only show when multiple grades available)
              _buildGradeDropdown(),

              // Show loading while initializing
              if (_teacherGrades.isEmpty && _isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading grades...'),
                    ],
                  ),
                ),

              // Video title being assigned
              if (widget.videoTitle.isNotEmpty && _teacherGrades.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.video_library, size: 18, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            "Assigning Video:",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.videoTitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.blue[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              // Student list or error
              Expanded(
                child: _errorMessage != null
                    ? _buildErrorWidget()
                    : _isLoading && _students.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading students...'),
                    ],
                  ),
                )
                    : _students.isEmpty && _teacherGrades.isNotEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No students found for selected class',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchStudents,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
                    : _students.isNotEmpty
                    ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.people, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Students (${_students.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _students.length,
                        itemBuilder: (context, index) => _buildStudentTile(
                          _students[index]['name'] ?? 'Student ${index + 1}',
                          index,
                        ),
                      ),
                    ),
                  ],
                )
                    : const Center(
                  child: Text('Select a class to view students'),
                ),
              ),

              // Buttons - only show if we have students
              if (_students.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectDueDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          _dueDate == null
                              ? 'Set Due Date'
                              : 'Due: ${_dueDate!.toLocal()}'.split(' ')[0],
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _assignVideoToStudents,
                        icon: _isLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Icon(Icons.assignment_turned_in, size: 18),
                        label: Text(
                          _isLoading ? 'Assigning...' : 'Assign Video',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}