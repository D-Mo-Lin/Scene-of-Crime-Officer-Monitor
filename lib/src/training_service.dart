import 'package:scene_of_crime_officer_monitor/scene_of_crime_officer_monitor.dart';

class TrainingResult {
  TrainingResult({required this.question, required this.ragHits, required this.scoring});

  final Map<String, Object?> question;
  final List<RagHit> ragHits;
  final ScoringResult scoring;
}

class TrainingService {
  TrainingService({
    required this.db,
    required this.rag,
    required this.scoring,
    required this.config,
  });

  final QuestionBankDatabase db;
  final RagEngine rag;
  final ScoringEngine scoring;
  final AppConfig config;

  TrainingResult run({
    required String questionId,
    required String userAnswer,
    required String pakPath,
  }) {
    final q = db.getQuestion(questionId);
    if (q == null) {
      throw StateError('question not found: $questionId');
    }
    final stem = q['stem'] as String;
    final standard = q['standard_answer'] as String;
    final hits = rag.retrieve(query: '$stem\n$userAnswer', pakPath: pakPath, topK: 3);
    final result = scoring.evaluate(userAnswer: userAnswer, standardAnswer: standard, points: config.scoringPoints);

    db.insertAttempt(
      questionId: questionId,
      userAnswer: userAnswer,
      totalScore: result.totalScore,
      scoreDetailJson: result.toJsonString(),
    );

    return TrainingResult(question: q, ragHits: hits, scoring: result);
  }
}
