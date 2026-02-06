import 'dart:io';

import 'package:scene_of_crime_officer_monitor/src/database.dart';
import 'package:scene_of_crime_officer_monitor/src/embedding.dart';

class RagHit {
  RagHit({required this.questionId, required this.similarity, required this.stem});
  final String questionId;
  final double similarity;
  final String stem;
}

class RagEngine {
  RagEngine({required this.db, required this.embeddingService});

  final QuestionBankDatabase db;
  final EmbeddingService embeddingService;

  List<RagHit> retrieve({required String query, required String pakPath, int topK = 3}) {
    final pak = EmbeddingPak.fromPakBytes(File(pakPath).readAsBytesSync());
    final q = embeddingService.embed(query);
    final questions = db.listQuestions();
    final byId = {for (final r in pak.records) r.id: r.vector};

    final hits = <RagHit>[];
    for (final row in questions) {
      final id = row['id'] as String;
      final v = byId[id];
      if (v == null) continue;
      hits.add(
        RagHit(
          questionId: id,
          similarity: embeddingService.cosine(q, v),
          stem: row['stem'] as String,
        ),
      );
    }

    hits.sort((a, b) => b.similarity.compareTo(a.similarity));
    return hits.take(topK).toList();
  }
}
