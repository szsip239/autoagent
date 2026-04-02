# Worker 执行质量问题

### ISS-004: Worker 使用过时 API 知识 [P1] ✅ 已部分修复
**已修复**: CLAUDE.md 和模板加"先查官方文档再写代码"。无运行时强制。

### ISS-005: Worker 训练步数/参数选择不合理 [P2] ✅ 已修复
**已修复**: ORCHESTRATION Worker prompt 加"经验法则"：至少 2-3 完整 epoch + 先跑 loss 曲线。

---

## 调研/POC 流程复盘

### ISS-055: 中文场景调研必须优先搜索中文技术生态 [P1] ✅ 已修复
**现象**: 验证码识别调研主搜英文 GitHub/PyPI 全部失败，CSDN 上早有 kerlomz 98.7% 等方案。
**已修复**: tech-strategist Phase 1 三路并行搜索（原生 + /vane-search + /jisu-wechat-article），RESEARCH_REPORT 强制"中文平台检索结果"章节。

### ISS-056: 首次接触可行方案时必须量化验证 [P1] ✅ 已修复
**现象**: Qwen API 首测仅粗测一次就跳走，绕了 30h 才回来。
**已修复**: tech-strategist Phase 2 POC 量化要求（≥10 次，输出 n_trials/success_rate/latency/cost）。

### ISS-057: POC 单方向连续 2 次失败必须强制回调研 [P1] ✅ 已修复
**现象**: ddddocr 13% 后连续 5 个 POC 在"本地 OCR"方向全失败。
**已修复**: tech-strategist Phase 4 方向止损规则。

### ISS-058: POC 阶段应最多 3 个验证 agent 并行 [P1] ✅ 已修复
**现象**: 所有 POC 串行，总耗时 ~30h。并行 3 个 agent 可 ~10h。
**已修复**: tech-strategist Phase 3 并行 POC 编排（≤3 个 Worker + 先达标者收敛全队）。

---

## 数据分析/评估复盘

### ISS-059: 数据分析项目缺少强制 EDA + 逐步验证门控 [P1] ⚡ 部分修复
**现象**: 数据清洗/分类/统计三步中间无验证，汇总看起来合理但细节有错。
**已修复部分**: data-engineer 五维检查 + tc-creator 数据分析覆盖矩阵。
**未修复**: 每步"暂停+抽样验证"的强制门控。

### ISS-060: 评估脚本自评放水 [P1] ⚡ 部分修复
**现象**: TC 标 PASS 但写"需人工抽验"而非做实质验证。
**已修复部分**: evaluator agent 按 TC 类型选验证工具（API/数据/截图/交互/网络）。
**未修复**: Leader 直接执行时未 spawn 独立 Evaluator 的问题。

### ISS-061: ClawTeam spawn --workspace worktree 时序陷阱 [P1] ✅ 已修复
**已修复**: 先 commit 再 spawn + 绝对路径 + `--repo $(pwd)`。
