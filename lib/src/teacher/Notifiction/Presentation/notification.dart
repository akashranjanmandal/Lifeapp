import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../Services/services.dart';
import '../models/models.dart';
import '../../teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';

class NotificationPage extends StatefulWidget {
  final String token;
  const NotificationPage({super.key, required this.token});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  Future<List<NotificationModel>>? _futureNotifications;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationsAndMarkRead();
  }

  void _loadNotificationsAndMarkRead() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final service = NotificationService(widget.token);

      // Call API to mark all notifications as read
      await service.clearNotifications();

      // Then fetch the updated notifications
      setState(() {
        _futureNotifications = service.fetchNotifications();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load notifications. Please try again.';
      });
    }
  }

  void _showMessageDialog(String title, String message, int index) async {
    final lowerMessage = message.toLowerCase();
    final urlRegex = RegExp(r'https?:\/\/[^\s]+');
    final isCouponNotification = urlRegex.hasMatch(message);
    final isAppUpdateNotification = lowerMessage.contains("update") ||
        lowerMessage.contains("new version");
    final isFromAdmin = lowerMessage.contains("admin");

    Widget iconWidget;
    if (isCouponNotification) {
      iconWidget = const Icon(Icons.card_giftcard_rounded,
          size: 60, color: Color(0xFF4A5EFF));
    } else if (isFromAdmin) {
      iconWidget = Image.asset("assets/images/addlogo.png", height: 60);
    } else {
      iconWidget = const Icon(Icons.notifications,
          size: 60, color: Color(0xFF4A5EFF));
    }

    final String dialogTitle = isCouponNotification ? "Congratulations!" : title;

    String _stripLinkFromMessage(String message) {
      final linkRegex = RegExp(r'https?:\/\/[^\s]+');
      return message.replaceAll(linkRegex, '').trim();
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      iconWidget,
                      const SizedBox(height: 16),
                      Text(
                        dialogTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!isCouponNotification)
                        Text(
                          _stripLinkFromMessage(message),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      if (isCouponNotification) _buildCouponHeader(message),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      if (isCouponNotification)
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A5EFF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              final urlRegExp = RegExp(r'(https?:\/\/[^\s]+)');
                              final match = urlRegExp.firstMatch(message);
                              if (match != null) {
                                try {
                                  await launchUrl(
                                    Uri.parse(match.group(0)!),
                                    mode: LaunchMode.externalApplication,
                                  );
                                } catch (e) {
                                  // Show error message if URL launch fails
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Could not open link. Please try again.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text(
                              "Redeem Now",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (isCouponNotification) const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A5EFF),
                            side: const BorderSide(color: Color(0xFF4A5EFF)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            "Close",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCouponHeader(String message) {
    final linkRegex = RegExp(r'https?:\/\/[^\s]+');
    final cleanMessage = message.replaceAll(linkRegex, '').trim();

    return Column(
      children: [
        const SizedBox(height: 8),
        Text(
          cleanMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
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

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                height: 40,
                width: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A5EFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notifications, color: Color(0xFF4A5EFF)),
                  );
                },
              ),
            ),
            title: Text(
              n.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _formatDate(n.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            trailing: ElevatedButton(
              onPressed: () => _showMessageDialog(n.title, n.message, index),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFF4A5EFF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text("View"),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
    } catch (e) {
      return 'Date unavailable';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          color: const Color(0xFFF4F6FA),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 20),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const TeacherDashboardPage()),
                      );
                    },
                  ),
                  const Text(
                    "Notifications",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_futureNotifications != null && !_hasError)
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 22),
                      onPressed: _loadNotificationsAndMarkRead,
                      tooltip: 'Refresh notifications',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A5EFF)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading notifications...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : _hasError
          ? _buildErrorState()
          : FutureBuilder<List<NotificationModel>>(
        future: _futureNotifications,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final notifications = snapshot.data!;
          return _buildNotificationList(notifications);
        },
      ),

    );
  }
}