import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/app_models.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/storage_service.dart';
import '../services/profile_service.dart';
import '../services/resume_service.dart';
import '../services/interview_service.dart';

// ── Service Providers ────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final geminiServiceProvider = Provider<GeminiService>((ref) =>
    GeminiService(dotenv.env['GEMINI_API_KEY']!));

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());

final profileServiceProvider =
    Provider<ProfileService>((ref) => ProfileService());

final resumeServiceProvider = Provider<ResumeService>((ref) => ResumeService(
      ref.read(storageServiceProvider),
      ref.read(geminiServiceProvider),
    ));

final interviewServiceProvider = Provider<InterviewService>(
    (ref) => InterviewService(ref.read(geminiServiceProvider)));

// ── Auth State ───────────────────────────────────────────────
final authStateProvider = StreamProvider<bool>((ref) {
  return ref
      .read(authServiceProvider)
      .authStateChanges
      .map((event) => event.session != null);
});

// ── Current User Profile ──────────────────────────────────
final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier(ref.read(profileServiceProvider));
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileService _service;
  ProfileNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> load(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.fetchProfile(userId));
  }

  Future<void> update(UserProfile profile) async {
    await _service.updateProfile(profile);
    state = AsyncValue.data(profile);
  }
}

// ── Resume State ─────────────────────────────────────────────
final resumeProvider =
    StateNotifierProvider<ResumeNotifier, AsyncValue<ResumeModel?>>((ref) {
  return ResumeNotifier(ref.read(resumeServiceProvider));
});

class ResumeNotifier extends StateNotifier<AsyncValue<ResumeModel?>> {
  final ResumeService _service;
  ResumeNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> loadLatest(String userId) async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _service.fetchLatestResume(userId));
  }

  Future<void> uploadAndAnalyze({
    required String userId,
    required String fileName,
    required List<int> bytes,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.uploadAndAnalyze(
          userId: userId,
          fileName: fileName,
          bytes: bytes as dynamic,
        ));
  }
}

// ── Interview History ────────────────────────────────────────
final interviewHistoryProvider =
    StateNotifierProvider<InterviewHistoryNotifier,
        AsyncValue<List<InterviewModel>>>((ref) {
  return InterviewHistoryNotifier(ref.read(interviewServiceProvider));
});

class InterviewHistoryNotifier
    extends StateNotifier<AsyncValue<List<InterviewModel>>> {
  final InterviewService _service;
  InterviewHistoryNotifier(this._service)
      : super(const AsyncValue.data([]));

  Future<void> load(String userId) async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _service.fetchHistory(userId));
  }
}
