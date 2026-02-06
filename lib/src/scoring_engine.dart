import 'dart:convert';

import 'package:scene_of_crime_officer_monitor/src/config_models.dart';
import 'package:scene_of_crime_officer_monitor/src/embedding.dart';

class PointScore {
  PointScore({
    required this.pointId,
    required this.pointName,
    required this.hitRate,
    required this.weight,
    required this.score,
  });

  final String pointId;
  final String pointName;
  final double hitRate;
  final double weight;
  final double score;

  Map<String, dynamic> toJson() => {
        'point_id': pointId,
        'point_name': pointName,
        'hit_rate': hitRate,
        'weight': weight,
        'score': score,
      };
}

class ScoringResult {
  ScoringResult({required this.totalScore, required this.items, required this.feedback});

  final double totalScore;
  final List<PointScore> items;
  final String feedback;

  String toJsonString() => jsonEncode({
        'total_score': totalScore,
        'items': items.map((e) => e.toJson()).toList(),
        'feedback': feedback,
      });
}

class ScoringEngine {
  ScoringEngine({required this.embedding});
  final EmbeddingService embedding;

  ScoringResult evaluate({
    required String userAnswer,
    required String standardAnswer,
    required List<ScoringPoint> points,
  }) {
    final userLower = userAnswer.toLowerCase();
    final stdEmb = embedding.embed(standardAnswer);
    final userEmb = embedding.embed(userAnswer);
    final semanticBase = (embedding.cosine(stdEmb, userEmb) + 1) / 2;

    final itemScores = <PointScore>[];
    double totalWeight = 0;
    double weighted = 0;

    for (final p in points) {
      final hits = p.keywords.where((k) => userLower.contains(k.toLowerCase())).length;
      final keywordRate = p.keywords.isEmpty ? 1.0 : hits / p.keywords.length;
      final levelBoost = 1 + (p.analysisLevel - 1) * 0.1;
      final hitRate = (0.65 * keywordRate + 0.35 * semanticBase) * levelBoost;
      final normalizedHit = hitRate.clamp(0, 1).toDouble();
      final score = normalizedHit * p.weight;
      totalWeight += p.weight;
      weighted += score;
      itemScores.add(
        PointScore(
          pointId: p.id,
          pointName: p.name,
          hitRate: normalizedHit,
          weight: p.weight,
          score: score,
        ),
      );
    }

    final total = totalWeight == 0 ? 0 : (weighted / totalWeight * 100);
    final feedback = total >= 85
        ? '处置流程完整，语义与关键处置点覆盖良好。'
        : total >= 60
            ? '具备基本处置能力，但存在关键步骤缺失，请重点补齐高权重处置点。'
            : '处置方案风险较高，建议回看标准流程并进行专项训练。';

    return ScoringResult(totalScore: double.parse(total.toStringAsFixed(2)), items: itemScores, feedback: feedback);
  }
}
