# ClawTeam CLI 命令速查

> 二进制: `~/.local/bin/clawteam` | 版本: v0.2.0

## 全局选项
```bash
clawteam [--json] [--data-dir PATH] [--transport file|p2p] <command>
```

## 团队管理

```bash
# 创建团队（注册 Leader）
clawteam team spawn-team <TEAM> [-d "描述"] [-n leader-name]

# 查看团队状态
clawteam team status <TEAM>

# 列出所有团队
clawteam team discover

# 删除团队
clawteam team cleanup <TEAM> [-f]

# 快照/恢复
clawteam team snapshot <TEAM> [-t label]
clawteam team restore <TEAM> <SNAPSHOT_ID>
```

## 任务管理

```bash
# 创建任务
clawteam task create <TEAM> "任务描述" [-d "详情"] [-o agent-name] [--blocked-by id1,id2]

# 列出任务
clawteam task list <TEAM> [-s pending|in_progress|completed|blocked] [-o agent]

# 更新任务
clawteam task update <TEAM> <TASK_ID> [-s completed] [-o new-owner]

# 查看单个任务
clawteam task get <TEAM> <TASK_ID>

# 等待所有任务完成
clawteam task wait <TEAM> [-t 300]

# 任务统计
clawteam task stats <TEAM>
```

## 派生 Agent

```bash
# 派 Agent（默认 tmux）
clawteam spawn [tmux|subprocess] [claude] \
  --team <TEAM> \
  --agent-name worker-1 \
  --task "你的任务描述" \
  [--workspace]           # 创建 git worktree
  [--profile <PROFILE>]   # 运行时配置
  [--resume]              # 恢复上次会话

# 常用：派 Claude Code Worker
clawteam spawn tmux claude \
  -t my-project \
  -n worker-1 \
  --task "实现用户认证模块" \
  --workspace
```

## 消息通信

```bash
# 发送消息
clawteam inbox send <TEAM> <TO_AGENT> "消息内容" [-f from-agent]

# 广播
clawteam inbox broadcast <TEAM> "消息内容"

# 接收消息（消费）
clawteam inbox receive <TEAM> [-a agent-name] [-l 10]

# 查看消息（不消费）
clawteam inbox peek <TEAM> [-a agent-name]

# 消息历史
clawteam inbox log <TEAM> [-l 50]

# 监听新消息
clawteam inbox watch <TEAM> [-a agent-name] [-e "处理命令"]
```

## 看板 & 监控

```bash
# 文本看板
clawteam board show <TEAM>

# 实时刷新看板
clawteam board live <TEAM> [-i 2.0]

# Web 看板
clawteam board serve [TEAM] [-p 8080]

# 总览
clawteam board overview

# tmux 拼接视图
clawteam board attach <TEAM>

# Gource 可视化
clawteam board gource <TEAM> [--live]
```

## Git Workspace

```bash
# 列出 worktree
clawteam workspace list <TEAM>

# 检查点提交
clawteam workspace checkpoint <TEAM> <AGENT> [-m "消息"]

# 合并到主分支
clawteam workspace merge <TEAM> <AGENT>

# 清理 worktree
clawteam workspace cleanup <TEAM> [-a agent-name]

# 查看 diff
clawteam workspace status <TEAM> <AGENT>
```

## Git 上下文

```bash
# Agent 改了哪些文件
clawteam context files <TEAM>

# 文件冲突检测
clawteam context conflicts <TEAM>

# 跨分支提交日志
clawteam context log <TEAM> [-n 50]

# 生成上下文注入文本
clawteam context inject <TEAM> <AGENT>
```

## 成本追踪

```bash
# 报告 token 消耗
clawteam cost report <TEAM> --input-tokens 50000 --output-tokens 10000 --cost-cents 125

# 查看成本
clawteam cost show <TEAM>

# 设置预算
clawteam cost budget <TEAM> 100.00
```

## 生命周期

```bash
# 请求关闭 Agent
clawteam lifecycle request-shutdown <TEAM> <FROM> <TO> [-r "原因"]

# 发送空闲通知
clawteam lifecycle idle <TEAM> [--last-task ID]

# Agent 退出处理（自动调用）
clawteam lifecycle on-exit --team <TEAM> --agent <AGENT>
```

## 模板 & 一键启动

```bash
# 查看模板
clawteam template list
clawteam template show <NAME>

# 一键启动团队
clawteam launch <TEMPLATE> [-g "项目目标"] [-t team-name] [--workspace]
```

## 配置 & 身份

```bash
# 配置
clawteam config show
clawteam config set <KEY> <VALUE>

# 身份
clawteam identity show

# Profile 管理
clawteam profile list
clawteam profile wizard        # 交互式配置
clawteam profile doctor        # 诊断
```

## Session 持久化 (v0.2.0 新增)

```bash
# 保存 Agent 会话（用于 resume）
clawteam session save <TEAM> <AGENT> [-m "描述"]

# 查看已保存会话
clawteam session show <TEAM> [AGENT]

# 清除保存的会话
clawteam session clear <TEAM> [AGENT]
```

## Plan 审批 (v0.2.0 新增)

```bash
# Worker 提交 Plan 给 Leader 审批
clawteam plan submit <TEAM> <PLAN_FILE> [-t "标题"]

# Leader 批准 Plan
clawteam plan approve <TEAM> <PLAN_ID>

# Leader 拒绝 Plan（附理由）
clawteam plan reject <TEAM> <PLAN_ID> [-r "理由"]
```
