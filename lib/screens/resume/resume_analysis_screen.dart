import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../services/resume_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_widgets.dart';

class ResumeAnalysisScreen extends ConsumerStatefulWidget {
  final String? resumeId;
  const ResumeAnalysisScreen({super.key, this.resumeId});
  @override
  ConsumerState<ResumeAnalysisScreen> createState() =>
      _ResumeAnalysisScreenState();
}

class _ResumeAnalysisScreenState
    extends ConsumerState<ResumeAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    await ref.read(resumeProvider.notifier).loadLatest(uid);
  }

  @override
  Widget build(BuildContext context) {
    final resumeAsync = ref.watch(resumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Analysis'),
        leading: BackButton(onPressed: () => context.go('/resume')),
      ),
      body: resumeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (resume) {
          if (resume == null || resume.analysis == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  const Text('No analysis yet',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: 'Upload Resume',
                    onPressed: () => context.go('/resume'),
                  ),
                ],
              ),
            );
          }
          return _AnalysisBody(analysis: resume.analysis!);
        },
      ),
    );
  }
}

class _AnalysisBody extends StatelessWidget {
  final ResumeAnalysis analysis;
  const _AnalysisBody({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Score Card ──────────────────────────────────
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    ScoreRing(
                        score: analysis.score.toDouble(), size: 100, label: '/100'),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resume Score',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            _scoreLabel(analysis.score),
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.scoreColor(
                                    analysis.score / 10)),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: analysis.score / 100,
                            backgroundColor: AppColors.divider,
                            color: AppColors.scoreColor(analysis.score / 10),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (analysis.summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text(analysis.summary,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Skills ──────────────────────────────────────
          _Section(
            title: '🛠 Skills Identified',
            color: AppColors.primary,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.skills
                  .map((s) => SkillChip(label: s))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Education ────────────────────────────────────
          if (analysis.education.isNotEmpty)
            _Section(
              title: '🎓 Education',
              color: AppColors.accent,
              child: Column(
                children: analysis.education
                    .map((e) => _BulletItem(text: e, color: AppColors.accent))
                    .toList(),
              ),
            ),
          if (analysis.education.isNotEmpty) const SizedBox(height: 16),

          // ── Experience ───────────────────────────────────
          if (analysis.experience.isNotEmpty)
            _Section(
              title: '💼 Experience',
              color: AppColors.secondary,
              child: Column(
                children: analysis.experience
                    .map((e) => _BulletItem(text: e, color: AppColors.secondary))
                    .toList(),
              ),
            ),
          if (analysis.experience.isNotEmpty) const SizedBox(height: 16),

          // ── Suggestions ──────────────────────────────────
          _Section(
            title: '💡 Improvement Suggestions',
            color: AppColors.warning,
            child: Column(
              children: analysis.suggestions
                  .map((s) => _BulletItem(text: s, color: AppColors.warning))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Weak Areas ───────────────────────────────────
          if (analysis.weakAreas.isNotEmpty)
            _Section(
              title: '⚠️ Areas to Improve',
              color: AppColors.error,
              child: Column(
                children: analysis.weakAreas
                    .map((w) => _BulletItem(text: w, color: AppColors.error))
                    .toList(),
              ),
            ),

          const SizedBox(height: 24),
          GradientButton(
            label: 'Start Mock Interview',
            onPressed: () => context.push('/interview/setup'),
            icon: Icons.play_arrow,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Excellent resume!';
    if (score >= 60) return 'Good — some improvements needed.';
    if (score >= 40) return 'Fair — significant improvements needed.';
    return 'Needs major improvements.';
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;

  const _Section(
      {required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.4))),
        ],
      ),
    );
  }
}
