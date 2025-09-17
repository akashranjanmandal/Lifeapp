import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:lifelab3/src/student/notification/model/notification_model.dart';
import 'package:lifelab3/src/student/notification/presentations/notification_handler.dart';
import 'package:lifelab3/src/student/notification/presentations/notification_page.dart';
import 'package:provider/provider.dart';

// 🔹 Your imports
import 'package:lifelab3/src/common/helper/color_code.dart';
import 'package:lifelab3/src/common/helper/string_helper.dart';
import 'package:lifelab3/src/common/utils/version_check_service.dart';
import 'package:lifelab3/src/common/utils/mixpanel_service.dart';
import 'package:lifelab3/src/utils/storage_utils.dart';

// 🔹 Student imports
import 'package:lifelab3/src/student/nav_bar/presentations/pages/nav_bar_page.dart';
import 'package:lifelab3/src/student/mission/provider/mission_provider.dart';
import 'package:lifelab3/src/student/home/provider/dashboard_provider.dart';
import 'package:lifelab3/src/student/connect/provider/connect_provider.dart';
import 'package:lifelab3/src/student/friend/provider/friend_provider.dart';
import 'package:lifelab3/src/student/hall_of_fame/provider/hall_of_fame_provider.dart';
import 'package:lifelab3/src/student/questions/provider/question_provider.dart';
import 'package:lifelab3/src/student/quiz/provider/quiz_provider.dart';
import 'package:lifelab3/src/student/profile/provider/profile_provider.dart';
import 'package:lifelab3/src/student/riddles/provider/riddle_provider.dart';
import 'package:lifelab3/src/student/puzzle/provider/puzzle_provider.dart';
import 'package:lifelab3/src/student/sign_up/provider/sign_up_provider.dart';
import 'package:lifelab3/src/student/student_login/provider/student_login_provider.dart';
import 'package:lifelab3/src/student/subject_level_list/provider/subject_level_provider.dart';
import 'package:lifelab3/src/student/subject_list/provider/subject_list_provider.dart';
import 'package:lifelab3/src/student/tracker/provider/tracker_provider.dart';
import 'package:lifelab3/src/student/vision/providers/vision_provider.dart';

// 🔹 Mentor imports
import 'package:lifelab3/src/mentor/code/provider/mentor_code_provider.dart';
import 'package:lifelab3/src/mentor/mentor_create_session/provider/mentor_create_session_provider.dart';
import 'package:lifelab3/src/mentor/mentor_home/presentations/pages/mentor_home_page.dart';
import 'package:lifelab3/src/mentor/mentor_home/provider/mentor_home_provider.dart';
import 'package:lifelab3/src/mentor/mentor_my_session_list/provider/mentor_my_session_list_provider_page.dart';
import 'package:lifelab3/src/mentor/mentor_profile/provider/mentor_profile_provider.dart';

// 🔹 Teacher imports
import 'package:lifelab3/src/teacher/shop/provider/provider.dart';
import 'package:lifelab3/src/teacher/shop/services/services.dart';
import 'package:lifelab3/src/teacher/student_progress/provider/student_progress_provider.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/presentations/pages/teacher_dashboard_page.dart';
import 'package:lifelab3/src/teacher/teacher_dashboard/provider/teacher_dashboard_provider.dart';
import 'package:lifelab3/src/teacher/teacher_login/provider/teacher_login_provider.dart';
import 'package:lifelab3/src/teacher/teacher_profile/provider/teacher_profile_provider.dart';
import 'package:lifelab3/src/teacher/teacher_sign_up/provider/teacher_sign_up_provider.dart';
import 'package:lifelab3/src/teacher/teacher_tool/provider/tool_provider.dart';

// 🔹 Welcome
import 'package:lifelab3/src/welcome/presentation/page/welcome_page.dart';

// ------------------ FCM Background Handler ------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message: ${message.messageId}');
  debugPrint("Payload: ${message.data}");
  _handleNotificationTap(message.data);
}

// ------------------ Notification Tap Handler ------------------
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint("Notification tapped in background/terminated");
  if (notificationResponse.payload != null) {
    final data = jsonDecode(notificationResponse.payload!);
    debugPrint("Payload: $data");
    _handleNotificationTap(data);
  }
}

