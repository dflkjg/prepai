import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/app_models.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService(String apiKey)
      : _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );

  // ── Resume Analysis ───────────────────────────────────────
  /// Send raw PDF bytes directly to Gemini for analysis.
  Future<ResumeAnalysis> analyzeResume(Uint8List pdfBytes) async {
    const prompt = '''
You are a professional resume reviewer. Analyze this resume carefully and return ONLY a valid JSON object with this exact structure (no markdown, no extra text):
{
  "score": <integer 0-100>,
  "skills": ["skill1", "skill2"],
  "education": ["degree and institution"],
  "experience": ["job title at company - duration"],
  "suggestions": ["specific improvement suggestion"],
  "weak_areas": ["area that needs improvement"],
  "summary": "2-3 sentence professional summary of the candidate"
}
''';

    final content = Content.multi([
      DataPart('application/pdf', pdfBytes),
      TextPart(prompt),
    ]);

    final response = await _model.generateContent([content]);
    final text = response.text ?? '{}';
    final json = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
    return ResumeAnalysis.fromJson(json);
  }

  // ── Interview Question Generation ─────────────────────────
  Future<List<String>> generateQuestions({
    required String jobRole,
    required String industry,
    required String experienceLevel,
    required String interviewType,
  }) async {
    final prompt = '''
Generate exactly 8 ${interviewType} interview questions for:
- Job Role: $jobRole
- Industry: $industry
- Experience Level: $experienceLevel

Return ONLY a valid JSON array of 8 question strings. No markdown, no extra text.
Example: ["Question 1?", "Question 2?"]
''';

    final response =
        await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '[]';
    final list = jsonDecode(_cleanJson(text)) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  // ── Answer Evaluation ────────────────────────────────────
  Future<EvaluationResult> evaluateAnswer({
    required String question,
    required String answer,
    String? resumeContext,
  }) async {
    final prompt = '''
You are an expert interviewer. Evaluate this interview answer objectively.

Question: $question
Answer: $answer
${resumeContext != null ? 'Candidate Background: $resumeContext' : ''}

Return ONLY a valid JSON object (no markdown):
{
  "score": <number 0-10>,
  "feedback": "detailed constructive feedback in 2-3 sentences",
  "strengths": ["strength point"],
  "weaknesses": ["weakness point"],
  "suggestions": ["improvement suggestion"]
}
''';

    final response =
        await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '{}';
    final json = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
    return EvaluationResult.fromJson(json);
  }

  // ── Helper ───────────────────────────────────────────────
  String _cleanJson(String raw) {
    // Strip markdown code fences if present
    final fenceRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = fenceRegex.firstMatch(raw);
    return match != null ? match.group(1)! : raw.trim();
  }
}

/// Lightweight result object for a single answer evaluation.
class EvaluationResult {
  final double score;
  final String feedback;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;

  const EvaluationResult({
    required this.score,
    required this.feedback,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
  });

  factory EvaluationResult.fromJson(Map<String, dynamic> json) =>
      EvaluationResult(
        score: (json['score'] as num?)?.toDouble() ?? 0,
        feedback: (json['feedback'] as String?) ?? '',
        strengths: _list(json['strengths']),
        weaknesses: _list(json['weaknesses']),
        suggestions: _list(json['suggestions']),
      );

  static List<String> _list(dynamic v) =>
      v == null ? [] : List<String>.from(v as List);
}
