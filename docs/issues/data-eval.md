# 数据/评估问题

### ISS-013: 训练和验证用同一份数据 [P2] 📝 已知局限
**现象**: 39,597 条数据，5-fold CV 部分缓解。如有新数据到来保留为 holdout set。

### ISS-014: Track2 评估只用了 1000 条子集 [P2] ✅ 已修复
**已修复**: "必须使用完整测试集（禁止子集评估）"。

### ISS-026: 预测文件来源不清导致评估数据混淆 [P1] ✅ 已修复
**已修复**: 产物命名 `predictions_{model}_{version}.npy` + `predictions_meta.json`。

### ISS-027: Release 包 pickle 依赖源码模块路径 [P1] ✅ 已修复
**已修复**: 禁止 pickle 含模块路径，优先 cloudpickle/joblib/ONNX。

### ISS-028: Release README 数据与统一评估结果不一致 [P2] ✅ 已修复
**已修复**: README 性能数据由 eval 脚本自动生成。

### ISS-032: 评估脚本可被 Worker 篡改 [P1] ✅ 已修复
**来源**: autoresearch "评估不可篡改"原则。
**已修复**: eval/ 只读 + gate-check pass 2 md5 seal + check 3 校验。

### ISS-034: 项目无 git init，无法追踪实验历史 [P2] ✅ 已修复
**来源**: autoresearch "Git 即状态机"。
**已修复**: gate-check init 自动 git init + commit + tag。
