import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
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
      setState(() {});
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
            '🔹 Compression attempt quality=$quality → size=${(sizeInBytes / 1024).toStringAsFixed(2)} KB');

        if (sizeInBytes <= 500 * 1024) {
          return compressedFile;
        }

        quality -= 10;
      }

      // Return the last compressed file anyway (even if > 500 KB)
      return compressedXFile != null ? File(compressedXFile.path) : null;
    } catch (e) {
      debugPrint('⚠️ Compression error: $e');
      return null;
    }
  }

  void _loadPicker(ImageSource source) async {
    try {
      final XFile? picked = await ImagePicker().pickImage(source: source, imageQuality: 100);
      if (picked == null) {
        Fluttertoast.showToast(msg: "Please select image");
        return;
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Colors.deepPurple,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      // Use cropped path if cropping done, else original picked path
      final File fileToCompress = File(cropped?.path ?? picked.path);

      final File? compressedFile = await _compressImage(fileToCompress);

      if (compressedFile == null) {
        Fluttertoast.showToast(msg: "Failed to compress image");
        return;
      }

      setState(() {
        imgUrl = compressedFile.path;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to pick or compress image");
      debugPrint('⚠️ _loadPicker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        timer.cancel();
        _cancelPopup(widget.mission?.level?.missionPoints ?? 0);
        return false;
      },
      child: Scaffold(
        appBar: commonAppBar(
          context: context,
          name: "Skip",
          onBack: () {
            timer.cancel();
            _cancelPopup(widget.mission?.level?.missionPoints ?? 0);
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
      debugPrint("Index $i");
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
          const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 15),
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
              SizedBox(
                width: MediaQuery.of(context).size.width * .5,
                child: const Text(
                  "Perform the activity to earn Coins!",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                  ),
                  softWrap: true,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                widget.mission.question!,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                softWrap: true,
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  _cameraOption();
                },
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 2,
                        ),
                        color: const Color(0xffadadad).withOpacity(.5)),
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
                            "tap to upload Picture",
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
                      Fluttertoast.showToast(msg: "Please add picture");
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

  _cameraOption() => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        color: Colors.white,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upload a photo",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 30),
          InkWell(
            onTap: () {
              Navigator.pop(context);
              MixpanelService.track("Upload Picture Button Clicked");
              _loadPicker(ImageSource.camera);
            },
            child: Row(
              children: [
                Image.asset(
                  "assets/images/Camera.png",
                  color: ColorCode.buttonColor,
                  height: 35,
                  width: 35,
                ),
                const SizedBox(width: 15),
                const Text(
                  "Take a photo",
                  style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                      fontWeight: FontWeight.w600),
                )
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    ),
  );

  _cancelPopup(int coins) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    isScrollControlled: true, // allows modal to take more height if needed
    builder: (ctx) => SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // max 70% of screen
        ),
        margin: const EdgeInsets.only(bottom: 20, top: 20),
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).size.height * 0.035,
                  left: 20,
                  right: 20,
                  top: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // important to avoid overflow
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
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
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
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
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // "I'll Stay" button
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx); // Close popup
                          },
                          child: Container(
                            alignment: Alignment.center,
                            height: 50,
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
                      // "Skip Anyway" button
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(ctx); // Close popup first

                            bool skipped = await Provider.of<MissionProvider>(context, listen: false)
                                .skipMission(context, widget.mission.id!);

                            if (skipped) {
                              // Pop this page and return true so the previous page can refresh
                              Navigator.pop(context, true);
                            }
                          },
                          child: Container(
                            alignment: Alignment.center,
                            height: 50,
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}