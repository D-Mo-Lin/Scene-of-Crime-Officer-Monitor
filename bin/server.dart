import 'dart:io';

import 'package:args/args.dart';
import 'package:scene_of_crime_officer_monitor/scene_of_crime_officer_monitor.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addCommand('init-db')
    ..addCommand('seed')
    ..addCommand('build-pak')
    ..addCommand('list')
    ..addCommand('audit');

  final result = parser.parse(args);
  final db = QuestionBankDatabase('assets/db/question_bank.sqlite');
  db.open();
  final embedding = EmbeddingService();

  switch (result.command?.name) {
    case 'init-db':
      stdout.writeln('数据库初始化完成: assets/db/question_bank.sqlite');
      break;
    case 'seed':
      final config = AppConfig.load();
      for (final t in config.templates) {
        db.upsertQuestion(
          id: t.id,
          title: t.title,
          stem: t.background,
          standardAnswer: '到场先控现场与风险源，分级处置伤者并固定证据，回传指挥中心并依法告知。',
          difficulty: t.difficulty,
          tags: t.tags,
          sourceType: 'template',
        );
      }
      stdout.writeln('已导入模板题目: ${config.templates.length} 条');
      break;
    case 'build-pak':
      final rows = db.listQuestions();
      final records = rows
          .map((r) => EmbeddingRecord(r['id'] as String, embedding.embed('${r['title']}\n${r['stem']}')))
          .toList();
      final pak = EmbeddingPak(model: embedding.model, dimension: embedding.dimension, records: records);
      File('assets/embeddings/question_embeddings.pak').writeAsBytesSync(pak.toPakBytes());
      stdout.writeln('向量包已生成: assets/embeddings/question_embeddings.pak (${records.length} records)');
      break;
    case 'list':
      final rows = db.listQuestions();
      for (final r in rows) {
        stdout.writeln('[${r['id']}] ${r['title']} (D${r['difficulty']}) tags=${r['tags']}');
      }
      break;
    case 'audit':
      final audit = WorkflowAudit().auditFromSketch();
      stdout.writeln('功能性: ${audit.functionality}/100');
      stdout.writeln('可落地性: ${audit.feasibility}/100');
      stdout.writeln('逻辑正确性: ${audit.logic}/100');
      stdout.writeln('结论: ${audit.summary}');
      break;
    default:
      stdout.writeln('用法: dart run bin/server.dart <init-db|seed|build-pak|list|audit>');
  }

  db.close();
}
