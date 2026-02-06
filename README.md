# Scene-of-Crime-Officer-Monitor

文本语境下的现场处置培训系统（Server + Client 双程序，CLI 版）。

## 项目目标

- **Server**：交互式设计题库、打分点、发题与判题基础数据。
- **Client**：用户做题、查看评分、答案解析与RAG参考。
- **软硬编码分离**：模板/评分点全部放在 YAML；题库存 SQLite；向量库存 `.pak`。

## 技术实现

- 语言：Dart（Flutter 生态可直接复用）。
- 数据存储：SQLite（`assets/db/question_bank.sqlite`）。
- 配置数据：YAML（`assets/yaml/*.yaml`）。
- 向量包：自定义二进制 `.pak`（header + payload）。

## 目录说明

- `bin/server.dart`：题库初始化、模板导入、向量包构建、workflow审计。
- `bin/client.dart`：用户作答评分 + RAG 检索。
- `lib/src/*`：核心能力（DB、Embedding、RAG、评分、训练流程）。
- `docs/workflow_from_sketch.md`：手绘图识别修复、workflow细化、打分。

## 快速开始

```bash
dart pub get
dart run bin/server.dart init-db
dart run bin/server.dart seed
dart run bin/server.dart build-pak
dart run bin/server.dart list
dart run bin/server.dart audit
```

执行一次作答训练：

```bash
dart run bin/client.dart CASE001 "我会先控现场并隔离风险源，组织伤者分级救治，固定证据并依法告知，随后向指挥中心上报并组织复盘。"
```

## 评分算法（实现版）

每个打分点总权重 20，共 5 个点（总权重 100）：

- 命中率 = 关键词覆盖率
- 语义基线 = 与标准答案 embedding cosine（归一化）
- 分层系数 = `1 + (analysis_level - 1) * 0.1`
- 分点得分 = `(0.65*关键词 + 0.35*语义) * 分层系数 * 权重`
- 总分 = `Σ分点得分 / Σ权重 * 100`

## 全量审计清单

1. `dart analyze` 通过。
2. `dart test` 通过。
3. Server/Client 主流程命令可运行。
4. YAML / SQLite / `.pak` 三类数据链路一致。

## Flutter 运行环境说明

已在构建过程中自动部署 Flutter SDK（3.24.5 对应 Dart 3.5.4），本项目当前以 CLI 模式实现核心能力，后续可无缝扩展 UI。
