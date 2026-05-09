import '../models/app_models.dart';
import 'supabase_service.dart';

class ProfileService {
  final _db = SupabaseService.client;

  Future<UserProfile?> fetchProfile(String userId) async {
    final data = await _db
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data == null ? null : UserProfile.fromJson(data);
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _db.from('profiles').upsert({
      ...profile.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
