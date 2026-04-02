# ECC Skills 分类目录

> 来源: everything-claude-code v1.8.0 + claude-plugins-official + anthropic-agent-skills
>
> tech-strategist 在 Layer 1 根据技术选型结果从此目录中推荐 skills，写入目标项目 CLAUDE.md

## Python 项目

### 开发
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| python-patterns | PEP 8、类型提示、Pythonic 惯用写法 | Python 代码编写 |
| python-review | 代码审查（PEP 8、安全、性能） | 每次 Python 变更后自动触发 |
| django-patterns | Django 架构、DRF、ORM | Django 项目 |
| django-tdd | Django TDD（pytest-django、factory_boy） | Django 测试 |
| django-security | Django 安全（CSRF、SQL 注入、XSS） | Django 安全审查 |
| django-verification | Django 验证循环（迁移、lint、测试、安全扫描） | Django 发布前 |
| laravel-patterns | Laravel 架构、Eloquent、队列 | Laravel/PHP 项目 |
| laravel-tdd | Laravel TDD（PHPUnit、Pest） | Laravel 测试 |
| laravel-security | Laravel 安全 | Laravel 安全审查 |
| laravel-verification | Laravel 验证循环 | Laravel 发布前 |

### 测试
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| python-testing | pytest、TDD、fixture、mock、parametrize | Python 测试编写 |
| tdd-workflow | 通用 TDD 工作流（测试先行，80%+ 覆盖率） | 新功能/修 bug |

### 数据/ML
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| postgres-patterns | PostgreSQL 查询优化、Schema 设计、索引 | 数据库操作 |
| database-reviewer | PostgreSQL 审查（安全、性能） | SQL/数据库变更 |
| database-migrations | 数据库迁移最佳实践（零宕机） | Schema 变更 |
| clickhouse-io | ClickHouse 分析查询优化 | ClickHouse 项目 |

## Web / 全栈项目

### 前端
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| frontend-design | 高质量前端界面（非通用 AI 美学） | 构建 UI |
| frontend-patterns | React/Next.js 状态管理、性能优化 | 前端开发 |
| frontend-slides | HTML 演示文稿 | 做 PPT/Slides |

### 后端
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| backend-patterns | Node.js/Express/Next.js API 设计 | 后端开发 |
| api-design | REST API 设计（命名、状态码、分页） | API 设计 |
| springboot-patterns | Spring Boot 架构 | Java 后端 |
| springboot-tdd | Spring Boot TDD | Java 测试 |
| springboot-security | Spring Security | Java 安全 |
| springboot-verification | Spring Boot 验证循环 | Java 发布前 |

### 全栈工具
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| coding-standards | TypeScript/JavaScript/React/Node 编码规范 | TS/JS 开发 |
| e2e-testing | Playwright E2E 测试 | 端到端测试 |
| docker-patterns | Docker/Compose 开发、安全、编排 | 容器化 |
| deployment-patterns | CI/CD、健康检查、回滚策略 | 部署 |
| bun-runtime | Bun 运行时/包管理/打包/测试 | Bun 项目 |
| nextjs-turbopack | Next.js 16+ / Turbopack | Next.js 项目 |

## Go 项目

| Skill | 说明 | 触发场景 |
|-------|------|---------|
| golang-patterns | 惯用 Go 模式 | Go 开发 |
| golang-testing | 表驱动测试、fuzz、benchmark | Go 测试 |
| go-review | Go 代码审查（并发、错误处理） | Go 变更后 |
| go-build | 修复 Go 构建错误 | Go 构建失败 |

## Rust 项目

| Skill | 说明 | 触发场景 |
|-------|------|---------|
| rust-patterns | 所有权、错误处理、traits、并发 | Rust 开发 |
| rust-testing | Rust TDD、属性测试、mock | Rust 测试 |
| rust-review | 所有权、生命周期、unsafe 审查 | Rust 变更后 |
| rust-build | Cargo 构建错误修复 | Rust 构建失败 |

## Kotlin / Android 项目

| Skill | 说明 | 触发场景 |
|-------|------|---------|
| kotlin-patterns | 惯用 Kotlin、协程、DSL | Kotlin 开发 |
| kotlin-testing | Kotest、MockK、Kover 覆盖率 | Kotlin 测试 |
| kotlin-review | null 安全、协程安全、Compose | Kotlin 变更后 |
| kotlin-build | Gradle 构建错误修复 | Kotlin 构建失败 |
| kotlin-coroutines-flows | 协程/Flow 模式 | 异步编程 |
| kotlin-exposed-patterns | Exposed ORM 模式 | 数据库 |
| kotlin-ktor-patterns | Ktor 服务端模式 | Ktor 项目 |
| compose-multiplatform-patterns | Compose Multiplatform UI | KMP 项目 |
| android-clean-architecture | Android Clean Architecture | Android 项目 |

