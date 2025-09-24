import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/mentor/code/provider/mentor_code_provider.dart';
import 'package:lifelab3/src/mentor/mentor_create_session/provider/mentor_create_session_provider.dart';
import 'package:lifelab3/src/mentor/mentor_home/presentations/pages/mentor_home_page.dart';
import 'package:lifelab3/src/mentor/mentor_home/provider/mentor_home_provider.dart';
import 'package:lifelab3/src/mentor/mentor_my_session_list/provider/mentor_my_session_list_provider_page.dart';
import 'package:lifelab3/src/mentor/mentor_profile/provider/mentor_profile_provider.dart';
import 'package:lifelab3/src/student/connect/provider/connect_provider.dart';
import 'package:lifelab3/src/student/friend/provider/friend_provider.dart';
import 'package:lifelab3/src/student/hall_of_fame/provider/hall_of_fame_provider.dart';
import 'package:lifelab3/src/student/notification/model/notification_model.dart';
import 'package:lifelab3/src/student/home/provider/dashboard_provider.dart';
import 'package:lifelab3/src/student/mission/provider/mission_provider.dart';
import 'package:lifelab3/src/student/nav_bar/presentations/pages/nav_bar_page.dart';
import 'package:lifelab3/src/student/notification/presentations/notification_handler.dart';
import 'package:lifelab3/src/student/profile/provider/profile_provider.dart';
import 'package:lifelab3/src/student/puzzle/provider/puzzle_provider.dart';
import 'package:lifelab3/src/student/questions/provider/question_provider.dart';
import 'package:lifelab3/src/student/quiz/provider/quiz_provider.dart';
import 'package:lifelab3/src/student/riddles/provider/riddle_provider.dart';
import 'package:lifelab3/src/student/sign_up/provider/sign_up_provider.dart';
import 'package:lifelab3/src/student/student_login/provider/student_login_provider.dart';
import 'package:lifelab3/src/student/subject_level_list/provider/subject_level_provider.dart';
import 'package:lifelab3/src/student/subject_list/provider/subject_list_provider.dart';
import 'package:lifelab3/src/student/tracker/provider/tracker_provider.dart';
import 'package:lifelab3/src/teacher/Notifiction/Presentation/notification_handler.dart';
import 'package:lifelab3/src/teacher/shop/provider/provider.dart';
import 'package:lifelab3/src/teacher/shop/services/services.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:lifelab3/src/teacher/teacher_login/provider/teacher_login_provider.dart';
import 'package:lifelab3/src/teacher/teacher_profile/provider/teacher_profile_provider.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/provider/teacher_sign_up_provider.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';
import 'package:lifelab3/src/welcome/presentation/page/welcome_page.dart';
import 'package:provider/provider.dart';
import 'package:lifelab3/src/student/vision/providers/vision_provider.dart';
import 'package:lifelab3/src/common/utils/version_check_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  var data = jsonDecode(notificationResponse.payload!);
  navigateToScreen(data);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message ${message.messageId}');
  debugPrint(
      'Handling a background message ${message.notification?.android?.channelId ?? "NA"}');
  debugPrint("PayLoad ${message.data}");
}

late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
final navKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set white system bars with dark icons
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Optional: show content under status/nav bars (edge-to-edge)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values);

  await StorageUtil.getInstance();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  channel = const AndroidNotificationChannel(
    'lifelab',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  if (Platform.isIOS) {
    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      ),
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
  await MixpanelService.init();
  runApp(const MyApp());
}

class VersionCheckWrapper extends StatefulWidget {
  final Widget child;

