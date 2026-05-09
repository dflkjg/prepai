import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/resume/resume_upload_screen.dart';
import '../../screens/resume/resume_analysis_screen.dart';
import '../../screens/interview/interview_setup_screen.dart';
import '../../screens/interview/interview_chat_screen.dart';
import '../../screens/evaluation/evaluation_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter get router => GoRouter(
        navigatorKey: _rootNavigatorKey,
        initialLocation: '/',
        refreshListenable: _AuthChangeNotifier(),
        redirect: (context, state) {
          final isLoggedIn =
              Supabase.instance.client.auth.currentSession != null;
          final loc = state.matchedLocation;

          final publicRoutes = ['/', '/login', '/register', '/forgot-password'];
          final isPublic = publicRoutes.contains(loc);

          if (!isLoggedIn && !isPublic) return '/login';
          if (isLoggedIn && isPublic && loc != '/') return '/home';
          return null;
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
          GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
          GoRoute(
              path: '/forgot-password',
              builder: (_, __) => const ForgotPasswordScreen()),
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
              path: '/resume', builder: (_, __) => const ResumeUploadScreen()),
          GoRoute(
            path: '/resume/analysis',
            builder: (_, state) {
              final resumeId = state.extra as String?;
              return ResumeAnalysisScreen(resumeId: resumeId);
            },
          ),
          GoRoute(
              path: '/interview/setup',
              builder: (_, __) => const InterviewSetupScreen()),
          GoRoute(
            path: '/interview/chat',
            builder: (_, state) {
              final interviewId = state.extra as String;
              return InterviewChatScreen(interviewId: interviewId);
            },
          ),
          GoRoute(
            path: '/interview/evaluation',
            builder: (_, state) {
              final interviewId = state.extra as String;
              return EvaluationScreen(interviewId: interviewId);
            },
          ),
        ],
      );
}

/// Notifies GoRouter whenever Supabase auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }
}