// ------------------ Global Variables ------------------
late AndroidNotificationChannel channel;
late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
final navKey = GlobalKey<NavigatorState>();

// ------------------ MAIN ------------------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  await StorageUtil.getInstance();
  await Firebase.initializeApp();
  await FirebaseMessaging.instance.setAutoInitEnabled(true);

  // FCM Background Handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Notification Channel
  channel = const AndroidNotificationChannel(
    'lifelab',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    ),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: notificationTapBackground,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await MixpanelService.init();

  runApp(const MyApp());
}

// ------------------ Version Check Wrapper ------------------
class VersionCheckWrapper extends StatefulWidget {
  final Widget child;
  const VersionCheckWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<VersionCheckWrapper> createState() => _VersionCheckWrapperState();
}

class _VersionCheckWrapperState extends State<VersionCheckWrapper> {
  final VersionCheckService _versionCheckService = VersionCheckService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _versionCheckService.checkAndPromptUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ------------------ APP ------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? isLogin;
  bool isMentor = false;
  bool isTeacher = false;

  @override
  void initState() {
    super.initState();
    initNotifications();
    isLogin = StorageUtil.getBool(StringHelper.isLoggedIn);
    isMentor = StorageUtil.getBool(StringHelper.isMentor);
    isTeacher = StorageUtil.getBool(StringHelper.isTeacher);
  }

  Future<void> initNotifications() async {
    await FirebaseMessaging.instance.requestPermission(
        alert: true, badge: true, sound: true);

    final token = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM Token: $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      debugPrint("FCM Token refreshed: $t");
    });

    // Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground FCM: ${message.data}");
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification tapped (background): ${message.data}");
      if (navKey.currentContext != null) {
        _handleNotificationTap(message.data);
      }
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint("App launched from terminated: ${initialMessage.data}");
      Future.delayed(const Duration(milliseconds: 500), () {
        if (navKey.currentContext != null) {
          _handleNotificationTap(initialMessage.data);
        }
      });
    }
  }

  Widget _buildHomeScreen() {
    final homeWidget = isLogin == true
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
          create: (_) => ProductProvider(ProductService('https://your.api/baseurl')),
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
          Locale('en', ''),
        ],
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            titleTextStyle: TextStyle(
              color: ColorCode.defaultBgColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            elevation: 0,
            backgroundColor: ColorCode.defaultBgColor,
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
void showNotificationLoader(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false, // user can’t close it manually
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Loading notification...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ),
  );
}

// ------------------ Notification Tap ------------------
void _handleNotificationTap(Map<String, dynamic>? rawData) async {
  debugPrint("Handling notification tap: $rawData");

  if (navKey.currentContext == null) return;

  if (rawData == null || rawData.isEmpty) {
    debugPrint("Notification data empty, opening fallback NotificationPage");
    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
    return;
  }

  // 🔹 Show loader
  showNotificationLoader(navKey.currentContext!);

  // 🔹 Give Flutter one frame to draw loader
  await Future.delayed(Duration.zero);

  try {
    // Normalize payload
    final normalized = {
      "id": rawData["id"] ?? "",
      "type": rawData["type"] ?? "",
      "notifiable_type": rawData["notifiable_type"],
      "notifiable_id": rawData["notifiable_id"],
      "data": {
        "title": rawData["title"],
        "message": rawData["message"],
        "data": rawData["data"],
      },
      "created_at": rawData["created_at"],
      "updated_at": rawData["updated_at"],
    };

    final notification = NotificationData.fromJson(normalized);

    // 🔹 Close loader once everything is ready
    Navigator.of(navKey.currentContext!, rootNavigator: true).pop();

    // 🔹 Navigate to the actual target page
    NotificationActionHandler.handleNotification(
      navKey.currentContext!,
      notification,
    );
  } catch (e, st) {
    debugPrint("Error parsing notification data: $e\n$st");

    Navigator.of(navKey.currentContext!, rootNavigator: true).pop(); // close loader
    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }
}
