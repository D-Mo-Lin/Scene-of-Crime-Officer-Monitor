import 'dart:io';

import 'package:scene_of_crime_officer_monitor/scene_of_crime_officer_monitor.dart';
import 'package:test/test.dart';

void main() {
  test('embedding pak encode/decode', () {
    final s = EmbeddingService();
    final pak = EmbeddingPak(model: s.model, dimension: s.dimension, records: [EmbeddingRecord('A', s.embed('hello'))]);
    final bytes = pak.toPakBytes();
    final decoded = EmbeddingPak.fromPakBytes(bytes);
    expect(decoded.records.first.id, 'A');
    expect(decoded.dimension, s.dimension);
  });

  test('scoring should be higher for richer answer', () {
    final cfg = AppConfig.load();
    final engine = ScoringEngine(embedding: EmbeddingService());
    final rich = engine.evaluate(
      userAnswer: '先控现场风险，救治伤员并分级转运，固定证据依法告知并上报联动复盘。',
      standardAnswer: '到场先控现场与风险源，分级处置伤者并固定证据，回传指挥中心并依法告知。',
      points: cfg.scoringPoints,
    );
    final poor = engine.evaluate(
      userAnswer: '我先看看情况。',
      standardAnswer: '到场先控现场与风险源，分级处置伤者并固定证据，回传指挥中心并依法告知。',
      points: cfg.scoringPoints,
    );
    expect(rich.totalScore, greaterThan(poor.totalScore));
  });

  test('server pipeline basic', () {
    final dbPath = 'assets/db/test_question_bank.sqlite';
    final db = QuestionBankDatabase(dbPath)..open();
    db.upsertQuestion(
      id: 'T1',
      title: 't1',
      stem: 's1',
      standardAnswer: '控现场 救治 证据 依法 上报',
      difficulty: 1,
      tags: ['a'],
      sourceType: 'test',
    );
    final emb = EmbeddingService();
    final pak = EmbeddingPak(model: emb.model, dimension: emb.dimension, records: [EmbeddingRecord('T1', emb.embed('t1 s1'))]);
    File('assets/embeddings/test.pak').writeAsBytesSync(pak.toPakBytes());
    final rag = RagEngine(db: db, embeddingService: emb);
    final hits = rag.retrieve(query: 's1', pakPath: 'assets/embeddings/test.pak', topK: 1);
    expect(hits, hasLength(1));
    db.close();
  });
}
