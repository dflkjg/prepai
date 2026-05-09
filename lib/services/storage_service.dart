import 'dart:typed_data';
import 'supabase_service.dart';

class StorageService {
  final _storage = SupabaseService.client.storage;

  static const _bucket = 'resumes';

  /// Upload resume bytes. Returns the public URL.
  Future<String> uploadResume({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$userId/$fileName';

    await _storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    return _storage.from(_bucket).getPublicUrl(path);
  }

  /// Delete a resume file by its storage path.
  Future<void> deleteResume(String userId, String fileName) async {
    await _storage.from(_bucket).remove(['$userId/$fileName']);
  }
}
