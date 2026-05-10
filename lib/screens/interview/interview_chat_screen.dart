import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_widgets.dart';

class InterviewChatScreen extends ConsumerStatefulWidget {
  final String interviewId;
  const InterviewChatScreen({super.key, required this.interviewId});
  @override
  ConsumerState<InterviewChatScreen> createState() =>
      _InterviewChatScreenState();
}

class _InterviewChatScreenState
    extends ConsumerState<InterviewChatScreen> {
  final _answerCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<QuestionModel> _questions = [];
  final List<AnswerModel> _answers = [];
  int _currentIndex = 0;
  bool _loadingQuestions = true;
  bool _submitting = false;
  bool _finishing = false;
  String? _error;

  // Chat messages: {type: 'ai'|'user', text: ''}
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final qs = await ref
          .read(interviewServiceProvider)
          .fetchQuestions(widget.interviewId);
      setState(() {
        _questions = qs;
        _loadingQuestions = false;
        if (qs.isNotEmpty) {
          _messages.add({'type': 'ai', 'text': qs[0].questionText});
        }
      });
    } catch (e) {
      setState(() { _error = 'Failed to load questions.'; _loadingQuestions = false; });
    }
  }

  Future<void> _submitAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;

    final uid = SupabaseService.currentUserId!;
    final question = _questions[_currentIndex];

    setState(() { _submitting = true; _error = null; });

    // Add user message
    setState(() => _messages.add({'type': 'user', 'text': text}));
    _answerCtrl.clear();
    _scrollToBottom();

    try {
      final answer = await ref.read(interviewServiceProvider).submitAnswer(
            questionId: question.id,
            userId: uid,
            answerText: text,
          );
      _answers.add(answer);

      final isLast = _currentIndex >= _questions.length - 1;
      if (isLast) {
        setState(() => _messages.add({
              'type': 'ai',
              'text':
                  "Great job! 🎉 You've answered all ${_questions.length} questions. Tap 'Finish Interview' to see your evaluation."
            }));
      } else {
        setState(() {
          _currentIndex++;
          _messages.add({
            'type': 'ai',
            'text': _questions[_currentIndex].questionText
          });
        });
      }
      _scrollToBottom();
    } catch (e) {
      setState(() => _error = 'Could not submit answer. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _finishInterview() async {
    setState(() => _finishing = true);
    try {
      final uid = SupabaseService.currentUserId!;
      final resume = ref.read(resumeProvider).valueOrNull;
      final resumeCtx = resume?.analysis?.summary;

      // Evaluate all answers
      final evaluations = await ref
          .read(interviewServiceProvider)
          .evaluateInterview(
            questions: _questions,
            answers: _answers,
            resumeSummary: resumeCtx,
          );

      // Calculate overall score
      final avg = evaluations.isEmpty
          ? 0.0
          : evaluations.fold(0.0, (s, e) => s + e.score) / evaluations.length;

      await ref
          .read(interviewServiceProvider)
          .completeInterview(widget.interviewId, avg);

      // Refresh history
      await ref.read(interviewHistoryProvider.notifier).load(uid);

      if (mounted) {
        context.go('/interview/evaluation', extra: widget.interviewId);
      }
    } catch (e) {
      setState(() {
        _finishing = false;
        _error = 'Evaluation failed. Please try again.';
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _answerCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool get _allAnswered => _answers.length >= _questions.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Mock Interview',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            if (_questions.isNotEmpty)
              Text(
                'Q${_currentIndex + 1} of ${_questions.length}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
        leading: BackButton(onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Exit Interview?'),
              content: const Text(
                  'Your progress will be lost if you exit now.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.go('/home');
                    },
                    child: const Text('Exit',
                        style: TextStyle(color: AppColors.error))),
              ],
            ),
          );
        }),
        bottom: _questions.isNotEmpty
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: _questions.isEmpty
                      ? 0
                      : (_answers.length / _questions.length),
                  backgroundColor: AppColors.divider,
                  color: AppColors.primary,
                  minHeight: 4,
                ),
              )
            : null,
      ),
      body: _loadingQuestions
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Loading questions...',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // ── Messages ──────────────────────────
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final msg = _messages[i];
                          final isAI = msg['type'] == 'ai';
                          return _ChatBubble(
                            text: msg['text']!,
                            isAI: isAI,
                            questionNumber: isAI
                                ? _getQuestionNumber(i)
                                : null,
                          );
                        },
                      ),
                    ),

                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 12)),
                      ),

                    // ── Input ─────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, -2))
                        ],
                      ),
                      child: _allAnswered
                          ? GradientButton(
                              label: 'Finish & View Evaluation',
                              onPressed: _finishInterview,
                              isLoading: _finishing,
                              icon: Icons.assessment_outlined,
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _answerCtrl,
                                    maxLines: 3,
                                    minLines: 1,
                                    decoration: InputDecoration(
                                      hintText: 'Type your answer...',
                                      hintStyle: const TextStyle(
                                          color: AppColors.textHint,
                                          fontSize: 14),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.divider),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.divider),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: AppColors.primary,
                                            width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _submitting ? null : _submitAnswer,
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                            color: AppColors.primary
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3))
                                      ],
                                    ),
                                    child: _submitting
                                        ? const Padding(
                                            padding: EdgeInsets.all(12),
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.send,
                                            color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                if (_finishing)
                  const LoadingOverlay(
                      message:
                          'Evaluating your answers with AI...\nThis may take a moment.'),
              ],
            ),
    );
  }

  int? _getQuestionNumber(int messageIndex) {
    int count = 0;
    for (int i = 0; i <= messageIndex; i++) {
      if (_messages[i]['type'] == 'ai') count++;
    }
    return count;
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isAI;
  final int? questionNumber;

  const _ChatBubble({required this.text, required this.isAI, this.questionNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isAI ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                if (isAI && questionNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      questionNumber! <= 8
                          ? 'Question $questionNumber'
                          : 'PrepAI',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isAI ? AppColors.primaryGradient : null,
                    color: isAI ? null : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft:
                          Radius.circular(isAI ? 4 : 16),
                      bottomRight:
                          Radius.circular(isAI ? 16 : 4),
                    ),
                    border: isAI
                        ? null
                        : Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                          color: (isAI ? AppColors.primary : AppColors.black)
                              .withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isAI ? Colors.white : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isAI) ...[
            const SizedBox(width: 8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person_outline,
                  color: AppColors.primary, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}
