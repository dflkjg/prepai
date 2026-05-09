import 'dart:typed_data';
import '../models/app_models.dart';
import 'supabase_service.dart';
import 'storage_service.dart';
import 'gemini_service.dart';

class ResumeService {
  final _db = SupabaseService.client;
  final StorageService _storage;
  final GeminiService _gemini;

  ResumeService(this._storage, this._gemini);

  /// Upload PDF bytes, analyze via Gemini, store result in DB.
  Future<ResumeModel> uploadAndAnalyze({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    // 1. Upload to Supabase Storage
    final fileUrl = await _storage.uploadResume(
      userId: userId,
      fileName: fileName,
      bytes: bytes,
    );

    // 2. Analyze with Gemini (PDF bytes sent directly)
    final analysis = await _gemini.analyzeResume(bytes);

    // 3. Save to DB
    final response = await _db.from('resumes').insert({
      'user_id': userId,
      'file_name': fileName,
      'file_url': fileUrl,
      'analysis': analysis.toJson(),
    }).select().single();

    return ResumeModel.fromJson(response);
  }

  /// Fetch latest resume for user.
  Future<ResumeModel?> fetchLatestResume(String userId) async {
    final data = await _db
        .from('resumes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data == null ? null : ResumeModel.fromJson(data);
  }

  /// Fetch all resumes for user.
  Future<List<ResumeModel>> fetchAllResumes(String userId) async {
    final data = await _db
        .from('resumes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => ResumeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