  const VersionCheckWrapper({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  final VersionCheckService _versionCheckService = VersionCheckService();

  @override
  void initState() {
    super.initState();
    // Delay version check to ensure MaterialApp is fully initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _versionCheckService.checkAndPromptUpdate(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isLogin;
  bool isMentor = false;
  bool isTeacher = false;

  getFcmToken() async {
    await FirebaseMessaging.instance.requestPermission();
    FirebaseMessaging.instance.getToken().then((value) {
      StorageUtil.putString(StringHelper.fcmToken, value!);
      debugPrint("Fcm Token: $value");
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(message.notification?.title);
        Future.delayed(const Duration(milliseconds: 3000), () {
          navigateToScreen(message.data);
        });
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint("LISTEN${message.data.toString()}");
      RemoteNotification? notification = message.notification;

      AndroidNotification? android = message.notification?.android;
      debugPrint(
          "LISTEN${(message.notification?.android?.channelId ?? "NA").toString()}");
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      var initializationSettingsAndroid =
          const AndroidInitializationSettings('@drawable/launch_background');

      // var initializationSettingsIOs = const IOSInitializationSettings();
      DarwinInitializationSettings iosInitializationSettings =
          const DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      var initSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: iosInitializationSettings);
      flutterLocalNotificationsPlugin.initialize(initSettings,
          onDidReceiveNotificationResponse: notificationTapBackground,
          onDidReceiveBackgroundNotificationResponse:
              notificationTapBackground);

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                icon: 'launch_background',
              ),
            ),
            payload: jsonEncode(message.data));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigateToScreen(message.data);
    });

    FirebaseMessaging.onBackgroundMessage((RemoteMessage message) async {
      await Firebase.initializeApp();
      navigateToScreen(message.data);
    });
  }

  @override
  void initState() {
    getFcmToken();
    isLogin = StorageUtil.getBool(StringHelper.isLoggedIn);
    isMentor = StorageUtil.getBool(StringHelper.isMentor);
    isTeacher = StorageUtil.getBool(StringHelper.isTeacher);
    debugPrint("Is Logged In: $isLogin");
    debugPrint("Is Mentor: $isMentor");
    debugPrint("Is Teacher: $isTeacher");
    super.initState();
  }

  Widget _buildHomeScreen() {
    Widget homeWidget = isLogin!
        ? const NavBarPage(currentIndex: 0)
        : isMentor
            ? const MentorHomePage()
            : isTeacher
                ? const TeacherDashboardPage()
                : const WelComePage();

    return VersionCheckWrapper(child: homeWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StudentLoginProvider()),
        ChangeNotifierProvider(create: (_) => SignUpProvider()),
        ChangeNotifierProvider(create: (_) => TrackerProvider()),
        ChangeNotifierProvider(create: (_) => ConnectProvider()),
        ChangeNotifierProvider(create: (_) => SubjectListProvider()),
        ChangeNotifierProvider(create: (_) => SubjectLevelProvider()),
        ChangeNotifierProvider(create: (_) => MissionProvider()),
        ChangeNotifierProvider(create: (_) => RiddleProvider()),
        ChangeNotifierProvider(create: (_) => PuzzleProvider()),
        ChangeNotifierProvider(create: (_) => MentorOtpProvider()),
        ChangeNotifierProvider(create: (_) => MentorHomeProvider()),
        ChangeNotifierProvider(create: (_) => MentorCreateSessionProvider()),
        ChangeNotifierProvider(create: (_) => MentorMySessionListProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TeacherLoginProvider()),
        ChangeNotifierProvider(create: (_) => TeacherDashboardProvider()),
        ChangeNotifierProvider(create: (_) => TeacherSignUpProvider()),
        ChangeNotifierProvider(create: (_) => StudentProgressProvider()),
        ChangeNotifierProvider(create: (_) => FriendProvider()),
        ChangeNotifierProvider(create: (_) => HallOfFameProvider()),
        ChangeNotifierProvider(create: (_) => QuestionProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => ProductProvider(
              ProductService('https://your.api/baseurl')), // ✅ Correct
        ),
        ChangeNotifierProvider(create: (_) => MentorProfileProvider()),
        ChangeNotifierProvider(create: (_) => ToolProvider()),
        ChangeNotifierProvider(create: (_) => TeacherProfileProvider()),
        ChangeNotifierProvider(create: (_) => VisionProvider()),
      ],
      child: MaterialApp(
        navigatorKey: navKey,
        title: 'Life App',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en', ''), // English
        ],
        builder: (context, child) {
          return MaterialApp(
            // Remove the title and navigatorKey as they're in the parent MaterialApp
            debugShowCheckedModeBanner: false,
            home: Material(
              type: MaterialType.transparency,
              child: child!,
            ),
            theme: Theme.of(context), // Inherit theme from parent
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              color: ColorCode.defaultBgColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            elevation: 0,
            titleSpacing: 0,
            centerTitle: false,
            backgroundColor: ColorCode.defaultBgColor,
            scrolledUnderElevation: 0,
          ),
          scaffoldBackgroundColor: ColorCode.defaultBgColor,
          primaryColor: ColorCode.defaultBgColor,
          fontFamily: "Avenir",
          textTheme: const TextTheme().apply(displayColor: Colors.white),
        ),
        home: _buildHomeScreen(),
      ),
    );
  }
}

