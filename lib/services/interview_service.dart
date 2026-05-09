import '../models/app_models.dart';
import 'supabase_service.dart';
import 'gemini_service.dart';

class InterviewService {
  final _db = SupabaseService.client;
  final GeminiService _gemini;

  InterviewService(this._gemini);

  // ── Create Interview & Questions ─────────────────────────
  Future<InterviewModel> createInterview({
    required String userId,
    required String jobRole,
    required String industry,
    required String experienceLevel,
    required String interviewType,
  }) async {
    // 1. Generate questions via Gemini
    final questions = await _gemini.generateQuestions(
      jobRole: jobRole,
      industry: industry,
      experienceLevel: experienceLevel,
      interviewType: interviewType,
    );

    // 2. Insert interview record
    final interviewData = await _db.from('interviews').insert({
      'user_id': userId,
      'job_role': jobRole,
      'industry': industry,
      'experience_level': experienceLevel,
      'interview_type': interviewType,
      'status': 'pending',
    }).select().single();

    final interview = InterviewModel.fromJson(interviewData);

    // 3. Insert questions
    for (var i = 0; i < questions.length; i++) {
      await _db.from('questions').insert({
        'interview_id': interview.id,
        'question_text': questions[i],
        'order_index': i,
      });
    }

    return interview;
  }

  // ── Fetch Questions ───────────────────────────────────────
  Future<List<QuestionModel>> fetchQuestions(String interviewId) async {
    final data = await _db
        .from('questions')
        .select()
        .eq('interview_id', interviewId)
        .order('order_index');
    return (data as List)
        .map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Submit Answer ─────────────────────────────────────────
  Future<AnswerModel> submitAnswer({
    required String questionId,
    required String userId,
    required String answerText,
  }) async {
    final data = await _db.from('answers').insert({
      'question_id': questionId,
      'user_id': userId,
      'answer_text': answerText,
    }).select().single();
    return AnswerModel.fromJson(data);
  }

  // ── Evaluate All Answers ──────────────────────────────────
  Future<List<EvaluationModel>> evaluateInterview({
    required List<QuestionModel> questions,
    required List<AnswerModel> answers,
    String? resumeSummary,
  }) async {
    final evaluations = <EvaluationModel>[];

    for (var i = 0; i < answers.length; i++) {
      final q = questions.firstWhere((q) => q.id == answers[i].questionId,
          orElse: () => questions[i]);

      final result = await _gemini.evaluateAnswer(
        question: q.questionText,
        answer: answers[i].answerText,
        resumeContext: resumeSummary,
      );

      final evalData = await _db.from('evaluations').insert({
        'answer_id': answers[i].id,
        'score': result.score,
        'feedback': result.feedback,
        'strengths': result.strengths,
        'weaknesses': result.weaknesses,
        'suggestions': result.suggestions,
      }).select().single();

      evaluations.add(EvaluationModel.fromJson(evalData));
    }

    return evaluations;
  }

  // ── Complete Interview ────────────────────────────────────
  Future<void> completeInterview(
      String interviewId, double overallScore) async {
    await _db.from('interviews').update({
      'status': 'completed',
      'overall_score': overallScore,
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', interviewId);
  }

  // ── Fetch History ─────────────────────────────────────────
  Future<List<InterviewModel>> fetchHistory(String userId) async {
    final data = await _db
        .from('interviews')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (data as List)
        .map((e) => InterviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch Evaluations for Interview ──────────────────────
  Future<List<EvaluationModel>> fetchEvaluations(
      String interviewId) async {
    final data = await _db
        .from('evaluations')
        .select('*, answers!inner(question_id, questions!inner(interview_id))')
        .eq('answers.questions.interview_id', interviewId);
    return (data as List)
        .map((e) => EvaluationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
