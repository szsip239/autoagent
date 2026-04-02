# Claude Harness 命令速查

> Plugin: claude-code-harness v3.14.0 | 需要 Claude Code v2.1.78+

## 5 个核心动词

### /harness-setup — 项目初始化

```bash
/harness-setup              # 交互式选择
/harness-setup init         # 初始化项目（生成 CLAUDE.md, Plans.md, hooks）
/harness-setup ci           # 配置 GitHub Actions
/harness-setup codex        # 安装 Codex CLI
/harness-setup agents       # 配置 agents-v3/
```

### /harness-plan — 计划管理

```bash
/harness-plan               # 交互式创建计划
/harness-plan create        # 听需求 → 搜索 → 生成 Plans.md
/harness-plan add "任务名" --phase N    # 添加任务
/harness-plan update 3 done             # 更新任务状态
/harness-plan sync          # 同步 Plans.md 与 git 实际状态
/harness-plan sync --no-retro           # 同步（跳过回顾）
```

**Plans.md 格式（v2，5 列）**:
```markdown
| Task | 内容 | DoD | Depends | Status |
|------|------|-----|---------|--------|
| 1.1  | 实现登录 | 测试通过 | - | cc:TODO |
| 1.2  | 实现注册 | 测试通过 | 1.1 | cc:TODO |
```

**状态标记**: `cc:TODO` → `cc:WIP` → `cc:完了 [hash]` → `pm:確認済`

### /harness-work — 任务执行

```bash
/harness-work               # 交互式选择范围
/harness-work all           # 全部未完成任务（自动选模式）
/harness-work 3             # 只做任务 3（Solo）
/harness-work 3-6           # 做任务 3-6（自动选模式）
/harness-work --parallel 5  # 强制 5 个并行 Worker
/harness-work --breezing    # 强制 Lead/Worker/Reviewer 团队模式
/harness-work --codex all   # 委托给 Codex CLI
/harness-work --no-tdd      # 跳过 TDD
/harness-work --no-commit   # 不自动提交
```

**自动模式选择**:
| 任务数 | 模式 |
|--------|------|
| 1 | Solo（直接实现） |
| 2-3 | Parallel（Task tool 并行） |
| 4+ | Breezing（Lead + Worker + Reviewer） |

**Solo 流程**: Plans.md → cc:WIP → TDD(Red→Green) → /simplify → git commit → cc:完了

### /harness-review — 代码审查

```bash
/harness-review             # 自动检测类型
/harness-review code        # 代码审查（5 维：安全/性能/质量/可访问性/AI残留）
/harness-review plan        # 计划审查
/harness-review scope       # 范围审查
```

**代码审查 5 维度**（v3.13.0+）:
- Security: 注入、XSS、密钥暴露
- Performance: N+1 查询、内存泄漏
- Quality: 命名、SRP、测试覆盖
- Accessibility: ARIA、键盘导航
- **AI Residuals (v3.13.0 新增)**: mockData、dummyUser、localhost:3000、TODO/FIXME、test.skip、hardcoded API keys 等 AI 生成残留检测

### harness-mem — 会话记忆永续 (v3.13.0 新增)

SessionStart/Stop hook 自动管理会话间记忆：
- **SessionStart**: 注入 Continuity Briefing（前次会话的关键上下文）
- **Stop**: 自动保存当前会话的决策和发现到 harness-mem
- 无需手动操作，由 hook 自动触发

### /harness-release — 发版

```bash
/harness-release            # 交互式
/harness-release patch      # x.y.Z（修 bug）
/harness-release minor      # x.Y.0（新功能）
/harness-release major      # X.0.0（破坏性变更）
/harness-release --dry-run  # 预览
```

## 护栏引擎（自动生效）

| 规则 | 动作 |
|------|------|
| R01: sudo | DENY |
| R02: 写 .env/.git/SSH keys | DENY |
| R03: rm -rf / | DENY |
| R04: git push --force | ASK |
| PostToolUse: 硬编码密码/XSS/命令注入 | WARN |

## Breezing 团队模式

```
Lead（当前会话）
├── Worker（Sonnet 4.6, worktree 隔离, maxTurns=100）
│   工具: Read, Write, Edit, Bash, Grep, Glob
│   流程: 实现 → 自检 → 提交 → cc:完了
│
└── Reviewer（Sonnet 4.6, 只读, maxTurns=50）
    工具: Read, Grep, Glob
    输出: APPROVE / REQUEST_CHANGES
```
