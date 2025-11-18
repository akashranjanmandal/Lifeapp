import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class FilterPage extends StatefulWidget {
  final Function(Map<String, bool>) onApplyFilters;
  final Map<String, bool> initialFilters;

  const FilterPage({
    Key? key,
    required this.onApplyFilters,
    required this.initialFilters,
  }) : super(key: key);

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  bool allFilter = false;
  bool teacherAssignedFilter = false;
  bool skippedFilter = false;
  bool pendingFilter = false;
  bool completedFilter = false;
  bool submittedFilter = false;

  @override
  void initState() {
    super.initState();
    MixpanelService.track("Vision Filter Page Opened");
    allFilter = widget.initialFilters['all'] ?? false;
    teacherAssignedFilter = widget.initialFilters['teacher_assigned'] ?? false;
    skippedFilter = widget.initialFilters['skipped'] ?? false;
    pendingFilter = widget.initialFilters['pending'] ?? false;
    completedFilter = widget.initialFilters['completed'] ?? false;
    submittedFilter = widget.initialFilters['submitted'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            MixpanelService.track("Vision Filter Back Button Clicked");
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Vision Filters',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters title
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Filters',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          // Filter options
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildFilterOption('All', allFilter, (value) {
                  setState(() {
                    allFilter = value;
                    // If "All" is selected, deselect others
                    if (value) {
                      teacherAssignedFilter = false;
                      skippedFilter = false;
                      pendingFilter = false;
                      completedFilter = false;
                      submittedFilter = false;
                    }
                  });
                }),
                const Divider(height: 1),
                _buildFilterOption('Teacher Assigned', teacherAssignedFilter, (value) {
                  setState(() {
                    teacherAssignedFilter = value;
                    if (value) allFilter = false;
                  });
                }),
                const Divider(height: 1),
                _buildFilterOption('Skipped', skippedFilter, (value) {
                  setState(() {
                    skippedFilter = value;
                    if (value) allFilter = false;
                  });
                }),
                const Divider(height: 1),
                _buildFilterOption('Pending', pendingFilter, (value) {
                  setState(() {
                    pendingFilter = value;
                    if (value) allFilter = false;
                  });
                }),
                const Divider(height: 1),
                _buildFilterOption('Completed', completedFilter, (value) {
                  setState(() {
                    completedFilter = value;
                    if (value) allFilter = false;
                  });
                }),
                const Divider(height: 1),
                _buildFilterOption('Submitted', submittedFilter, (value) {
                  setState(() {
                    submittedFilter = value;
                    if (value) allFilter = false;
                  });
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                // Reset button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resetFilters,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.blue.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                // Submit button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue.shade500,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {
              MixpanelService.track("Vision Filter Toggled", properties: {
                "filter_name": title,
                "is_enabled": val,
              });
              onChanged(val);
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _resetFilters() {
    MixpanelService.track("Vision Filter Reset Button Clicked");
    setState(() {
      allFilter = false;
      teacherAssignedFilter = false;
      skippedFilter = false;
      pendingFilter = false;
      completedFilter = false;
      submittedFilter = false;
    });
  }

  void _applyFilters() {
    // Create a map of the current filter states
    final filters = {
      'all': allFilter,
      'teacher_assigned': teacherAssignedFilter,
      'skipped': skippedFilter,
      'pending': pendingFilter,
      'completed': completedFilter,
      'submitted': submittedFilter,
    };

    MixpanelService.track("Vision Filter Submit Button Clicked", properties: filters);

    // Pass filters back to parent
    widget.onApplyFilters(filters);

    // Close the filter page
    Navigator.of(context).pop(filters);
  }
}