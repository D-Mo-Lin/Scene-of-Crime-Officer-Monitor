import 'dart:io';

import 'package:scene_of_crime_officer_monitor/scene_of_crime_officer_monitor.dart';

void main(List<String> args) {
  if (args.length < 2) {
    stdout.writeln('用法: dart run bin/client.dart <question_id> <你的作答文本>');
    exit(1);
  }

  final questionId = args.first;
  final answer = args.skip(1).join(' ');

  final db = QuestionBankDatabase('assets/db/question_bank.sqlite');
  db.open();

  final config = AppConfig.load();
  final embedding = EmbeddingService();
  final rag = RagEngine(db: db, embeddingService: embedding);
  final scoring = ScoringEngine(embedding: embedding);
  final training = TrainingService(db: db, rag: rag, scoring: scoring, config: config);

  final result = training.run(
    questionId: questionId,
    userAnswer: answer,
    pakPath: 'assets/embeddings/question_embeddings.pak',
  );

  stdout.writeln('题目: ${result.question['title']}');
  stdout.writeln('得分: ${result.scoring.totalScore}');
  stdout.writeln('反馈: ${result.scoring.feedback}');
  stdout.writeln('\nRAG参考题 Top3:');
  for (final h in result.ragHits) {
    stdout.writeln(' - ${h.questionId}: sim=${h.similarity.toStringAsFixed(4)} | ${h.stem.substring(0, h.stem.length > 40 ? 40 : h.stem.length)}');
  }

  db.close();
}
