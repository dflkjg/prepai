// ── Data Models ───────────────────────────────────────────────

// UserProfile
class UserProfile {
  final String id;
  final String? name;
  final String? email;
  final String? targetRole;
  final String? industry;
  final String? experienceLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    this.name,
    this.email,
    this.targetRole,
    this.industry,
    this.experienceLevel,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String?,
        email: json['email'] as String?,
        targetRole: json['target_role'] as String?,
        industry: json['industry'] as String?,
        experienceLevel: json['experience_level'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'target_role': targetRole,
        'industry': industry,
        'experience_level': experienceLevel,
      };

  UserProfile copyWith({
    String? name,
    String? email,
    String? targetRole,
    String? industry,
    String? experienceLevel,
  }) =>
      UserProfile(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        targetRole: targetRole ?? this.targetRole,
        industry: industry ?? this.industry,
        experienceLevel: experienceLevel ?? this.experienceLevel,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  bool get isComplete =>
      name != null &&
      targetRole != null &&
      industry != null &&
      experienceLevel != null;
}

// ── ResumeAnalysis ────────────────────────────────────────────
class ResumeAnalysis {
  final int score;
  final List<String> skills;
  final List<String> education;
  final List<String> experience;
  final List<String> suggestions;
  final List<String> weakAreas;
  final String summary;

  const ResumeAnalysis({
    required this.score,
    required this.skills,
    required this.education,
    required this.experience,
    required this.suggestions,
    required this.weakAreas,
    required this.summary,
  });

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) => ResumeAnalysis(
        score: (json['score'] as num?)?.toInt() ?? 0,
        skills: _toStringList(json['skills']),
        education: _toStringList(json['education']),
        experience: _toStringList(json['experience']),
        suggestions: _toStringList(json['suggestions']),
        weakAreas: _toStringList(json['weak_areas']),
        summary: (json['summary'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'skills': skills,
        'education': education,
        'experience': experience,
        'suggestions': suggestions,
        'weak_areas': weakAreas,
        'summary': summary,
      };

  static List<String> _toStringList(dynamic v) =>
      v == null ? [] : List<String>.from(v as List);
}

// ── ResumeModel ───────────────────────────────────────────────
class ResumeModel {
  final String id;
  final String userId;
  final String? fileName;
  final String? fileUrl;
  final ResumeAnalysis? analysis;
  final DateTime? createdAt;

  const ResumeModel({
    required this.id,
    required this.userId,
    this.fileName,
    this.fileUrl,
    this.analysis,
    this.createdAt,
  });

  factory ResumeModel.fromJson(Map<String, dynamic> json) => ResumeModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        fileName: json['file_name'] as String?,
        fileUrl: json['file_url'] as String?,
        analysis: json['analysis'] != null
            ? ResumeAnalysis.fromJson(
                Map<String, dynamic>.from(json['analysis'] as Map))
            : null,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );
}

// ── InterviewModel ────────────────────────────────────────────
class InterviewModel {
  final String id;
  final String userId;
  final String jobRole;
  final String industry;
  final String experienceLevel;
  final String interviewType;
  final String status;
  final double? overallScore;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const InterviewModel({
    required this.id,
    required this.userId,
    required this.jobRole,
    required this.industry,
    required this.experienceLevel,
    required this.interviewType,
    this.status = 'pending',
    this.overallScore,
    this.createdAt,
    this.completedAt,
  });

  factory InterviewModel.fromJson(Map<String, dynamic> json) => InterviewModel(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        jobRole: (json['job_role'] as String?) ?? '',
        industry: (json['industry'] as String?) ?? '',
        experienceLevel: (json['experience_level'] as String?) ?? '',
        interviewType: (json['interview_type'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'pending',
        overallScore: (json['overall_score'] as num?)?.toDouble(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );
}

// ── QuestionModel ─────────────────────────────────────────────
class QuestionModel {
  final String id;
  final String interviewId;
  final String questionText;
  final int orderIndex;

  const QuestionModel({
    required this.id,
    required this.interviewId,
    required this.questionText,
    required this.orderIndex,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
        id: json['id'] as String,
        interviewId: json['interview_id'] as String,
        questionText: (json['question_text'] as String?) ?? '',
        orderIndex: (json['order_index'] as int?) ?? 0,
      );
}

// ── AnswerModel ───────────────────────────────────────────────
class AnswerModel {
  final String id;
  final String questionId;
  final String userId;
  final String answerText;

  const AnswerModel({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.answerText,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) => AnswerModel(
        id: json['id'] as String,
        questionId: json['question_id'] as String,
        userId: json['user_id'] as String,
        answerText: (json['answer_text'] as String?) ?? '',
      );
}

// ── EvaluationModel ───────────────────────────────────────────
class EvaluationModel {
  final String id;
  final String answerId;
  final double score;
  final String feedback;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> suggestions;

  const EvaluationModel({
    required this.id,
    required this.answerId,
    required this.score,
    required this.feedback,
    required this.strengths,
    required this.weaknesses,
    required this.suggestions,
  });

  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      EvaluationModel(
        id: json['id'] as String,
        answerId: json['answer_id'] as String,
        score: (json['score'] as num?)?.toDouble() ?? 0,
        feedback: (json['feedback'] as String?) ?? '',
        strengths: _toList(json['strengths']),
        weaknesses: _toList(json['weaknesses']),
        suggestions: _toList(json['suggestions']),
      );

  static List<String> _toList(dynamic v) =>
      v == null ? [] : List<String>.from(v as List);
}
