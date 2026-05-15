import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_toeic_app/core/api/dio_client.dart';
import 'package:chat_toeic_app/core/utils/app_env.dart';
import 'package:chat_toeic_app/core/utils/storage_service.dart';
import 'package:chat_toeic_app/features/auth/auth_controller.dart';
import 'package:chat_toeic_app/features/auth/login_screen.dart';
import 'package:chat_toeic_app/features/home/home_view.dart';
import 'package:chat_toeic_app/features/vocabulary/vocabulary_view.dart';
import 'package:chat_toeic_app/features/chat/chat_view.dart';
import 'package:chat_toeic_app/features/profile/profile_view.dart';
import 'package:chat_toeic_app/features/admin/admin_view.dart';
import 'package:chat_toeic_app/features/statistics/statistics_view.dart';
import 'package:chat_toeic_app/features/test/test_detail_view.dart';
import 'package:chat_toeic_app/features/test/test_history_view.dart';
import 'package:chat_toeic_app/features/test/test_result_view.dart';
import 'package:chat_toeic_app/features/test/test_answer_details_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Init Env
  await AppEnv.init();
  
  // Init Dio
  DioClient.init();

  // Inject AuthController
  Get.put(AuthController(), permanent: true);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Chatbot TOEIC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E293B),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF475569)),
        ),
      ),
      initialRoute: '/',
      getPages: [
        GetPage(
          name: '/',
          page: () => const SplashScreen(),
        ),
        GetPage(
          name: '/login',
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: '/home',
          page: () => const HomeView(),
        ),
        GetPage(
          name: '/vocabulary',
          page: () => const VocabularyView(),
        ),
        GetPage(
          name: '/chatbot',
          page: () => const ChatView(),
        ),
        GetPage(
          name: '/profile',
          page: () => const ProfileView(),
        ),
        GetPage(
          name: '/admin',
          page: () => const AdminView(),
        ),
        GetPage(
          name: '/statistics',
          page: () => const StatisticsView(),
        ),
        GetPage(
          name: '/test-detail',
          page: () {
            final args = Get.arguments;

            // Defensive extraction: arguments may be plain int, String, Map or internal IdentityMap
            int _safeExtractInt(dynamic v) {
              if (v == null) return 0;
              if (v is int) return v;
              if (v is String) return int.tryParse(v) ?? 0;
              if (v is Map) {
                if (v.containsKey('id')) return _safeExtractInt(v['id']);
                if (v.containsKey('testId')) return _safeExtractInt(v['testId']);
                if (v.isNotEmpty) return _safeExtractInt(v.values.first);
              }
              return 0;
            }

            final int id = _safeExtractInt((args is Map) ? args['testId'] ?? args : args);
            return TestDetailView(testId: id);
          },
),  
        GetPage(
          name: '/test-history',
          page: () {
            final args = Get.arguments;

            int _safeExtractInt(dynamic v) {
              if (v == null) return 0;
              if (v is int) return v;
              if (v is String) return int.tryParse(v) ?? 0;
              if (v is Map) {
                if (v.containsKey('id')) return _safeExtractInt(v['id']);
                if (v.containsKey('testId')) return _safeExtractInt(v['testId']);
                if (v.isNotEmpty) return _safeExtractInt(v.values.first);
              }
              return 0;
            }

            final int id = _safeExtractInt((args is Map) ? args['testId'] ?? args : args);
            return TestHistoryView(testId: id);
          },
        ),
        GetPage(
          name: '/test-result',
          page: () => const TestResultView(),
        ),
        GetPage(
          name: '/test-answer-details',
          page: () => const TestAnswerDetailsView(),
        ),
      ],
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    final token = await StorageService.getAccessToken();
    final currentRoute = Get.currentRoute;

    if (token != null) {
      // If user is at root, go to home. Otherwise, stay where they are (deep link)
      if (currentRoute == '/' || currentRoute == '/splash') {
        Get.offAllNamed('/home');
      }
    } else {
      // No token, force login unless already at login
      if (currentRoute != '/login') {
        Get.offAllNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      ),
    );
  }
}