int _safeInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _safeString(dynamic value, {String fallback = ""}) {
  if (value == null) return fallback;
  return value.toString().trim();
}

void navigateToScreen(Map<String, dynamic> data) {
  debugPrint("=== Raw Notification Data ===");
  debugPrint(data.toString());

  final bool isStudent = StorageUtil.getBool(StringHelper.isLoggedIn) ?? false;
  final bool isTeacher = StorageUtil.getBool(StringHelper.isTeacher) ?? false;
  final bool isMentor = StorageUtil.getBool(StringHelper.isMentor) ?? false;

  final context = navKey.currentState?.overlay?.context;
  if (context == null) {
    debugPrint("Navigator context is null, cannot navigate or show popup.");
    return;
  }

  if (isStudent) {
    try {
      dynamic rawDataDynamic = data['data'];
      Map<String, dynamic> rawData = {};

      if (rawDataDynamic is String) {
        try {
          final decoded = jsonDecode(rawDataDynamic);
          if (decoded is Map<String, dynamic>) rawData = decoded;
        } catch (e) {
          debugPrint("Failed to decode rawData string → $e");
        }
      } else if (rawDataDynamic is Map<String, dynamic>) {
        rawData = rawDataDynamic;
      }

      // Build payload
      final studentPayload = {
        "id": null,
        "type": _safeString(data['type']),
        "data": {
          "title": _safeString(data['title'], fallback: "Notification"),
          "message": _safeString(data['message']),
          "data": {
            "action": _safeInt(rawData['action']),
            "actionId": _safeInt(rawData['action_id'] ?? rawData['actionId']),
            "laSubjectId":
                _safeInt(rawData['la_subject_id'] ?? rawData['laSubjectId']),
            "laLevelId":
                _safeInt(rawData['la_level_id'] ?? rawData['laLevelId']),
            "missionId":
                _safeInt(rawData['mission_id'] ?? rawData['missionId']),
            "visionId": _safeInt(rawData['vision_id'] ?? rawData['visionId']),
            "admin_message_id": _safeInt(rawData['admin_message_id']),
            "time": _safeInt(rawData['time']),
          },
        },
      };

      debugPrint("=== Notification Payload Sent to Handler ===");
      debugPrint(jsonEncode(studentPayload));

      final notification = NotificationData.fromJson(studentPayload);

      // Log parsed data
      debugPrint("=== Parsed NotificationData Object ===");
      debugPrint("Title: ${notification.data?..title}");
      debugPrint("Message: ${notification.data?.message}");
      debugPrint("Action ID: ${notification.data?.data?.actionId}");
      debugPrint("Mission ID: ${notification.data?.data?.missionId}");
      debugPrint("Vision ID: ${notification.data?.data?.visionId}");
      debugPrint("Subject ID: ${notification.data?.data?.laSubjectId}");
      debugPrint("Level ID: ${notification.data?.data?.laLevelId}");

      NotificationActionHandler.handleNotification(context, notification);
    } catch (e, s) {
      debugPrint("Error parsing notification for student: $e\n$s");
    }
  } else if (isTeacher) {
    TeacherNotificationHandler.show(context, data);
  } else if (isMentor) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MentorHomePage()),
    );
  } else {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const WelComePage()),
    );
  }
}
