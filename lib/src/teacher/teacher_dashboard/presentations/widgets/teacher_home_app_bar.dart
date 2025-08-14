import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/teacher/teacher_profile/presentations/pages/teacher_profile_page.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
class TeacherHomeAppBar extends StatelessWidget {
  final String name;
  final String? img;

  const TeacherHomeAppBar({
    required this.name,
    required this.img,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    String? finalImageUrl;

    if (img != null && img!.isNotEmpty) {
      final base = ApiHelper.imgBaseUrl.endsWith('/')
          ? ApiHelper.imgBaseUrl
          : '${ApiHelper.imgBaseUrl}/';

      final path = img!.startsWith('/')
          ? img!.substring(1)
          : img!;

      finalImageUrl = img!.startsWith('http') ? img : '$base$path';
    }


    debugPrint('👤 Final Profile Image URL: $finalImageUrl');

    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Row(
          children: [
            // Drawer icon
            InkWell(
              onTap: () {
                MixpanelService.track("Menu icon clicked", properties: {
                  "timestamp": DateTime.now().toIso8601String(),
                });
                Scaffold.of(context).openDrawer();
              },
              child: Image.asset(
                ImageHelper.drawerIcon,
                height: 40,
              ),
            ),
            const SizedBox(width: 15),

            // Greeting text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  StringHelper.lifeApp,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    const Text(
                      "Hello! ",
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),

            const Spacer(),

            // Profile image with fallback
            InkWell(
              onTap: () {
                MixpanelService.track("Profile icon clicked", properties: {
                  "timestamp": DateTime.now().toIso8601String(),
                });
                PersistentNavBarNavigator.pushNewScreen(
                  context,
                  screen: const TeacherProfilePage(),
                  withNavBar: false,
                );
              },
              child: _ProfileImageWithFallback(imageUrl: finalImageUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileImageWithFallback extends StatefulWidget {
  final String? imageUrl;
  final double size;

  const _ProfileImageWithFallback({
    required this.imageUrl,
    this.size = 50,
    Key? key,
  }) : super(key: key);

  @override
  State<_ProfileImageWithFallback> createState() => _ProfileImageWithFallbackState();
}

class _ProfileImageWithFallbackState extends State<_ProfileImageWithFallback> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl != null && !_hasError) {
      return ClipOval(
        child: Image.network(
          widget.imageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _hasError = true);
              }
            });
            return _fallbackImage(widget.size);
          },
          loadingBuilder: (_, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
        ),
      );
    } else {
      return _fallbackImage(widget.size);
    }
  }

  Widget _fallbackImage(double size) {
    return CircleAvatar(
      radius: size / 2,
      backgroundImage: const AssetImage(ImageHelper.profileImg),
    );
  }
}

