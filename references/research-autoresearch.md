# Autoresearch 深度调研报告

> 项目: [karpathy/autoresearch](https://github.com/karpathy/autoresearch) | 调研日期: 2026-03-25
> 源码位置: `references/repos/autoresearch/`

## 1. 项目概况

**仓库**: karpathy/autoresearch
**License**: MIT
**Python 版本**: 3.10+
**Stars**: ~55K

**一句话定位**: 让 AI Agent 在固定 5 分钟时间预算内自主修改 LLM 训练代码并反复实验，人类睡觉时 Agent 自动跑约 100 次实验，醒来看结果。

**核心文件仅 3 个**（总计 1133 行）:
- `prepare.py` (389 行) — 数据下载、Tokenizer 训练、DataLoader、评估函数（只读）
- `train.py` (630 行) — GPT 模型、Muon+AdamW 优化器、训练循环（Agent 可改）
- `program.md` (114 行) — Agent 的指令文档（人类可改）

README 中的标志性开头——一段虚构的"未来史"：

> *"One day, frontier AI research used to be done by meat computers in between eating, sleeping, having other fun, and synchronizing once in a while using sound wave interconnect in the ritual of 'group meeting'. That era is long gone. Research is now entirely the domain of autonomous swarms of AI agents running across compute cluster megastructures in the skies."* — @karpathy

从 progress.png 可见，实际运行成果：**83 次实验，15 次成功改进 (kept)**，val_bpb 从约 0.998 降至约 0.976。

---

## 2. 核心理念

### 2.1 "Programming the Program" 哲学

README 原话：

> *"The core idea is that you're not touching any of the Python files like you normally would as a researcher. Instead, you are programming the `program.md` Markdown files that provide context to the AI agents and set up your autonomous research org."*

这是一个**元编程**理念：人类不再直接写 Python 做研究，而是编写"指导 Agent 做研究"的 Markdown。人类的角色从"研究员"变成了"研究组织的架构师"。

### 2.2 对 Agent 自治的态度

program.md 中有一段极其明确的指令（第 112 行）：

> **"NEVER STOP"**: Once the experiment loop has begun (after the initial setup), do NOT pause to ask the human if you should continue. Do NOT ask "should I keep going?" or "is this a good stopping point?". The human might be asleep, or gone from a computer and expects you to continue working *indefinitely* until you are manually stopped. You are autonomous. If you run out of ideas, think harder — read papers referenced in the code, re-read the in-scope files for new angles, try combining previous near-misses, try more radical architectural changes. The loop runs until the human interrupts you, period.

这是**完全自主**的设计。Agent 只能被人类手动中断，不允许主动停下来请示。

### 2.3 简洁性准则

program.md 第 37 行，原话：

> **"Simplicity criterion"**: All else being equal, simpler is better. A small improvement that adds ugly complexity is not worth it. Conversely, removing something and getting equal or better results is a great outcome — that's a simplification win. When evaluating whether to keep a change, weigh the complexity cost against the improvement magnitude. A 0.001 val_bpb improvement that adds 20 lines of hacky code? Probably not worth it. A 0.001 val_bpb improvement from deleting code? Definitely keep. An improvement of ~0 but much simpler code? Keep.

这是一个**反复杂度准则**：删除代码但保持性能 > 加代码提升一点性能。

### 2.4 设计哲学总结

README 中：
> - **Single file to modify.** The agent only touches `train.py`. This keeps the scope manageable and diffs reviewable.
> - **Fixed time budget.** Training always runs for exactly 5 minutes, regardless of your specific platform.
> - **Self-contained.** No external dependencies beyond PyTorch and a few small packages. No distributed training, no complex configs. One GPU, one file, one metric.

---

## 3. 架构与文件结构

### 3.1 文件清单

| 文件 | 行数 | 角色 | 可编辑 | 关键内容 |
|------|------|------|--------|---------|
| `train.py` | 630 | 核心训练脚本 | **Agent 可改** | GPTConfig, GPT, MuonAdamW, 训练循环, 超参数 |
| `prepare.py` | 389 | 数据准备 + 运行时工具 | **只读** | 常量定义, 数据下载, Tokenizer 训练, DataLoader, evaluate_bpb |
| `program.md` | 114 | Agent 指令 | **人类可改** | Setup 流程, 实验循环, 输出格式, 日志规范 |
| `pyproject.toml` | 27 | 依赖配置 | 只读 | torch 2.9.1, kernels, rustbpe, tiktoken 等 |
| `analysis.ipynb` | N/A | 结果分析 | 工具性 | 读取 results.tsv, 绘制 progress.png |
| `.gitignore` | 24 | Git 配置 | N/A | 忽略 results.tsv, CLAUDE.md, worktrees/, dev/ |

### 3.2 文件间依赖关系

```
program.md  ─(指导 Agent 操作)─→  train.py
train.py    ─(import)──────────→  prepare.py  (MAX_SEQ_LEN, TIME_BUDGET, Tokenizer, make_dataloader, evaluate_bpb)
train.py    ─(import)──────────→  kernels     (Flash Attention 3, 通过 get_kernel 动态加载)
train.py    ─(输出)────────────→  run.log     (重定向 stdout/stderr)
program.md  ─(指导 Agent 记录)──→  results.tsv (实验结果追踪，不入 git)
```

关键设计：**train.py 从 prepare.py 导入常量和工具函数**，Agent 只能改 train.py，无法篡改评估逻辑或训练时间预算。

---

## 4. 工作流详解

### 4.1 Setup Phase（program.md 第 7-18 行）

1. **约定 run tag**：基于日期（如 `mar5`），确认分支 `autoresearch/<tag>` 不存在
2. **创建分支**：`git checkout -b autoresearch/<tag>` 从 master 创建
3. **读取全部文件**：Agent 读取 README.md, prepare.py, train.py 获取完整上下文
4. **验证数据**：检查 `~/.cache/autoresearch/` 是否有数据分片和 tokenizer，若无则提示人类运行 `uv run prepare.py`
5. **初始化 results.tsv**：创建仅含 header 行的文件
6. **确认并启动**：确认一切就绪后开始实验

### 4.2 Experiment Loop（program.md 第 94-106 行）

**LOOP FOREVER:**

1. 查看 git 状态（当前分支/commit）
2. 修改 `train.py` — 实现一个实验想法
3. `git commit` 提交修改
4. 执行实验：`uv run train.py > run.log 2>&1`（**必须重定向**，不能 tee，防止输出淹没 Agent 上下文）
5. 读取结果：`grep "^val_bpb:\|^peak_vram_mb:" run.log`
6. **崩溃处理**：若 grep 为空 → `tail -n 50 run.log` 看栈追踪 → 尝试修复 → 多次失败则放弃
7. 记录结果到 results.tsv（**不 commit**，保持 untracked）
8. **改进**（val_bpb 降低）→ 保留 commit，推进分支
9. **未改进**（val_bpb 相等或更差）→ `git reset` 回退

### 4.3 崩溃处理逻辑

- **简单错误**（typo, missing import）→ 修复后重跑
- **根本性问题**（OOM, 想法本身不可行）→ 记录 `crash`，跳过，继续下一个实验

### 4.4 停止条件

**没有停止条件。** 只能人类手动中断。Agent 被明确禁止主动询问是否继续。

超时保护：单次实验超过 10 分钟则 kill，视为失败。

---

## 5. 评估机制

### 5.1 evaluate_bpb() 实现细节

位于 `prepare.py` 第 344-365 行：

```python
@torch.no_grad()
def evaluate_bpb(model, tokenizer, batch_size):
    token_bytes = get_token_bytes(device="cuda")
    val_loader = make_dataloader(tokenizer, batch_size, MAX_SEQ_LEN, "val")
    steps = EVAL_TOKENS // (batch_size * MAX_SEQ_LEN)
    total_nats = 0.0
    total_bytes = 0
    for _ in range(steps):
        x, y, _ = next(val_loader)
        loss_flat = model(x, y, reduction='none').view(-1)
        y_flat = y.view(-1)
        nbytes = token_bytes[y_flat]
        mask = nbytes > 0
        total_nats += (loss_flat * mask).sum().item()
        total_bytes += nbytes.sum().item()
    return total_nats / (math.log(2) * total_bytes)
```

**参数**：model, tokenizer, batch_size
**返回值**：float，验证集上的 bits per byte
**数据集**：固定的验证分片（shard_06542.parquet，即 VAL_SHARD = 6542）
**评估量**：`EVAL_TOKENS = 40 * 524288 = 20,971,520` tokens（约 2000 万）

### 5.2 为什么选 val_bpb

README 原话：
> The metric is **val_bpb** (validation bits per byte) — lower is better, and **vocab-size-independent** so architectural changes are fairly compared.

BPB 而非 perplexity 的原因：vocab_size 不同时 cross-entropy loss 不可直接比较（因为随机基线 = log(vocab_size)），而 BPB 将 nats 转换为每字节比特数，消除了词表大小的影响。

### 5.3 不可篡改设计

1. `evaluate_bpb()` 在 `prepare.py` 中，Agent **不能修改** prepare.py
2. program.md 明确禁止：*"Modify `prepare.py`. It is read-only."* 和 *"Modify the evaluation harness."*
3. 常量 `EVAL_TOKENS`, `MAX_SEQ_LEN`, `TIME_BUDGET` 全在 prepare.py 中
4. 验证分片固定为 shard_06542（不受训练数据影响）

### 5.4 Fast-fail 机制

train.py 第 570-572 行：

```python
if math.isnan(train_loss_f) or train_loss_f > 100:
    print("FAIL")
    exit(1)
```

如果训练过程中 loss 爆炸（NaN 或 > 100），立即退出，不浪费 5 分钟等待。

---

## 6. 状态管理

### 6.1 Git 作为状态机

**分支策略**：
- master 保持原始代码
- 每次实验 run 在 `autoresearch/<tag>` 分支上（如 `autoresearch/mar5`）

**Commit 策略**：
- Agent 每次修改 train.py 后先 commit
- 如果实验成功（val_bpb 改善）→ commit 保留，分支推进
- 如果实验失败 → `git reset` 回退到上一个成功 commit

这是一个**线性推进的状态机**：分支 HEAD 始终指向"当前最优"。

### 6.2 results.tsv 格式

5 列 TSV：

| 列 | 含义 | 示例 |
|----|------|------|
| commit | 短 hash (7 字符) | `a1b2c3d` |
| val_bpb | 验证 BPB | `0.997900` (crash 时为 `0.000000`) |
| memory_gb | 峰值 VRAM (GB) | `44.0` (crash 时为 `0.0`) |
| status | keep / discard / crash | `keep` |
| description | 实验描述 | `baseline` |

**关键设计**：results.tsv **不入 git**（.gitignore 中明确排除），它是 Agent 的实验日志，不污染代码历史。

### 6.3 run.log 的作用

每次实验输出重定向到 run.log：`uv run train.py > run.log 2>&1`

用途：
1. 提取结果：`grep "^val_bpb:\|^peak_vram_mb:" run.log`
2. 崩溃诊断：`tail -n 50 run.log`
3. **保护 Agent 上下文窗口**——不让训练输出淹没 LLM 的 context

---

## 7. 模型与训练细节

### 7.1 模型架构

GPTConfig 默认配置（train.py 第 33-40 行）：

```python
@dataclass
class GPTConfig:
    sequence_len: int = 2048
    vocab_size: int = 32768
    n_layer: int = 12
    n_head: int = 6
    n_kv_head: int = 6
    n_embd: int = 768
    window_pattern: str = "SSSL"
```

实际运行时通过 `build_model_config()` 根据 DEPTH 动态计算：
- `DEPTH = 8`，`ASPECT_RATIO = 64` → `base_dim = 512` → 对齐到 HEAD_DIM=128 → `model_dim = 512`
- `num_heads = 512 / 128 = 4`

核心架构特性：
- **Activation**: `F.relu(x).square()` — Squared ReLU
- **Normalization**: RMS Norm，无 bias
- **Attention**: Flash Attention 3，支持 Hopper (H100) 和非 Hopper GPU
- **Value Embedding (ResFormer)**: 交替层有 value embedding，用 input-dependent gate 混入
- **Sliding Window Attention**: "SSSL" 模式，S = 半上下文窗口，L = 全上下文窗口
- **Residual Lambda**: 每层有可学习的 `resid_lambdas` 和 `x0_lambdas`
- **Logit Soft-capping**: `softcap = 15`，logits 经过 tanh 压缩
- **RoPE**: 标准旋转位置编码

### 7.2 优化器配置

**双优化器设计** — MuonAdamW：

| 参数组 | 优化器 | 学习率 | 备注 |
|--------|--------|--------|------|
| lm_head (unembedding) | AdamW | 0.004 * dmodel_scale | betas=(0.8, 0.95) |
| wte (embedding) | AdamW | 0.6 * dmodel_scale | |
| value_embeds | AdamW | 0.6 * dmodel_scale | |
| resid_lambdas | AdamW | 0.005 | |
| x0_lambdas | AdamW | 0.5 | betas=(0.96, 0.95) |
| transformer 矩阵参数 | **Muon** | 0.04 | momentum=0.95, ns_steps=5 |

Muon 优化器核心是 **Polar Express 正交化**（近似矩阵极分解），还包括 **NorMuon 方差归约** 和 **Cautious weight decay**。

### 7.3 训练超参数

```python
TOTAL_BATCH_SIZE = 2**19    # ~524K tokens/step
DEVICE_BATCH_SIZE = 128     # 每次前向/反向的样本数
WARMUP_RATIO = 0.0          # 无 warmup
WARMDOWN_RATIO = 0.5        # 后 50% 时间做 LR 衰减
FINAL_LR_FRAC = 0.0         # 衰减到 0
WEIGHT_DECAY = 0.2          # Muon 的 cautious weight decay
```

### 7.4 5 分钟预算计时

`TIME_BUDGET = 300` 秒（prepare.py 第 31 行）。

关键：**前 10 步不计入训练时间**（排除 torch.compile 编译开销）：
```python
if step > 10:
    total_training_time += dt
# ...
if step > 10 and total_training_time >= TIME_BUDGET:
    break
```

---

## 8. 关键代码片段

### 片段 1：评估不可篡改的核心 — 常量与评估分离

```python
# prepare.py 第 30-32 行
MAX_SEQ_LEN = 2048
TIME_BUDGET = 300        # 5 minutes
EVAL_TOKENS = 40 * 524288  # ~20M tokens
```

**启发性**：所有"游戏规则"放在只读文件中。Agent 能改的只有"怎么玩"，不能改"怎么算分"。

### 片段 2：实验输出的标准化格式

```python
# train.py 第 621-631 行
print("---")
print(f"val_bpb:          {val_bpb:.6f}")
print(f"training_seconds: {total_training_time:.1f}")
print(f"peak_vram_mb:     {peak_vram_mb:.1f}")
```

**启发性**：固定格式文本 + grep 提取，比 JSON/API 更简单抗错。

### 片段 3：Fast-fail 机制

```python
if math.isnan(train_loss_f) or train_loss_f > 100:
    print("FAIL")
    exit(1)
```

**启发性**：不等 5 分钟跑完才发现失败。fail fast 原则。

### 片段 4：GC 冻结避免训练抖动

```python
if step == 0:
    gc.collect()
    gc.freeze()
    gc.disable()
elif (step + 1) % 5000 == 0:
    gc.collect()
```

**启发性**：Python GC 会造成约 500ms 训练卡顿。第一步后冻结 GC。

### 片段 5：Squared ReLU 激活

```python
x = F.relu(x).square()
```

**启发性**：不是标准 GeLU/SwiGLU，而是 squared ReLU（Primer 论文），极简实现。

### 片段 6：BOS-aligned best-fit packing DataLoader

```python
def make_dataloader(tokenizer, B, T, split, buffer_size=1000):
    """BOS-aligned dataloader with best-fit packing.
    Every row starts with BOS. Documents packed using best-fit to minimize cropping.
    100% utilization (no padding)."""
```

**启发性**：无 padding 的高效文档打包——100% token 利用率。

### 片段 7：stdout 重定向保护 Agent 上下文

```
# program.md 第 99 行
uv run train.py > run.log 2>&1 (redirect everything — do NOT use tee or let output flood your context)
```

**启发性**：训练输出会耗尽 LLM 上下文窗口。长命令必须重定向。

---

## 9. 使用方法与命令

### 9.1 环境要求

- 单块 NVIDIA GPU（H100 上测试）
- Python 3.10+
- [uv](https://docs.astral.sh/uv/) 包管理器
- CUDA 12.8

### 9.2 依赖项

```
torch==2.9.1, kernels>=0.11.7, rustbpe>=0.1.0, tiktoken>=0.11.0
pyarrow>=21.0.0, requests>=2.32.0, numpy>=2.2.6
pandas>=2.3.3, matplotlib>=3.10.8
```

### 9.3 安装与运行

```bash
# 1. 安装 uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# 2. 安装依赖
uv sync

# 3. 数据准备（一次性，约 2 分钟）
uv run prepare.py

# 4. 手动验证训练（约 5 分钟）
uv run train.py

# 5. 启动 Agent（以 Claude 为例）
# "Hi have a look at program.md and let's kick off a new experiment!"
```

### 9.4 数据

- 数据集：`karpathy/climbmix-400b-shuffle`（HuggingFace）
- 默认 10 训练分片 + 1 固定验证分片 (shard_06542)
- 存储：`~/.cache/autoresearch/`
- Tokenizer：rustbpe BPE，vocab_size = 8192 + 4 special tokens

---

## 10. 社区与生态

### Notable Forks

| Fork | 平台 |
|------|------|
| miolini/autoresearch-macos | macOS |
| trevin-creator/autoresearch-mlx | macOS (MLX) |
| jsegov/autoresearch-win-rtx | Windows |
| andyluo7/autoresearch | AMD GPU |

### 实验成果

从 progress.png：共 83 次实验，15 次改进保留，val_bpb 从 ~0.998 降至 ~0.976（约 2.2% 提升）。大部分改进集中在前 50 次，后期收益递减。

---

## 11. 对 AutoAgent 的启发

### 1. 评估函数必须与可编辑代码物理隔离
→ 关联 ISS-032。评估脚本和评估数据放在 Agent 不可写的路径。

### 2. 用 Git reset 实现无状态实验回滚
→ Layer 1 POC 阶段每个 Worker 可用 "commit-try-reset" 循环快速迭代。

### 3. 重定向输出保护上下文窗口
→ Worker 指引加入：长时间运行命令必须重定向到日志，只 grep 关键指标。

### 4. program.md 作为极简 Skill 的范式
→ 114 行定义完整 Agent 行为。关联 ISS-009。

### 5. 固定预算 + 单一指标 = 公平对比
→ 关联 ISS-033。每个项目定义一个"北极星指标"。

### 6. "NEVER STOP" 的选择性采纳
→ Layer 2 Worker 内部可采纳——持续工作直到完成或被中断，不主动请示。

### 7. results.tsv 标准化实验日志
→ 每个项目标准化 `EXPERIMENT_LOG.tsv`（commit + 指标 + 状态 + 描述），比 OV 更轻量。
