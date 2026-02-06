import 'dart:io';

import 'package:yaml/yaml.dart';

class ScoringPoint {
  ScoringPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.weight,
    required this.keywords,
    required this.analysisLevel,
  });

  final String id;
  final String name;
  final String description;
  final double weight;
  final List<String> keywords;
  final int analysisLevel;
}

class ScenarioTemplate {
  ScenarioTemplate({
    required this.id,
    required this.title,
    required this.background,
    required this.difficulty,
    required this.tags,
  });

  final String id;
  final String title;
  final String background;
  final int difficulty;
  final List<String> tags;
}

class AppConfig {
  AppConfig({
    required this.scoringPoints,
    required this.templates,
  });

  final List<ScoringPoint> scoringPoints;
  final List<ScenarioTemplate> templates;

  static AppConfig load({
    String scoringYaml = 'assets/yaml/scoring_points.yaml',
    String templateYaml = 'assets/yaml/case_templates.yaml',
  }) {
    final scoringDoc = loadYaml(File(scoringYaml).readAsStringSync()) as YamlMap;
    final templateDoc = loadYaml(File(templateYaml).readAsStringSync()) as YamlMap;

    final points = (scoringDoc['points'] as YamlList)
        .map((raw) => raw as YamlMap)
        .map(
          (m) => ScoringPoint(
            id: m['id'] as String,
            name: m['name'] as String,
            description: m['description'] as String,
            weight: (m['weight'] as num).toDouble(),
            keywords: (m['keywords'] as YamlList).cast<String>().toList(),
            analysisLevel: m['analysis_level'] as int,
          ),
        )
        .toList();

    final templates = (templateDoc['templates'] as YamlList)
        .map((raw) => raw as YamlMap)
        .map(
          (m) => ScenarioTemplate(
            id: m['id'] as String,
            title: m['title'] as String,
            background: m['background'] as String,
            difficulty: m['difficulty'] as int,
            tags: (m['tags'] as YamlList).cast<String>().toList(),
          ),
        )
        .toList();

    return AppConfig(scoringPoints: points, templates: templates);
  }
}
