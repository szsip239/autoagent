# 目录结构

> 最后更新: 2026-04-02（v0.4.0 插件化改造后）

```
autoagent/
├── CLAUDE.md                          ← 系统操作手��（精简版，45 行）
├── soul.md                            ← 核心原则（8 条，所有决策的锚点）
├── ISSUES.md                          ← 已知问题索引（123 行，详情在 docs/issues/）
│
├── autoagent-plugin/                  ← 🔑 自研插件（v0.4.0 新增，替代 Harness）
│   ├── skills/                        ← 7 个 /aa 系列 skill 命令
│   │   ├── aa/SKILL.md               ← 唯一入口（状态+路由+初始化）
│   │   ├── aa-research/SKILL.md      ← Layer 1 调研+POC+选型
│   │   ├── aa-plan/SKILL.md          ← Layer 2 编排规划
│   │   ├── aa-spawn/SKILL.md         ← Layer 2 Worker 派发
│   │   ├── aa-eval/SKILL.md          ← Layer 3 独立评估
│   │   ├── aa-ship/SKILL.md          ← Layer 4 审查+交付
│   │   └── aa-gate/SKILL.md          ← 门控操作
│   ├── agents/                        ← 6 个插件注册 Agent（精简 frontmatter）
│   │   ├── requirements-analyst.md
│   │   ├── data-engineer.md
│   │   ├── tc-creator.md
│   │   ├── tech-strategist.md
│   │   ├── evaluator.md
│   │   └── critical-thinker.md
│   ├���─ hooks/                         ← 4 个 hooks（SessionStart/PreToolUse/PostToolUse/Stop）
│   │   ├── hooks.json                ← hook 配置
│   │   ├── session-init.sh           ← SessionStart: 项目状态检测+提示
│   │   ��── safety-check.sh           ← PreToolUse: 破坏性命令+密钥泄露拦截
│   │   ├── skill-tracker.sh          ← PostToolUse: Skill ��用记录
│   │   └── session-end.sh            ← Stop: notepads/skills/clawteam 检查
│   └── scripts/
│       └── check-scope.sh            ← 范围偏离检测
│
├── agents/                            ← Agent 定义（双层设计，见下方说明）
│   ├── core/                          ← 6 个详细 Agent prompt（完整 workflow/template）
│   │   ├── requirements-analyst.md    ← Layer 0: 需求深挖
│   │   ├── data-engineer.md           ← Layer 0: 数据质量
│   │   ├── tc-creator.md              ← Layer 0.5: TC 生成
│   │   ├── tech-strategist.md         ← Layer 1: 技术选型
│   │   ├── evaluator.md               ← Layer 3: 独立评估
│   │   └── critical-thinker.md        ← 战略层: 批判性重评
│   ├── library/                       ← Agent 参考库
│   │   ├── AGENT_FORMAT.md
│   │   ├── AGENT_CATALOG.md           ← 172 个 Agent 全量索引
│   │   └── SKILLS_CATALOG.md          ← ECC Skills 分类目录
│   └── archive/                       ← 已归档 Agent
│       └── benchmark-evaluator.md
│
├── scripts/                           ← 核心自动化脚本（被 skills 高频引用）
│   ├── gate-check.sh                 ← 五层门控检查 + 状态推进 + 回退
│   ├── check-careful.sh              ← 破坏性命令+密钥泄露正则集（safety-check.sh 源）
│   ├── check-notepads.sh             ← Worker 代码变更时提��更新 notepads
│   └── check-scope.sh               ← 范围偏离检测（DoD vs git diff）
│
├── docs/                              ← 详细文档（按需读取）
│   ├── layers.md                     ← Layer 0-4 详细��义
│   ├── init-flow.md                  ��� 项目初始化流程
│   ├── gate-system.md                ← 门控工具链、命令、条件
│   ├── agent-invocation.md           ← 核心 Agent 调用
│   ├── openviking-isolation.md       ← OV URI 路径隔离策略
│   ├── plugin-migration-audit.md     ← v0.4.0 迁移审计（108/108 功能点检）
│   ├── observation-checklist.md      ← 观察检查表
│   ├── directory-structure.md        ← 本文件
│   └── issues/                       ← ISSUES 详情分卷
│       ├── toolchain.md              ← ISS-001~003 三件套协同
│       ├── worker-quality.md         ← ISS-004~061 Worker 执行质量
│       ├── gate-flow.md              ← ISS-006~053 门控/流程
│       ├── architecture.md           ← ISS-009~054 架构演进
│       ├── data-eval.md              ← ISS-013~034 数据/评估
│       ├── tmux-session.md           ← ISS-029~046 tmux/会话
│       ├── benchmarks.md             ← ISS-016~049 调研借鉴
│       ├── vdd.md                    ← ISS-045 VDD 验证驱动开发（P0）
│       ├── verification-checklist.md ← C1~C48 实战验证检查表
│       └── roadmap.md                ← 修复优先级路线图
│
���── templates/                         ← 目标项目模板
│   ├── PROJECT_CLAUDE.md
│   ├── ORCHESTRATION.md               ← 编排模板索引
│   ├── ORCHESTRATION-leader.md
│   ├── ORCHESTRATION-clawteam.md
│   ├── ORCHESTRATION-teams.md
│   ├── EVAL_REPORT.md
│   ├── REASSESSMENT.md
│   ├── RETRO.md
│   ├── TECH_SELECTION.md
│   ├── RESEARCH_REPORT.md
│   ├── api-contract-example.yaml
│   └── STATE.json
│
├── references/                        ← 调研资料+命令速查
│   ├── benchmarks.md                 ← 五方横向对比
│   ├── research-*.md                 ← 各标杆深度调���
│   ├── agent-teams-vs-clawteam.md    ← 混合编排选型
│   ├── clawteam-commands.md
│   ├── harness-commands.md
│   └── openviking-commands.md
│
├── project/                           ← 目标项目数据/产物（.gitignore 排除）
│   └── {project-name}/               ← 每个项目独立目录
│
├── .claude/settings.json             ← 插件注册（localPlugins: autoagent-plugin）
│
└── (只读参考源码)
    ├── claude-code-harness/
    ├── ClawTeam/
    ├── OpenViking/
    ├── agency-agents/
    ├── promptfoo/
    └── deepeval/
```

## agents/ 双层设计说明

AutoAgent 的 Agent 定义采用**双层分离**：

| 层 | 位置 | 用途 | 内容 |
|---|------|------|------|
| **注册层** | `autoagent-plugin/agents/*.md` | 插件系统注册 | 精简 frontmatter（name/description/tools/model）+ 角色摘要 |
| **参考层** | `agents/core/*.md` | Skill 运行时读取 | 完整 prompt（personality/workflow/template/examples） |

**为什么分两层**：
- 插件系统只需 frontmatter 来注册 agent（名称、描述、工具限制、模型选择）
- Skill 在 spawn agent 时需要注入完整 prompt（详细工作流、输出模板、示例）
- 精简注册层减少插件加载开销，详细参考层保证运行时 prompt 质量

**引用关系**: 新版 agent frontmatter 中注明 `完整角色定义见 agents/core/xxx.md`，Skill SKILL.md 中引用 `agents/core/xxx.md` 作为 spawn 时的 prompt 来源。

**注意**: `agents/core/` 不是残留文件，是设计上的分层引用。修改 agent 行为时两层都需更新。
