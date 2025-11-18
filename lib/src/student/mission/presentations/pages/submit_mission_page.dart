import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifelab3/src/common/helper/api_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/student/mission/provider/mission_provider.dart';
import 'package:lifelab3/src/student/subject_level_list/models/mission_list_model.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../../common/helper/color_code.dart';
import '../../../../common/widgets/custom_button.dart';
import '../../../../common/widgets/custom_text_field.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

class SubmitMissionPage extends StatefulWidget {
  final MissionDatum mission;

  const SubmitMissionPage({super.key, required this.mission});

  @override
  State<SubmitMissionPage> createState() => _SubmitMissionPageState();
}

class _SubmitMissionPageState extends State<SubmitMissionPage> {
  final TextEditingController _descController = TextEditingController();

  int time = 0;
  String? imgUrl;
  bool isSubmitView = false;
  late Timer timer;

  @override
  void initState() {
    super.initState();
    startTime();
  }

  @override
  void dispose() {
    timer.cancel();
    _descController.dispose();
    super.dispose();
  }

  void startTime() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      time++;
      if (!mounted) timer.cancel();
    });
  }

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      int quality = 85;
      XFile? compressedXFile;

      while (quality >= 30) {
        compressedXFile = await FlutterImageCompress.compressAndGetFile(
          file.absolute.path,
          targetPath,
          quality: quality,
          minWidth: 1080,
          minHeight: 1080,
          format: CompressFormat.jpeg,
        );

        if (compressedXFile == null) return null;

        final compressedFile = File(compressedXFile.path);
        final sizeInBytes = await compressedFile.length();
        debugPrint(
            '🔹 Compression attempt quality=$quality → ${(sizeInBytes / 1024).toStringAsFixed(2)} KB');

        if (sizeInBytes <= 500 * 1024) return compressedFile;

        quality -= 10;
      }

      return compressedXFile != null ? File(compressedXFile.path) : null;
    } catch (e) {
      debugPrint('⚠️ Compression error: $e');
      return null;
    }
  }

  /// Only capture from camera — no gallery, no cropping.
  void _captureImage() async {
    try {
      final XFile? picked =
      await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 100);

      if (picked == null) {
        Fluttertoast.showToast(msg: "No image captured");
        return;
      }

      final File fileToCompress = File(picked.path);
      final File? compressedFile = await _compressImage(fileToCompress);

      if (compressedFile == null) {
        Fluttertoast.showToast(msg: "Failed to compress image");
        return;
      }

      setState(() {
        imgUrl = compressedFile.path;
      });

      MixpanelService.track("Camera Capture Successful");
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to capture image");
      debugPrint('⚠️ _captureImage error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        timer.cancel();
        _cancelPopup(widget.mission.level?.missionPoints ?? 0);
        return false;
      },
      child: Scaffold(
        appBar: commonAppBar(
          context: context,
          name: "Skip",
          onBack: () {
            timer.cancel();
            _cancelPopup(widget.mission.level?.missionPoints ?? 0);
          },
          action: !isSubmitView
              ? const Padding(
            padding: EdgeInsets.only(right: 15),
            child: Row(
              children: [
                Text(
                  "Swipe for next card",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: ColorCode.textBlackColor,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: ColorCode.textBlackColor,
                ),
              ],
            ),
          )
              : null,
        ),
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: isSubmitView ? _submitWidget() : _image(),
        ),
      ),
    );
  }

  Widget _image() => PageView.builder(
    onPageChanged: (i) {
      if (i == widget.mission.resources!.length) {
        setState(() {
          isSubmitView = true;
        });
      }
    },
    itemCount: widget.mission.resources!.length + 1,
    itemBuilder: (context, index) => index < widget.mission.resources!.length
        ? Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: PhotoView(
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                imageProvider: NetworkImage(
                  "${ApiHelper.imgBaseUrl}${widget.mission.resources![index].media!.url}",
                ),
              ),
            ),
          ),
        ),
      ],
    )
        : const SizedBox(),
  );

  Widget _submitWidget() => SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: 40),
    child: Stack(
      children: [
        Container(
          margin:
          const EdgeInsets.only(left: 15, right: 15, top: 20, bottom: 30),
          padding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                offset: const Offset(1.0, 1.0),
                blurRadius: 3.0,
                color: Colors.black45.withOpacity(0.3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Perform the activity to earn Coins!",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 30),
              Text(
                widget.mission.question ?? '',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: _captureImage,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 2,
                      ),
                      color: const Color(0xffadadad).withOpacity(.5),
                    ),
                    child: imgUrl == null
                        ? Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [
                          Image.asset(
                            "assets/images/upload_image_icon.png",
                            height: 80,
                            width: 80,
                          ),
                          const Text(
                            "Tap to capture Picture",
                            style: TextStyle(
                              color: ColorCode.buttonColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(imgUrl!),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomTextField(
                readOnly: false,
                color: Colors.white,
                maxLines: 5,
                hintName: "Add your description",
                fieldController: _descController,
              ),
              const SizedBox(height: 40),
              Center(
                child: CustomButton(
                  color: ColorCode.buttonColor,
                  name: StringHelper.submit,
                  height: 45,
                  width: double.infinity,
                  onTap: () async {
                    if (imgUrl == null) {
                      Fluttertoast.showToast(msg: "Please capture a photo");
                    } else {
                      timer.cancel();
                      Provider.of<MissionProvider>(context, listen: false)
                          .submitMission(context, {
                        "la_mission_id": widget.mission.id!,
                        "media": await MultipartFile.fromFile(imgUrl!),
                        "description": _descController.text,
                        "timing": time,
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Positioned(
          top: -10,
          right: 0,
          child: Image.asset(
            "assets/images/G4 1.png",
            height: 180,
            width: 180,
          ),
        ),
      ],
    ),
  );

  _cancelPopup(int coins) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (ctx) => SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        margin: const EdgeInsets.only(bottom: 20, top: 20),
        width: double.infinity,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Uh-oh!!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You're about to lose",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                "$coins coins",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Complete this challenge now to boost your balance and level up — your adventure awaits!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "I'll Stay",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        bool skipped =
                        await Provider.of<MissionProvider>(context,
                            listen: false)
                            .skipMission(context, widget.mission.id!);
                        if (skipped) Navigator.pop(context, true);
                      },
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          "Skip Anyway",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