## C++ 项目

| Skill | 说明 | 触发场景 |
|-------|------|---------|
| cpp-coding-standards | C++ Core Guidelines | C++ 开发 |
| cpp-testing | GoogleTest/CTest | C++ 测试 |
| cpp-review | 内存安全、现代 C++、并发 | C++ 变更后 |
| cpp-build | CMake/链接器错误修复 | C++ 构建失败 |

## Swift / Apple 项目

| Skill | 说明 | 触发场景 |
|-------|------|---------|
| swiftui-patterns | SwiftUI 架构、@Observable、导航 | SwiftUI 开发 |
| swift-concurrency-6-2 | Swift 6.2 并发（单线程默认、@concurrent） | Swift 并发 |
| swift-actor-persistence | Actor 线程安全持久化 | 数据持久化 |
| swift-protocol-di-testing | 协议依赖注入测试 | Swift 测试 |
| foundation-models-on-device | Apple FoundationModels（设备端 LLM） | iOS 26+ AI |
| liquid-glass-design | iOS 26 Liquid Glass 设计 | iOS 26 UI |

## 通用工具（所有项目适用）

### 安全
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| security-review | OWASP Top 10 检查清单 | 认证/输入处理/API |
| security-scan | Claude Code 配置安全扫描 | 配置审查 |

### 流程
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| plan | 需求重述→风险评估→实施计划 | 规划阶段 |
| tdd | 通用 TDD（接口脚手架→测试→实现） | 所有开发 |
| simplify | 审查代码复用、质量、效率 | 代码完成后 |
| search-first | 编码前先调研现有工具/库 | 开始新功能 |

### 文档
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| docs | Context7 查阅最新文档 | 查 API/库用法 |
| doc-coauthoring | 共同撰写文档/提案/规格 | 写文档 |

### AI/LLM 开发
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| claude-api | Claude API / Anthropic SDK 模式 | Claude API 开发 |
| cost-aware-llm-pipeline | LLM 成本优化（模型路由、预算追踪） | LLM 管道 |
| mcp-server-patterns | MCP Server 构建 | MCP 开发 |
| agent-harness-construction | Agent 动作空间、工具定义优化 | Agent 开发 |
| prompt-optimizer | Prompt 分析优化（不执行任务） | Prompt 优化 |

### 多 Agent / 自动化
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| orchestrate | 多 Agent tmux/worktree 编排 | 多 Agent 协作 |
| blueprint | 多会话工程项目蓝图 | 大型项目规划 |
| autonomous-loops | 自主 Agent 循环架构 | 持续运行 Agent |
| continuous-learning | 从会话提取可复用模式 | 经验积累 |
| verification-loop | Claude Code 会话验证系统 | 质量保证 |
| eval-harness | 会话评估框架（EDD） | 评估驱动开发 |

### 内容/媒体
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| article-writing | 长篇内容写作 | 文章/博客 |
| content-engine | 多平台内容创作 | 社交媒体 |
| video-editing | AI 辅助视频编辑 | 视频制作 |
| fal-ai-media | fal.ai 图片/视频/音频生成 | AI 媒体 |

### 研究
| Skill | 说明 | 触发场景 |
|-------|------|---------|
| deep-research | 多源深度调研（firecrawl + exa） | 深度研究 |
| market-research | 市场/竞品/投资调研 | 商业调研 |
| exa-search | Exa 神经搜索 | Web/代码搜索 |

---

## 快速选择指南

| 项目类型 | 必选 Skills | 可选 Skills |
|---------|------------|------------|
| **Python ML/数据** | python-patterns, python-review, python-testing, tdd, security-review | database-reviewer, postgres-patterns, deep-research |
| **Python Web (Django)** | django-patterns, django-tdd, django-security, django-verification | docker-patterns, deployment-patterns |
| **全栈 Web (TS/React)** | coding-standards, frontend-patterns, backend-patterns, api-design, e2e-testing | nextjs-turbopack, docker-patterns |
| **Go 服务** | golang-patterns, golang-testing, go-review, api-design | docker-patterns, deployment-patterns |
| **Rust 项目** | rust-patterns, rust-testing, rust-review | — |
| **Java Spring Boot** | springboot-patterns, springboot-tdd, springboot-security | database-migrations |
| **Kotlin Android/KMP** | kotlin-patterns, kotlin-testing, android-clean-architecture | compose-multiplatform-patterns |
| **LLM/Agent 开发** | claude-api, cost-aware-llm-pipeline, prompt-optimizer | mcp-server-patterns, agent-harness-construction |
| **通用（所有项目）** | plan, tdd, simplify, security-review, search-first | docs, verification-loop |
