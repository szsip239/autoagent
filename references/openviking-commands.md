# OpenViking CLI & API 速查

> CLI: `~/.openviking/venv/bin/ov` | Server: localhost:1933 | 版本: v0.2.13

## CLI 命令

### 资源管理

```bash
# 添加资源（文件/目录/URL）
ov add-resource ./docs/ [--to viking://resources/project/] [--wait] [--reason "说明"]
ov add-resource https://example.com/api.md --wait

# 添加技能
ov add-skill ./skills/search-web/SKILL.md --wait

# 导出/导入 .ovpack
ov export viking://resources/project/ ./project.ovpack
ov import ./project.ovpack viking://resources/imported/ [--force]
```

### 文件系统

```bash
# 浏览
ov ls [viking://resources/] [--recursive] [--simple]
ov tree viking://resources/ [-L 2]
ov stat viking://resources/docs/api.md

# 读取内容（三级）
ov abstract viking://resources/docs/     # L0: ~100 tokens 摘要
ov overview viking://resources/docs/     # L1: ~2k tokens 概览
ov read viking://resources/docs/api.md   # L2: 完整内容

# 操作
ov mkdir viking://resources/new-project/
ov mv viking://resources/old/ viking://resources/new/
ov rm viking://resources/old.md
ov rm viking://resources/old-project/ --recursive
```

### 搜索

```bash
# 语义搜索
ov find "如何认证用户" [--uri viking://resources/] [--limit 10]

# 上下文感知搜索
ov search "最佳实践" [--session-id abc123]

# 模式搜索
ov grep viking://resources/ "authentication" [--ignore-case]

# 文件匹配
ov glob "**/*.md" [--uri viking://resources/]
```

### 会话

```bash
ov session new                    # 创建会话（返回 session_id）
ov session list                   # 列出会话
ov session get <ID>               # 查看会话
ov session add-message <ID> --role user --content "问题"
ov session commit <ID>            # 提交（压缩+提取记忆）
ov session delete <ID>
```

### 记忆

```bash
# 一键存记忆
ov add-memory "记住：我偏好 markdown 格式"
```

### 关联

```bash
ov relations viking://resources/docs/auth/
ov link viking://resources/docs/auth/ viking://resources/docs/security/ [--reason "相关"]
ov unlink viking://resources/docs/auth/ viking://resources/docs/security/
```

### 系统 & 监控

```bash
ov health                     # 健康检查
ov status                     # 系统状态
ov wait [--timeout 60]        # 等待异步处理完成
ov observer queue             # 队列状态
ov observer vikingdb          # 向量库状态
ov observer vlm               # VLM token 用量

# v0.2.11+ 新增
ov doctor                     # 配置诊断（检查 embedding/VLM/存储配置是否正确）
ov reindex [--uri viking://]  # 重建向量索引（数据损坏时使用）
```

### Prometheus 指标 (v0.2.11+)

```bash
# 指标导出端点
curl http://localhost:1933/metrics    # Prometheus 格式指标
# 可接入 Grafana 做 OV 运维监控
```

### 多租户管理

```bash
# 创建账户
ov admin create-account acme --admin alice

# 注册用户（返回 API Key）
ov admin register-user acme worker-1 [--role user]

# 列出
ov admin list-accounts
ov admin list-users acme

# 管理
ov admin set-role acme bob admin
ov admin regenerate-key acme worker-1
ov admin remove-user acme worker-1
```

### 交互工具

```bash
ov tui [viking://resources/]  # 交互式文件浏览器
ov chat -m "什么是 OpenViking?"  # 聊天
```

## HTTP API 常用端点

### 基础
```bash
curl http://localhost:1933/health                    # {"status":"ok"}
curl http://localhost:1933/api/v1/debug/health
```

### 搜索
```bash
curl -X POST http://localhost:1933/api/v1/search/find \
  -H "Content-Type: application/json" \
  -d '{"query": "认证方法", "target_uri": "viking://resources/", "limit": 10}'
```

### 文件系统
```bash
# 列目录
curl "http://localhost:1933/api/v1/fs/ls?uri=viking://resources/"

# 读内容
curl "http://localhost:1933/api/v1/content/read?uri=viking://resources/docs/api.md"

# 创建目录
curl -X POST http://localhost:1933/api/v1/fs/mkdir \
  -d '{"uri": "viking://resources/new/"}'
```

### 资源
```bash
curl -X POST http://localhost:1933/api/v1/resources \
  -d '{"path": "./docs/", "target": "viking://resources/docs/", "wait": true}'
```

### 会话
```bash
# 创建
curl -X POST http://localhost:1933/api/v1/sessions

# 添加消息
curl -X POST http://localhost:1933/api/v1/sessions/<ID>/messages \
  -d '{"role": "user", "content": "问题"}'

# 提交
curl -X POST http://localhost:1933/api/v1/sessions/<ID>/commit
```

## Python SDK

```python
from openviking import SyncHTTPClient

client = SyncHTTPClient(url="http://localhost:1933", api_key="key")
client.initialize()

# 搜索
results = client.find("认证方法", target_uri="viking://resources/", limit=10)
for r in results.resources:
    print(f"{r.uri} (score: {r.score:.3f})")

# 浏览
entries = client.ls("viking://resources/")

# 读取
content = client.read("viking://resources/docs/api.md")
abstract = client.abstract("viking://resources/docs/")

# 添加资源
client.add_resource("./docs/", target="viking://resources/docs/", wait=True)

# 会话
session = client.session()
session.add_message("user", "问题")
session.commit()
```

## Viking URI 结构

```
viking://
├── resources/     # 项目文档和代码（共享只读）
├── agent/
│   ├── skills/    # 可调用的技能
│   ├── memories/
│   │   ├── cases/     # 问题-解决方案
│   │   └── patterns/  # 可复用模式
│   └── instructions/
├── user/
│   └── memories/
│       ├── preferences/  # 用户偏好
│       ├── entities/     # 重要实体
│       └── events/       # 关键事件
└── session/        # 会话数据
    └── {session-id}/
```
