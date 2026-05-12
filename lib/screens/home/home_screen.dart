import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final uid = SupabaseService.currentUserId;
    if (uid == null) return;
    await ref.read(profileProvider.notifier).load(uid);
    await ref.read(resumeProvider.notifier).loadLatest(uid);
    await ref.read(interviewHistoryProvider.notifier).load(uid);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final resumeAsync = ref.watch(resumeProvider);
    final historyAsync = ref.watch(interviewHistoryProvider);

    return Scaffold(
      body: IndexedStack(
        index: _selectedTab,
        children: [
          _DashboardTab(
            profile: profileAsync.valueOrNull,
            resume: resumeAsync.valueOrNull,
            history: historyAsync.valueOrNull ?? [],
            onRefresh: _loadData,
          ),
          const _ResumeTab(),
          const _InterviewTab(),
          const _ProfileTabShell(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.description_outlined),
              activeIcon: Icon(Icons.description),
              label: 'Resume'),
          BottomNavigationBarItem(
              icon: Icon(Icons.mic_none),
              activeIcon: Icon(Icons.mic),
              label: 'Interview'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

// ─── Dashboard Tab ────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final UserProfile? profile;
  final ResumeModel? resume;
  final List<InterviewModel> history;
  final VoidCallback onRefresh;

  const _DashboardTab({
    this.profile,
    this.resume,
    required this.history,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final completed = history.where((i) => i.status == 'completed').toList();
    final avgScore = completed.isEmpty
        ? 0.0
        : completed.fold(0.0, (s, i) => s + (i.overallScore ?? 0)) /
            completed.length;
    final resumeScore = (resume?.analysis?.score ?? 0).toDouble();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Hello, ${profile?.name?.split(' ').first ?? 'there'} 👋',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                    Text(
                      profile?.targetRole ?? 'Complete your profile to get started',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Stats Row ───────────────────────────────
                Row(
                  children: [
                    Expanded(child: _StatCard(
                      label: 'Interviews',
                      value: '${completed.length}',
                      icon: Icons.mic,
                      color: AppColors.primary,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(
                      label: 'Avg Score',
                      value: completed.isEmpty
                          ? '—'
                          : '${avgScore.toStringAsFixed(1)}/10',
                      icon: Icons.star,
                      color: AppColors.warning,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(
                      label: 'Resume',
                      value: resume == null ? '—' : '$resumeScore%',
                      icon: Icons.description,
                      color: AppColors.success,
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Readiness ───────────────────────────────
                if (resume != null || completed.isNotEmpty) ...[
                  AppCard(
                    child: Row(
                      children: [
                        ScoreRing(
                          score: _readiness(resumeScore, avgScore),
                          size: 90,
                          label: 'Ready',
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Interview Readiness',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(
                                _readinessLabel(
                                    _readiness(resumeScore, avgScore)),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: _readiness(resumeScore, avgScore) / 100,
                                backgroundColor: AppColors.divider,
                                color: AppColors.scoreColor(
                                    _readiness(resumeScore, avgScore) / 10),
                                borderRadius: BorderRadius.circular(4),
                                minHeight: 6,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Quick Actions ────────────────────────────
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.description_outlined,
                        label: 'Upload Resume',
                        color: AppColors.primary,
                        onTap: () => context.push('/resume'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.play_circle_outline,
                        label: 'Start Interview',
                        color: AppColors.secondary,
                        onTap: () => context.push('/interview/setup'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Recent Interviews ────────────────────────
                SectionHeader(
                  title: 'Recent Interviews',
                  actionLabel: history.length > 3 ? 'See All' : null,
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  _EmptyState(
                    icon: Icons.mic_none,
                    message: 'No interviews yet.\nStart your first mock interview!',
                    actionLabel: 'Start Interview',
                    onAction: () => context.push('/interview/setup'),
                  )
                else
                  ...history.take(5).map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InterviewHistoryCard(
                          role: i.jobRole,
                          type: i.interviewType,
                          score: i.overallScore,
                          status: i.status,
                          date: i.createdAt,
                          onTap: i.status == 'completed'
                              ? () => context.push('/interview/evaluation',
                                  extra: i.id)
                              : null,
                        ),
                      )),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  double _readiness(double resumeScore, double avgScore) {
    if (resumeScore == 0 && avgScore == 0) return 0;
    if (resumeScore == 0) return avgScore * 10;
    if (avgScore == 0) return resumeScore;
    return (resumeScore + avgScore * 10) / 2;
  }

  String _readinessLabel(double score) {
    if (score >= 75) return 'You\'re well prepared! Keep it up.';
    if (score >= 50) return 'Good progress. Practice more!';
    return 'Just getting started. Keep going!';
  }
}

// ─── Stat Card ────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyState(
      {required this.icon,
      required this.message,
      required this.actionLabel,
      required this.onAction});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Shell Delegates (navigate to full screens) ───────────
class _ResumeTab extends StatelessWidget {
  const _ResumeTab();
  @override
  Widget build(BuildContext context) {
    // Navigate immediately when tab is tapped — using a shell approach
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.push('/resume'));
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _InterviewTab extends StatelessWidget {
  const _InterviewTab();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.push('/interview/setup'));
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileTabShell extends StatelessWidget {
  const _ProfileTabShell();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.push('/profile'));
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
