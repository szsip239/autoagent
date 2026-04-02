# ISS-045: 验证驱动开发 (VDD) [P0] ⚡ 框架落地待实战

> 统筹 ISS-040 (设计确认)、ISS-041 (Skills 强制)、ISS-042 (粗粒度验收)、ISS-043 (API 契约)

**来源**: 全流程测试 + Anthropic 官方 Harness 实践确认
**外部验证**: [references/research-anthropic-harness.md](../../references/research-anthropic-harness.md)

## 问题本质

Agent 的验证模式是"代码能跑 = 完成"，缺少四类验证：
1. **物理/逻辑验证** — 公式含义是否正确
2. **视觉验证** — UI 是否真的符合预期
3. **交互验证** — 用户操作是否有响应
4. **集成验证** — API 是否真的调通（非 Mock 降级）

## VDD 修复方案

### Step 1: 方案阶段写 TC（不是实施后补）

验证的是"正确性"而非"存在性"：
- ❌ `地图组件可渲染`
- ✅ `地图底图有中文道路名称（截图证据，不是空白背景）`

每个 P0 功能至少 5 条 TC（存在性 1-2 + 正确性 3+）。

### Step 2: 实施阶段先写验证代码再写功能代码

### Step 3: 验证阶段用浏览器自动化 (claude-in-chrome)

截图保存到 `eval/screenshots/` 作为证据。

### Step 4: 验证失败 → 自动回到实施（max 3 次重试）

## 验证方法分类

| 方法 | 适用 TC | 工具 | 自动化 |
|------|---------|------|--------|
| API 断言 | 存在性+数学 | curl+jq/pytest | 全自动 |
| 数据断言 | 空间物理+分级 | Python | 全自动 |
| 截图对比 | 视觉 | claude-in-chrome | 半自动 |
| 交互录制 | 交互 | claude-in-chrome click | 半自动 |
| 网络检查 | 集成 | claude-in-chrome network | 全自动 |

## 框架层变更

| 改什么 | 在哪改 | 效果 |
|--------|--------|------|
| TC 模板 | REQUIREMENTS.md 模板 | 每个功能必须附带 TC |
| 浏览器验证 | Worker prompt + Stop hook | 完成前必须截图 |
| EVAL_REPORT | Layer 3 评估模板 | TC 逐条通过率 |
| 重试机制 | Plans.md 模板 | 验证失败→修复→重验 (max 3) |

## TC 示例

详见原始 ISSUES.md git 历史中的完整 TC 清单模板（ISS-045 章节，含 F1~F6 + 集成共 ~80 条 TC）。
