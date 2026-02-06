import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

class QuestionBankDatabase {
  QuestionBankDatabase(this.path);

  final String path;
  late Database _db;

  void open() {
    final dir = Directory(p.dirname(path));
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _db = sqlite3.open(path);
    _db.execute('''
      CREATE TABLE IF NOT EXISTS question_bank (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        stem TEXT NOT NULL,
        standard_answer TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        tags TEXT NOT NULL,
        source_type TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');

    _db.execute('''
      CREATE TABLE IF NOT EXISTS training_attempt (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT NOT NULL,
        user_answer TEXT NOT NULL,
        total_score REAL NOT NULL,
        score_detail_json TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    ''');
  }

  void close() => _db.dispose();

  void upsertQuestion({
    required String id,
    required String title,
    required String stem,
    required String standardAnswer,
    required int difficulty,
    required List<String> tags,
    required String sourceType,
  }) {
    _db.execute(
      '''
      INSERT INTO question_bank (id, title, stem, standard_answer, difficulty, tags, source_type, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, datetime('now'))
      ON CONFLICT(id) DO UPDATE SET
        title=excluded.title,
        stem=excluded.stem,
        standard_answer=excluded.standard_answer,
        difficulty=excluded.difficulty,
        tags=excluded.tags,
        source_type=excluded.source_type;
      ''',
      [id, title, stem, standardAnswer, difficulty, tags.join(','), sourceType],
    );
  }

  List<Map<String, Object?>> listQuestions() {
    final rs = _db.select('SELECT * FROM question_bank ORDER BY created_at DESC');
    final names = rs.columnNames;
    return rs
        .map((r) => {
              for (var i = 0; i < names.length; i++) names[i]: r[names[i]],
            })
        .toList();
  }

  Map<String, Object?>? getQuestion(String id) {
    final rs = _db.select('SELECT * FROM question_bank WHERE id = ?', [id]);
    if (rs.isEmpty) return null;
    final row = rs.first;
    final names = rs.columnNames;
    return {
      for (var i = 0; i < names.length; i++) names[i]: row[names[i]],
    };
  }

  void insertAttempt({
    required String questionId,
    required String userAnswer,
    required double totalScore,
    required String scoreDetailJson,
  }) {
    _db.execute(
      '''
      INSERT INTO training_attempt (question_id, user_answer, total_score, score_detail_json, created_at)
      VALUES (?, ?, ?, ?, datetime('now'))
      ''',
      [questionId, userAnswer, totalScore, scoreDetailJson],
    );
  }
}
