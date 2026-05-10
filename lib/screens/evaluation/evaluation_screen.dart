import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/app_widgets.dart';

class EvaluationScreen extends ConsumerStatefulWidget {
  final String interviewId;
  const EvaluationScreen({super.key, required this.interviewId});
  @override
  ConsumerState<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends ConsumerState<EvaluationScreen> {
  List<EvaluationModel> _evaluations = [];
  InterviewModel? _interview;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = ref.read(interviewHistoryProvider).valueOrNull ?? [];
      _interview = history.where((i) => i.id == widget.interviewId).isNotEmpty
          ? history.firstWhere((i) => i.id == widget.interviewId)
          : null;

      final evals = await ref
          .read(interviewServiceProvider)
          .fetchEvaluations(widget.interviewId);

      setState(() { _evaluations = evals; _loading = false; });
    } catch (e) {
      setState(() { _error = 'Could not load results.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final avg = _interview?.overallScore ??
        (_evaluations.isEmpty
            ? 0.0
            : _evaluations.fold(0.0, (s, e) => s + e.score) /
                _evaluations.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluation Results'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: _error != null
          ? Center(child: Text(_error!))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Overall Score ───────────────────────────
                  AppCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            ScoreRing(
                                score: avg * 10, size: 100, label: '/10'),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Overall Score',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _overallLabel(avg),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.scoreColor(avg),
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_interview != null) ...[
                                    _InfoChip(
                                        label: _interview!.interviewType,
                                        icon: _interview!.interviewType ==
                                                'Technical'
                                            ? Icons.code
                                            : Icons.people),
                                    const SizedBox(height: 4),
                                    _InfoChip(
                                        label: _interview!.jobRole,
                                        icon: Icons.work_outline),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_evaluations.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          // Mini score bars
                          ...List.generate(_evaluations.length, (i) {
                            final e = _evaluations[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    child: Text('Q${i + 1}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: e.score / 10,
                                      backgroundColor: AppColors.divider,
                                      color: AppColors.scoreColor(e.score),
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    e.score.toStringAsFixed(1),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.scoreColor(e.score)),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Per-Question Cards ──────────────────────
                  const SectionHeader(title: 'Question-by-Question'),
                  const SizedBox(height: 12),
                  ..._evaluations.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _EvalCard(index: i + 1, evaluation: e),
                    );
                  }),

                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Practice Again',
                    onPressed: () => context.push('/interview/setup'),
                    icon: Icons.replay,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Back to Dashboard'),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  String _overallLabel(double score) {
    if (score >= 8) return 'Excellent performance!';
    if (score >= 6) return 'Good — keep practising!';
    if (score >= 4) return 'Fair — more practice needed.';
    return 'Needs improvement — don\'t give up!';
  }
}

class _EvalCard extends StatefulWidget {
  final int index;
  final EvaluationModel evaluation;
  const _EvalCard({required this.index, required this.evaluation});
  @override
  State<_EvalCard> createState() => _EvalCardState();
}

class _EvalCardState extends State<_EvalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.evaluation;
    final scoreColor = AppColors.scoreColor(e.score);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text('Q${widget.index}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: scoreColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question ${widget.index}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(e.feedback.length > 60
                          ? '${e.feedback.substring(0, 60)}...'
                          : e.feedback,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scoreColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${e.score.toStringAsFixed(1)}/10',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scoreColor)),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),

          // ── Expanded Details ─────────────────────────────
          if (_expanded) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Feedback
            Text('📝 Feedback',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(e.feedback,
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.5)),

            if (e.strengths.isNotEmpty) ...[
              const SizedBox(height: 14),
              _TagList(title: '✅ Strengths', items: e.strengths,
                  color: AppColors.success),
            ],
            if (e.weaknesses.isNotEmpty) ...[
              const SizedBox(height: 10),
              _TagList(title: '⚠️ Weaknesses', items: e.weaknesses,
                  color: AppColors.warning),
            ],
            if (e.suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              _TagList(title: '💡 Suggestions', items: e.suggestions,
                  color: AppColors.primary),
            ],
          ],
        ],
      ),
    );
  }
}

class _TagList extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  const _TagList({required this.title, required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items.map((s) => SkillChip(label: s, color: color)).toList(),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
