import 'package:flutter/material.dart';
import 'package:lifelab3/src/common/helper/image_helper.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/widgets/common_appbar.dart';
import 'package:lifelab3/src/student/subject_level_list/presentation/pages/quiz_topic_list_page.dart';
import 'package:lifelab3/src/student/subject_level_list/provider/subject_level_provider.dart';
import 'package:provider/provider.dart';

import '../../../../common/widgets/common_navigator.dart';
import '../../../mission/presentations/pages/mission_page.dart';
import '../../../puzzle/presentations/pages/puzzle_page.dart';
import '../../../vision/presentations/vision_page.dart';
import '../widgets/level_mission_widget.dart';
import '../widgets/level_vision_widget.dart';
import '../widgets/level_puzzles_widget.dart';
import '../widgets/level_quiz_widget.dart';
import '../widgets/level_subscribe_widget.dart';

class LevelChallengePage extends StatefulWidget {
  final String levelName;
  final String levelId;
  final String subjectId;
  final String navName;

  const LevelChallengePage({
    super.key,
    required this.levelName,
    required this.levelId,
    required this.subjectId,
    required this.navName
  });

  @override
  State<LevelChallengePage> createState() => _LevelChallengePageState();
}

class _LevelChallengePageState extends State<LevelChallengePage> {
  void checkNavigation() async {
    Map<String,dynamic> data = {
      "type": 1,
      "la_subject_id": widget.subjectId,
      "la_level_id": widget.levelId,
    };
    Map<String,dynamic> data1 = {
      "type": 5,
      "la_subject_id": widget.subjectId,
      "la_level_id": widget.levelId,
    };
    Map<String,dynamic> data2 = {
      "type": 6,
      "la_subject_id": widget.subjectId,
      "la_level_id": widget.levelId,
    };
    Map<String,dynamic> rData = {
      "type": 3,
      "la_subject_id": widget.subjectId,
      "la_level_id": widget.levelId,
    };
    Map<String,dynamic> qData = {
      "type": 2,
      "la_subject_id": widget.subjectId,
      "la_level_id": widget.levelId,
    };
    Map<String,dynamic> pData = {
      "type": 4,
      "la_subject_id": widget.subjectId,
      "la_level_id": widget.levelId,
    };

    // Mission
    await Provider.of<SubjectLevelProvider>(context, listen: false).getMission(data);
    final missionCount = Provider.of<SubjectLevelProvider>(context, listen: false).missionListModel?.data?.missions?.data?.length ?? 0;
    debugPrint('🔹 Mission Count: $missionCount');
    if (widget.navName == StringHelper.mission && missionCount > 0) {
      push(
        context: context,
        page: MissionPage(
          missionListModel: Provider.of<SubjectLevelProvider>(context, listen: false).missionListModel!,
        ),
      );
    }

    // Vision
    await Provider.of<SubjectLevelProvider>(context, listen: false).getVision(data);
    final visionCount = Provider.of<SubjectLevelProvider>(context, listen: false)
        .visionListResponse?.total ?? 0;
    debugPrint('🔹 Vision Count: $visionCount');

    if (widget.navName == StringHelper.vision && visionCount > 0) {
      push(
        context: context,
        page: VisionPage(
          navName: widget.navName,
          subjectId: widget.subjectId,
          levelId: widget.levelId,
        ),
      );
    }

    // Jigyasa
    await Provider.of<SubjectLevelProvider>(context, listen: false).getJigyasaMission(data1);
    final jigyasaCount = Provider.of<SubjectLevelProvider>(context, listen: false).jigyasaListModel?.data?.missions?.data?.length ?? 0;
    debugPrint('🔹 Jigyasa Count: $jigyasaCount');
    if (widget.navName == StringHelper.jigyasaSelf && jigyasaCount > 0) {
      push(
        context: context,
        page: MissionPage(
          missionListModel: Provider.of<SubjectLevelProvider>(context, listen: false).jigyasaListModel!,
        ),
      );
    }

    // Pragya
    await Provider.of<SubjectLevelProvider>(context, listen: false).getPragyaMission(data2);
    final pragyaCount = Provider.of<SubjectLevelProvider>(context, listen: false).pragyaListModel?.data?.missions?.data?.length ?? 0;
    debugPrint('🔹 Pragya Count: $pragyaCount');
    if (widget.navName == StringHelper.pragyaSelf && pragyaCount > 0) {
      push(
        context: context,
        page: MissionPage(
          missionListModel: Provider.of<SubjectLevelProvider>(context, listen: false).pragyaListModel!,
        ),
      );
    }

    // Quiz
    await Provider.of<SubjectLevelProvider>(context, listen: false).getQuizTopic(qData);
    final quizCount = Provider.of<SubjectLevelProvider>(context, listen: false).quizTopicModel?.data?.laTopics?.length ?? 0;
    debugPrint('🔹 Quiz Topic Count: $quizCount');
    if (widget.navName == StringHelper.quizSelf && quizCount > 0) {
      push(
        context: context,
        page: QuizTopicListPage(
          provider: Provider.of<SubjectLevelProvider>(context, listen: false),
          levelId: widget.levelId,
          subjectId: widget.subjectId,
        ),
      );
    }

    // Puzzle
    await Provider.of<SubjectLevelProvider>(context, listen: false).getPuzzleTopic(pData);
    final puzzleCount = Provider.of<SubjectLevelProvider>(context, listen: false).puzzleTopicModel?.data?.laTopics?.length ?? 0;
    debugPrint('🔹 Puzzle Topic Count: $puzzleCount');
    if (widget.navName == StringHelper.puzzles && puzzleCount > 0) {
      push(
        context: context,
        page: PuzzlePage(
          provider: Provider.of<SubjectLevelProvider>(context, listen: false),
          levelId: widget.levelId,
          subjectId: widget.subjectId,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🏁 Initializing LevelChallengePage for ${widget.levelName}');
      checkNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectLevelProvider>(context);

    // Get counts for debug output
    final visionCount = provider.visionListResponse?.total ?? 0;
    final missionCount = provider.missionListModel?.data?.missions?.data?.length ?? 0;
    final quizCount = provider.quizTopicModel?.data?.laTopics?.length ?? 0;
    final puzzleCount = provider.puzzleTopicModel?.data?.laTopics?.length ?? 0;
    final jigyasaCount = provider.jigyasaListModel?.data?.missions?.data?.length ?? 0;
    final pragyaCount = provider.pragyaListModel?.data?.missions?.data?.length ?? 0;

    debugPrint('📊 Current Challenge Counts:');
    debugPrint('👁️ Vision: $visionCount');
    debugPrint('🎯 Mission: $missionCount');
    debugPrint('❓ Quiz: $quizCount');
    debugPrint('🧩 Puzzle: $puzzleCount');
    debugPrint('💡 Jigyasa: $jigyasaCount');
    debugPrint('📚 Pragya: $pragyaCount');

    return Scaffold(
      appBar: commonAppBar(
          context: context,
          name: "${widget.levelName} ${StringHelper.challenges}"
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 15, right: 15),
        child: Column(
          children: [
            // Vision - Only show if there are missions
            if (visionCount > 0)
              LevelVisionWidget(
                  provider: provider,
                  levelId: widget.levelId,
                  subjectId: widget.subjectId
              ),

            // Mission - Only show if there are missions
            if (missionCount > 0)
              LevelMissionWidget(
                  provider: provider,
                  levelId: widget.levelId,
                  subjectId: widget.subjectId
              ),

            // Quiz - Only show if there are topics
            if (quizCount > 0)
              LevelQuizWidget(
                provider: provider,
                levelId: widget.levelId,
                subjectId: widget.subjectId,
              ),

            // Puzzle - Only show if there are topics
            if (puzzleCount > 0)
              LevelPuzzlesWidget(
                provider: provider,
                levelId: widget.levelId,
                subjectId: widget.subjectId,
              ),

            // Jigyasa - Only show if there are missions
            if (jigyasaCount > 0) ...[
              const SizedBox(height: 30),
              LevelSubscribeWidget(
                name: StringHelper.jigyasaSelf,
                img: ImageHelper.jigyasaIcon,
                model: provider.jigyasaListModel!,
              ),
            ],

            // Pragya - Only show if there are missions
            if (pragyaCount > 0) ...[
              const SizedBox(height: 30),
              LevelSubscribeWidget(
                name: StringHelper.pragyaSelf,
                img: ImageHelper.pragyaIcon,
                model: provider.pragyaListModel!,
              ),
            ],

            const SizedBox(height: 50),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}