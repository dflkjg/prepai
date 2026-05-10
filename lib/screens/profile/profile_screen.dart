import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_widgets.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  String? _role, _industry, _level;
  bool _loading = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    await ref.read(profileProvider.notifier).load(uid);
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null && mounted) {
      _nameCtrl.text = profile.name ?? '';
      setState(() {
        _role = profile.targetRole;
        _industry = profile.industry;
        _level = profile.experienceLevel;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _saved = false; });
    final uid = SupabaseService.currentUserId!;
    final existing = ref.read(profileProvider).valueOrNull;
    final updated = (existing ?? UserProfile(id: uid)).copyWith(
      name: _nameCtrl.text.trim(),
      targetRole: _role,
      industry: _industry,
      experienceLevel: _level,
    );
    try {
      await ref.read(profileProvider.notifier).update(updated);
      if (mounted) setState(() => _saved = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: BackButton(onPressed: () => context.go('/home')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          )
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Avatar ─────────────────────────────────
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      (profile?.name?.isNotEmpty == true
                              ? profile!.name![0]
                              : '?')
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(profile?.email ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 28),

                // ── Form Fields ─────────────────────────────
                AppTextField(
                  label: 'Full Name',
                  controller: _nameCtrl,
                  prefixIcon: Icons.person_outline,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),

                _DropdownField(
                  label: 'Target Job Role',
                  icon: Icons.work_outline,
                  value: _role,
                  items: AppStrings.jobRoles,
                  onChanged: (v) => setState(() => _role = v),
                ),
                const SizedBox(height: 16),

                _DropdownField(
                  label: 'Industry',
                  icon: Icons.business_outlined,
                  value: _industry,
                  items: AppStrings.industries,
                  onChanged: (v) => setState(() => _industry = v),
                ),
                const SizedBox(height: 16),

                _DropdownField(
                  label: 'Experience Level',
                  icon: Icons.trending_up,
                  value: _level,
                  items: AppStrings.experienceLevels,
                  onChanged: (v) => setState(() => _level = v),
                ),
                const SizedBox(height: 28),

                if (_saved)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: AppColors.success, size: 18),
                          SizedBox(width: 8),
                          Text('Profile saved!',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),

                GradientButton(
                  label: 'Save Profile',
                  onPressed: _save,
                  isLoading: _loading,
                  icon: Icons.save_outlined,
                ),
                const SizedBox(height: 16),

                // ── Profile Completion ──────────────────────
                if (profile != null && !profile.isComplete)
                  AppCard(
                    color: AppColors.warning.withOpacity(0.08),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.warning, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Complete your profile to get personalised interview questions.',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: AppColors.textHint, size: 20),
      ),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
