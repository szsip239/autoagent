# OpenViking 项目隔离策略

采用 **URI 路径隔离**（单租户模式）：

```
viking://resources/{project-name}/       ← 每个项目独立路径，搜索时用 --uri 限定
viking://resources/cases/{project}/     ← 项目交付经验（gate-check pass 4 自动写入）
viking://resources/cases/               ← 搜索时用此路径查跨项目经验
```

- **resources/{project}/**: 按项目隔离的资源（文档、数据描述），Worker 搜索时必须指定 `--uri`
- **resources/cases/{project}/**: 项目交付经验，gate-check pass 4 自动写入，新项目 init 时自动搜索注入
- **升级路径**: 如果串记忆成为问题，加 `root_api_key` 切多租户，不影响已有数据
