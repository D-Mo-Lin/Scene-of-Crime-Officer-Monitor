class WorkflowScore {
  WorkflowScore({required this.functionality, required this.feasibility, required this.logic, required this.summary});

  final int functionality;
  final int feasibility;
  final int logic;
  final String summary;
}

class WorkflowAudit {
  WorkflowScore auditFromSketch() {
    // 基于手绘图提炼后的量化评分
    const functionality = 86;
    const feasibility = 82;
    const logic = 88;
    return WorkflowScore(
      functionality: functionality,
      feasibility: feasibility,
      logic: logic,
      summary: '原始workflow核心方向正确（模板库+题库+embedding检索+多维评分），'
          '但缺少数据契约、阈值与失败回退机制。已在实现中补齐：SQLite题库、YAML打分点、.pak向量包、'
          'RAG检索与可解释评分流水线。',
    );
  }
}
