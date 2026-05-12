import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_widgets.dart';

class InterviewSetupScreen extends ConsumerStatefulWidget {
  const InterviewSetupScreen({super.key});
  @override
  ConsumerState<InterviewSetupScreen> createState() =>
      _InterviewSetupScreenState();
}

class _InterviewSetupScreenState
    extends ConsumerState<InterviewSetupScreen> {
  String? _role, _industry, _level, _type;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
  }

  void _prefillFromProfile() {
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      setState(() {
        _role = profile.targetRole;
        _industry = profile.industry;
        _level = profile.experienceLevel;
      });
    }
  }

  Future<void> _start() async {
    if (_role == null || _industry == null || _level == null || _type == null) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;

    setState(() { _loading = true; _error = null; });

    try {
      final interview =
          await ref.read(interviewServiceProvider).createInterview(
                userId: uid,
                jobRole: _role!,
                industry: _industry!,
                experienceLevel: _level!,
                interviewType: _type!,
              );

      await ref.read(interviewHistoryProvider.notifier).load(uid);

      if (mounted) {
        context.push('/interview/chat', extra: interview.id);
      }
    } catch (e) {
      setState(() => _error = 'Failed to generate interview. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Interview'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero ────────────────────────────────────
                AppCard(
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Mock Interview',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                            SizedBox(height: 4),
                            Text(
                              'Gemini AI will generate 8 personalised questions for your role.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                const Text('Configure Your Interview',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text(
                    'Customise the interview to match your target job.',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                // ── Dropdowns ────────────────────────────────
                _SetupDropdown(
                  label: 'Job Role',
                  icon: Icons.work_outline,
                  value: _role,
                  items: AppStrings.jobRoles,
                  onChanged: (v) => setState(() => _role = v),
                ),
                const SizedBox(height: 16),
                _SetupDropdown(
                  label: 'Industry',
                  icon: Icons.business_outlined,
                  value: _industry,
                  items: AppStrings.industries,
                  onChanged: (v) => setState(() => _industry = v),
                ),
                const SizedBox(height: 16),
                _SetupDropdown(
                  label: 'Experience Level',
                  icon: Icons.trending_up,
                  value: _level,
                  items: AppStrings.experienceLevels,
                  onChanged: (v) => setState(() => _level = v),
                ),
                const SizedBox(height: 20),

                // ── Interview Type ───────────────────────────
                const Text('Interview Type',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  children: AppStrings.interviewTypes.map((t) {
                    final isSelected = _type == t;
                    final icon = t == 'HR' ? Icons.people : Icons.code;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: t == 'HR' ? 8 : 0,
                            left: t == 'Technical' ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setState(() => _type = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppColors.primaryGradient
                                  : null,
                              color: isSelected ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.divider,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4))
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Icon(icon,
                                    size: 30,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textHint),
                                const SizedBox(height: 8),
                                Text(t,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text(
                                  t == 'HR'
                                      ? 'Soft skills & fit'
                                      : 'Technical & coding',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected
                                          ? Colors.white70
                                          : AppColors.textHint),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.error, fontSize: 13))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                GradientButton(
                  label: 'Generate Interview',
                  onPressed: _start,
                  isLoading: _loading,
                  icon: Icons.auto_awesome,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_loading)
            const LoadingOverlay(
                message: 'Generating personalised questions with AI...\nThis may take a moment.'),
        ],
      ),
    );
  }
}

class _SetupDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _SetupDropdown({
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
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
      ),
      items: items
          .map((i) => DropdownMenuItem(value: i, child: Text(i)))
          .toList(),
      onChanged: onChanged,
      isExpanded: true,
    );
  }
}
