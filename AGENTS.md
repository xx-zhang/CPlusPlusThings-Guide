# AGENTS.md — 给任何 AI 代理或未来会话的仓库说明

> 本文件是**固定约定**（常驻指令）。详细状态与重启步骤见同目录 `session-handoff.md`；活待办见 `TODO.md`。

## 这是什么仓库

`xx-zhang/CPlusPlusThings-Guide`：C++ 知识体系 + 学习方法 + ROS2 架构映射的**交付仓库**。
- 内容：`auxiliary/` 下 27 篇文档（00-26）+ `lessons/`；导航入口 = `auxiliary/README.md`，知识地图 = `auxiliary/07-场景体系总览.md`；**骨架正身/入口 = `auxiliary/26-骨架总图与索引.md`**；能力引擎 = `auxiliary/25-专家练习路径.md`。
- 形态：也是 Obsidian vault——**WSL 侧 `~/CPlusPlusThings-Guide` 是内容权威**，Windows 宿主侧镜像在 `D:\Obsidian\CPlusPlusThings-Guide`（两处都要能打开），README/文档均为纯 Markdown。
- 关系：内容源是 `/home/user/CPlusPlusThings/auxiliary`（被 `rsync -a --delete` 同步过来），**修改一律改源再同步**，见下「同步流程」。

## 用户目标（一切工作的校准器）

1. 读 / 改 / 审 **AI 生成的 C++ 代码**（CAE/EDA 方向）。
2. **对标未来 ROS2 架构与程序设计**（`auxiliary/15-19`），并进一步服务于**具身智能**（`auxiliary/21`）。
4. **当前阶段：理论优先**——先把骨架打扎实（读 `00`→`01`→`26`），**暂不启动实践循环**（`25` 的 12 周计划待理论验收后再开）。
3. 学习方式偏好：学的是**驾驭知识的能力**（六步实证法，见 03），反对无脑堆知识、反对知识收藏。

## 核心约定（改任何文档前必读，违反等于破坏体系）

1. **实证原则（最高优先级）**：每条技术结论必须附「实测命令 + 真实输出」或标准条款；做不到就显式标「存疑」。环境基准：`g++ 14.2.0 / clang++ 19.1.7 / x86-64 Linux / Itanium ABI`。涉及布局/汇编/ABI 的结论必须标注「换平台需重测」。
2. **术语体系不可改名**：公理 `A1-A5`；定理 `T1-T7`；体系 `07-19`；记忆层 `L1 背 / L2 钩子 / L3 查`；方法 `六步实证法（定位→预测→实测→对账→反例→归档）`。新增术语需先在 `01` 挂靠。
3. **Markdown 规则**：纯文本代码块必须标 ` ```text `；**不得用单独成行的 `**粗体**` 当标题**（MD036——该行必须以全角 `：`/`。` 结尾）；表格里 `<br>` 可接受。
4. **交叉引用**：文档互相引用（01↔08↔07↔14 等）；改一篇必须同步相关索引（`auxiliary/README.md`、`07` 图谱、根 README）。
5. **同步与交付**：改 `auxiliary/` 源 → `rsync -a --delete auxiliary/ ~/CPlusPlusThings-Guide/auxiliary/` → 根 README 索引同步 → **`~/bin/vault-sync`（同步到 Windows 宿主镜像）** → commit + push（中文 commit message，带 `docs:` 前缀）。
6. **诚实**：明确标注「框架不覆盖什么」（见 01 附 / 0.5.4 四域分类）；不夸大覆盖度。**禁用「已闭合/完结」这类无限定语**，要么说「在 X 判据下闭合」。
7. **单一事实源（SSOT）**：同一事实只在一处维护——活缺口台账→ `26 §1.4`；实测数字→ `08 §3.2`；环境指纹→ `26 §1.6`。**别处只引用，不复制**；随机性数字必须标「某次运行」（随机结果不是标准值）。
8. **文档准入闸门**（防止“一被问就加文档”）：新增文档前必答三问——① 这是**新维度**还是已有维度的内容？② 它**改变了判据**吗？③ 用户要的是「现在知道」还是「落成文档」？答不出就**不写**，只在对话里答。
9. **加固饱和判据**：加固 = 提高一致性/可检验性/抗腐化，**不是**增加内容。四项饱和即停：内容可推导或已标定约定 · 结论有可执行证伪手段 · 引用无断链且事实无重复源 · 自检可机器执行。**改完文档必跑 `auxiliary/check.sh`**（**13 项检查**，必须全绿；含 SSOT 三级保护、实测回归、意图挂靠一致性、交接文档计数一致性、**并发自死锁回归**）。

## Windows 宿主镜像（改完文档必做，否则宿主 Obsidian 看到旧内容）

- **Windows 侧 vault**：`D:\Obsidian\CPlusPlusThings-Guide`（WSL 内即 `/mnt/d/Obsidian/CPlusPlusThings-Guide`），已在 Windows Obsidian 注册。
- **为什么需要它**：Windows 版 Obsidian **不能**可靠打开 `\\wsl.localhost\...` 下的 vault（9p 文件监听报 EISDIR / 漏事件），所以必须有 NTFS 上的一份。
- **同步命令**：`~/bin/vault-sync`——哈希驱动、双向、WSL 侧胜出；`-n` 只看计划、`--status` 只报告。用户侧一键入口 `D:\Obsidian\vault-sync.bat`（桌面亦有副本）。
- **代理规则**：改完任何 `.md` 后跑一次 `~/bin/vault-sync`，再 commit + push。
- **不用 rsync/mtime 的原因**：`/mnt/d` 以 `uid=0` 且无 `metadata` 挂载，非 root 不能 `chmod`/`utimes`，Windows 侧时间戳不可靠。
- **不同步**：`.git/`（Windows 侧不做仓库）与 `.obsidian/`（两端各留本地配置）。
- **冲突**：Windows 侧版本自动另存到 `D:\Obsidian\CPlusPlusThings-Guide-conflicts\<时间戳>\`；覆盖前副本在 `~/.local/state/cplusplus-vault-sync/backup/`。

## 当前状态速览

- 交付完成：01-19 + lessons/01（详见 `session-handoff.md` 第 2 节时间线）。
- 下一步：**等用户选应用靶子**（TODO.md 的「当前决策」区块）：A 现场拆真实代码 / B 做小项目或装 ROS2 / C 暂停。
- 环境事实（见 `session-handoff.md` 第 7 节）：本机**无 ROS2**、perf 硬件计数器不可用、TSan 需 `setarch -R`、Obsidian 1.13.7 运行中。

## 已沉淀的记忆（可检索）

本项目相关持久记忆：`cplusplusthings-repo-nature`（原仓库缺陷审计）、`cplusplusthings-auxiliary-framework`（内容结构与约定）、以及本会话新增的 ROS2 方向记忆。新会话用 memory 工具搜索这些名字即可。