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
  bool _isLoading = true;
  bool _hasInitialized = false;

  // Create data parameters once
  Map<String, dynamic> get _missionData => {
    "type": 1,
    "la_subject_id": widget.subjectId,
    "la_level_id": widget.levelId,
  };

  Map<String, dynamic> get _jigyasaData => {
    "type": 5,
    "la_subject_id": widget.subjectId,
    "la_level_id": widget.levelId,
  };

  Map<String, dynamic> get _pragyaData => {
    "type": 6,
    "la_subject_id": widget.subjectId,
    "la_level_id": widget.levelId,
  };

  Map<String, dynamic> get _visionData => {
    "type": 3,
    "la_subject_id": widget.subjectId,
    "la_level_id": widget.levelId,
  };

  Map<String, dynamic> get _quizData => {
    "type": 2,
    "la_subject_id": widget.subjectId,
    "la_level_id": widget.levelId,
  };

  Map<String, dynamic> get _puzzleData => {
    "type": 4,
    "la_subject_id": widget.subjectId,
    "la_level_id": widget.levelId,
  };

  Future<void> _loadAllData() async {
    if (_hasInitialized) return;

    _hasInitialized = true;
    debugPrint('🚀 Loading all data for Level ${widget.levelName}');

    final provider = Provider.of<SubjectLevelProvider>(context, listen: false);

    try {
      // Load all data in parallel
      await Future.wait([
        provider.getMission(_missionData),
        provider.getVision(_visionData),
        provider.getJigyasaMission(_jigyasaData),
        provider.getPragyaMission(_pragyaData),
        provider.getQuizTopic(_quizData),
        provider.getPuzzleTopic(_puzzleData),
      ]);

      debugPrint('✅ All data loaded successfully');
      _checkNavigation(provider);
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _checkNavigation(SubjectLevelProvider provider) {
    if (widget.navName.isEmpty) return;

    debugPrint('🔍 Checking navigation for: ${widget.navName}');

    switch (widget.navName) {
      case StringHelper.mission:
        final missionCount = provider.missionListModel?.data?.missions?.data?.length ?? 0;
        if (missionCount > 0) {
          _navigateToMission(provider.missionListModel!);
        }
        break;

      case StringHelper.vision:
        final visionCount = provider.visionListResponse?.total ?? 0;
        if (visionCount > 0) {
          _navigateToVision();
        }
        break;

      case StringHelper.jigyasaSelf:
        final jigyasaCount = provider.jigyasaListModel?.data?.missions?.data?.length ?? 0;
        if (jigyasaCount > 0) {
          _navigateToJigyasa(provider.jigyasaListModel!);
        }
        break;

      case StringHelper.pragyaSelf:
        final pragyaCount = provider.pragyaListModel?.data?.missions?.data?.length ?? 0;
        if (pragyaCount > 0) {
          _navigateToPragya(provider.pragyaListModel!);
        }
        break;

      case StringHelper.quizSelf:
        final quizCount = provider.quizTopicModel?.data?.laTopics?.length ?? 0;
        if (quizCount > 0) {
          _navigateToQuiz(provider);
        }
        break;

      case StringHelper.puzzles:
        final puzzleCount = provider.puzzleTopicModel?.data?.laTopics?.length ?? 0;
        if (puzzleCount > 0) {
          _navigateToPuzzle(provider);
        }
        break;
    }
  }

  void _navigateToMission(dynamic model) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      push(
        context: context,
        page: MissionPage(missionListModel: model),
      );
    });
  }

  void _navigateToVision() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      push(
        context: context,
        page: VisionPage(
          navName: widget.navName,
          subjectId: widget.subjectId,
          levelId: widget.levelId,
        ),
      );
    });
  }

  void _navigateToJigyasa(dynamic model) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      push(
        context: context,
        page: MissionPage(missionListModel: model),
      );
    });
  }

  void _navigateToPragya(dynamic model) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      push(
        context: context,
        page: MissionPage(missionListModel: model),
      );
    });
  }

  void _navigateToQuiz(SubjectLevelProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      push(
        context: context,
        page: QuizTopicListPage(
          provider: provider,
          levelId: widget.levelId,
          subjectId: widget.subjectId,
        ),
      );
    });
  }

  void _navigateToPuzzle(SubjectLevelProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      push(
        context: context,
        page: PuzzlePage(
          provider: provider,
          levelId: widget.levelId,
          subjectId: widget.subjectId,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    debugPrint('🏁 Initializing LevelChallengePage for ${widget.levelName}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllData();
    });
  }

  void _debugPrintCounts(SubjectLevelProvider provider) {
    final visionCount = provider.visionListResponse?.total ?? 0;
    final missionCount = provider.missionListModel?.data?.missions?.data?.length ?? 0;
    final quizCount = provider.quizTopicModel?.data?.laTopics?.length ?? 0;
    final puzzleCount = provider.puzzleTopicModel?.data?.laTopics?.length ?? 0;
    final jigyasaCount = provider.jigyasaListModel?.data?.missions?.data?.length ?? 0;
    final pragyaCount = provider.pragyaListModel?.data?.missions?.data?.length ?? 0;

    debugPrint('📊 Final Challenge Counts:');
    debugPrint('👁️ Vision: $visionCount');
    debugPrint('🎯 Mission: $missionCount');
    debugPrint('❓ Quiz: $quizCount');
    debugPrint('🧩 Puzzle: $puzzleCount');
    debugPrint('💡 Jigyasa: $jigyasaCount');
    debugPrint('📚 Pragya: $pragyaCount');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SubjectLevelProvider>(context);

    // Print counts only once when loading completes
    if (!_isLoading) {
      _debugPrintCounts(provider);
    }

    return Scaffold(
      appBar: commonAppBar(
          context: context,
          name: "${widget.levelName} ${StringHelper.challenges}"
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(provider),
    );
  }

  Widget _buildContent(SubjectLevelProvider provider) {
    final visionCount = provider.visionListResponse?.total ?? 0;
    final missionCount = provider.missionListModel?.data?.missions?.data?.length ?? 0;
    final quizCount = provider.quizTopicModel?.data?.laTopics?.length ?? 0;
    final puzzleCount = provider.puzzleTopicModel?.data?.laTopics?.length ?? 0;
    final jigyasaCount = provider.jigyasaListModel?.data?.missions?.data?.length ?? 0;
    final pragyaCount = provider.pragyaListModel?.data?.missions?.data?.length ?? 0;

    // Check if any content is available
    final hasContent = visionCount > 0 ||
        missionCount > 0 ||
        quizCount > 0 ||
        puzzleCount > 0 ||
        jigyasaCount > 0 ||
        pragyaCount > 0;

    if (!hasContent) {
      return const Center(
        child: Text('No challenges available for this level'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 15, right: 15),
      child: Column(
        children: [
          if (visionCount > 0)
            LevelVisionWidget(
              provider: provider,
              levelId: widget.levelId,
              subjectId: widget.subjectId,
            ),

          if (missionCount > 0)
            LevelMissionWidget(
              provider: provider,
              levelId: widget.levelId,
              subjectId: widget.subjectId,
            ),

          if (quizCount > 0)
            LevelQuizWidget(
              provider: provider,
              levelId: widget.levelId,
              subjectId: widget.subjectId,
            ),

          if (puzzleCount > 0)
            LevelPuzzlesWidget(
              provider: provider,
              levelId: widget.levelId,
              subjectId: widget.subjectId,
            ),

          if (jigyasaCount > 0) ...[
            const SizedBox(height: 30),
            LevelSubscribeWidget(
              name: StringHelper.jigyasaSelf,
              img: ImageHelper.jigyasaIcon,
              model: provider.jigyasaListModel!,
            ),
          ],

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
    );
  }
}