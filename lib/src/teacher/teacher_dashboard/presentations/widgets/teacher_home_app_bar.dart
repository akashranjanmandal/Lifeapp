import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/teacher/teacher_profile/presentations/pages/teacher_profile_page.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

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

    // Determine correct image URL
    if (img != null && img!.isNotEmpty) {
      if (!img!.contains('image_cropper_')) {
        finalImageUrl = img!.startsWith('http')
            ? img!
            : (ApiHelper.imgBaseUrl.endsWith('/') ? ApiHelper.imgBaseUrl : ApiHelper.imgBaseUrl + '/') + img!;
      }
    }

    print('👤 Final Profile Image URL: $finalImageUrl');

    return Builder(
      builder: (context) => Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Row(
          children: [
            // Drawer icon
            InkWell(
              onTap: () => Scaffold.of(context).openDrawer(),
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

            // Profile image with error fallback
            InkWell(
              onTap: () {
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

  const _ProfileImageWithFallback({this.imageUrl});

  @override
  State<_ProfileImageWithFallback> createState() => _ProfileImageWithFallbackState();
}

class _ProfileImageWithFallbackState extends State<_ProfileImageWithFallback> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl != null && !_hasError) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(widget.imageUrl!),
        onBackgroundImageError: (_, __) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _hasError = true;
              });
            }
          });
          print('❌ Failed to load image: ${widget.imageUrl}');
        },
      );
    } else {
      return const CircleAvatar(
        radius: 25,
        backgroundImage: AssetImage(ImageHelper.profileImg),
      );
    }
  }
}
