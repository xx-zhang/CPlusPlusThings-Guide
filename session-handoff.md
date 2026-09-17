# Session Handoff — 会话交接与重启指南

> **目的**：任何新会话、新代理或中断后的我，都能从这里**快速恢复完整上下文并重启**。
> **阅读顺序**：`AGENTS.md`（约定）→ 本文件（状态）→ `auxiliary/README.md`（导航）→ `TODO.md`（活待办）。
> **上次截止**：2026-09-15（ROS2 补充完成后）。

---

## 1 · 交付清单（产物现状）

| 项 | 位置 | 状态 |
| --- | --- | --- |
| 交付仓库 | `github.com/xx-zhang/CPlusPlusThings-Guide`（分支 `main`） | ✅ 已推送 |
| Obsidian vault（WSL 侧，内容权威） | `~/CPlusPlusThings-Guide`（Linux Obsidian 已注册，id `ef320ff5bc7fdb90`） | ✅ 运行中 |
| Obsidian vault（Windows 宿主镜像） | `D:\Obsidian\CPlusPlusThings-Guide`（已注册 id `c9a1f3e2b7d40815`；WSL 内 `/mnt/d/...`；同步器 `~/bin/vault-sync`） | ✅ 已建 |
| 文档全集 | `auxiliary/00~28` + `lessons/01` + **`check.sh`** + 根 README/AGENTS/handoff/TODO | ✅ 29 篇 + 1 脚本 |
| 代码源副本 | `/home/user/CPlusPlusThings/auxiliary`（上游 Light-City/CPlusPlusThings 的克隆工作区） | ✅ 同步源 |

**文档矩阵**（27 篇）：
`00` 方法论自检与迁移（三源对齐/自验协议/张力清单/缺口/生活工作延申）· `01` 知识框架（含第 0.5 层元公理）· `02` 正交轴与术语速查 · `03` 学习方法六步法 · `04` 14 课路线 · `05` 实验工具箱 · `06` 仓库审计报告 · `07` 场景体系总览（知识总图谱）· `08` 记忆固化手册 · `09` 异常与错误处理 · `10` 容器与算法 · `11` 并发与内存模型 · `12` 模板与泛型 · `13` 内存与性能 · `14` 调试与排错 · `15` ROS2 架构映射（锚）· `16` 所有权与智能指针 · `17` 事件驱动与执行器并发 · `18` 零拷贝与实时安全 · `19` 构建与插件 · `20` 领域进入方法论（v2，含学习者批判：目标/激励/反馈三补与 γ 源找回）· `21` 具身智能与跨领域加固（六缺口 + 五轴 + 冲突仲裁 + C++ 高优先四项）· `22` 语言核心暗角（名字查找/重载/初始化/ODR）· `23` 标准库全景 · `24` 工程化与工具链（CI 五层）· `25` 专家练习路径（L1-L4 + 四环 + 8 项轮子 + 12 周 + M1-M6）· **`26` 骨架总图与索引（总图 + 完整性自检 + 全量索引，理论阶段的入口）**。

---

## 2 · 交付时间线（git log，可分块）

```text
bb3c92b  初始 9 篇（01-06 + lessons/01 + README）
53a7f19  .gitignore（忽略 .obsidian/）
ccd32af  第 0.5 层元公理（设计决策/自洽性/四域边界/可迁移五步法）
1b0501b  08 记忆固化手册（记忆三层 + 24 条实测反例 + 记忆卡 + 复习计划）
5de1618  07 知识总图谱 + 09-14 六大场景体系（异常/容器/并发/模板/性能/调试）
b5d3c52  15-19 ROS2 补充体系（架构映射/所有权/执行器并发/零拷贝实时/构建插件）
d954c03  A2/A3 世界-语义关系校准（非并列公理；「公理」降级为模型）
（本次）00 方法论自检与迁移（回应「公理是否牵强」+ 缺口自检）
（本次）20 领域进入方法论 v2（整合学习者对 00 §6 的批判：补目标/激励/反馈，找回 γ 源，重排认知顺序）
（本次）21 具身智能与跨领域加固（目标升级；五轴加固；证据分级；多规则系统共存=契约/守门/优先级/降级）
（本次）22-25 回到 C++ 主线补齐「专家」四块：语言暗角 / 标准库全景 / 工程工具链 / 刻意练习引擎
（本次）**体系加固收尾（b)(c) 两处半）**：26 §1.6 的证伪命令补齐 **T1-T12 全部 12 条**；SSOT 规则**细化为三级**（非确定性数字/台账/确定性实测，其中第③级**不去重而用回归锁住**——避免牺牲可读性）；check.sh 由 6 项扩到 **10 项**
（本次）**体系加固（H1-H4）**：26 维度清单**推导化**（必答 8 问 → 8 维，补「证据」「演化」）；01 的 12 条定理**全部补齐「失效前提」字段**；建立 **SSOT 规则**（活缺口台账→26 §1.4、实测数字→08 §3.2、环境指纹→26 §1.6，别处只引用不复述）并修掉 `00 §5` 与 `26 §1.4` 的口径矛盾、`11` 里的随机数字复述；新增 **`check.sh`**（机器自检，本轮扩到 **11 项**：引用完整性/定理字段/结构规则/README 收录/计数一致/实测回归/**SSOT①非确定性数字不外泄**/**SSOT②台账指针**/**SSOT③去虚化回归**/**SSOT③弱符号回归**）；README 补收 27/28；AGENTS 增规则 7-9（SSOT/文档准入闸门/加固饱和判据）
（本次）**理论骨架闭合**：01 新增 T8-T12（类型代数/契约/求值顺序/实现模型/程序生命周期），原 00 §5 缺口全部升为一等定理；新增 `26` 骨架总图与**完整性自检**
```

---

## 3 · 关键设计决策（为什么这么建，别推翻）

| 决策 | 理由（一句话） |
| --- | --- |
| 公理 A1-A5 = Stroustrup 设计决策的投影（0.5.1） | 让框架有「唯一真公理层」，可迁移到任何系统 |
| 0.5.5 可迁移五步法 | 用户明确看重「驾驭知识的能力」> 知识本身 |
| 实证原则：每条结论附实测命令+输出 | 这是全套资料的立身之本；06 审计 33 条错误全实测 |
| 记忆三层 L1 背/L2 钩子/L3 查 | 记忆负担从「背 95 条」降到「背 ~20 条 + 会分类」 |
| ROS2 用「15 锚文档 + 16-19 四补充」结构 | 已有语言内核全部有效，只补 4 个架构层缺口 |
| 同步方向：`/home/user/CPlusPlusThings/auxiliary` → guide 仓库 | 保持单一内容源，防分叉 |
| Windows 宿主 vault 是**镜像**而不是第二个内容源（哈希双向同步，WSL 胜出） | Windows Obsidian 打不开 `\\wsl.localhost\` vault（EISDIR），又不能让宿主侧变成可写第二真源 |

---

## 4 · 未完成待办（详细勾选版见 `TODO.md`）

```text
[等用户决策] 应用靶子（A 现场拆代码 / B 小项目或装 ROS2 / C 暂停）
  - 若 B：选纯 C++ mini 项目（练 09-14）或「装 ROS2 走通最小节点」
[可选增强，未启动]
  - rclcpp 源码阅读指南（executor.cpp / intra_process_manager.cpp / node.hpp）
  - DRE / Events Executor 小节（进 15 附录，约 20-30 行）
  - ROS2 环境安装步骤 + 常见坑清单（Humble 或 Jazzy + colcon）
[用户的活，持续推进]
  - 08 记忆卡逐课填卡 + 反例档案持续增补（每做一个实验记一行）
  - 07 图谱 14 块行逐个打勾
```

---

## 5 · 重启步骤（30 秒恢复上下文）

```bash
# 1. 看状态
cd ~/CPlusPlusThings-Guide && git log --oneline | head -8 && ls auxiliary/
# 2. 读导航（15 秒）
#    auxiliary/README.md（文件地图）→ auxiliary/07（知识总图谱）→ TODO.md
# 3. 验证环境（本机）
g++ --version | head -1        # 14.2.0
gh auth status                 # 已登录 xx-zhang（https 协议）
# 4. 要改文档时的同步链路（重要！）
#    改 /home/user/CPlusPlusThings/auxiliary 下源文件
#    rsync -a --delete auxiliary/ ~/CPlusPlusThings-Guide/auxiliary/
#    （根 README 索引同步）→ ~/bin/vault-sync → commit + push
```

---

## 6 · 关键实测证据库（可信度基石 + 防重复实验）

> **SSOT**：完整清单只在 `auxiliary/08-记忆固化手册.md` §3.2（24 条），别处引用不复述；随机性数字标「某次运行」。以下是最常被复引的 12 条：

```text
1.  const 与 #define：两个 TU 各写 const int c（1/2）链接通过、各用各的 → 内部链接、一份/每 TU
2.  inline = 弱符号 W；inline 变量 = 符号 u（GNU unique，不是 W！）
3.  static vs inline：3 个 TU 内 cnt_static 三个地址 / cnt_inline 一个地址
4.  volatile 同步失败：2×20 万自增丢成 212561/329722/226264；atomic 与 mutex 恒 400000
5.  x86 `int++` 陷阱：裸 int 三局全对（单条 addl 原子），但仍是 UB；TSan 可抓（须 setarch -R 关 ASLR）
6.  noexcept 内抛 → terminate（编译器 -Wterminate 联警）；栈展开中析构抛 → terminate
7.  vector 扩容：noexcept move → 15 移动 0 复制；copy-only → 15 复制；capacity 1,2,4,8…2x
8.  多态多继承：MA(两多态基类) sizeof=16 = 两个 vptr/两张子虚表（-fdump-lang-class 实证）
9.  EBO：Empty=1 / EBO:Empty{int}=4 / NoEBO=8（基类可 0 字节，成员不行）
10. sizeof(B)=24、偏移 4/8/16，无「编译器重排」；{char,double,char}=24 vs {char,char,double}=16
11. 去虚化：call_final(Sealed&) 引用参数照样 `movl $3,%eax` 完全消除
12. dlopen/可见性：内联成员函数不产生符号（nm -D 看不到）→ 须类外定义；extern "C" 导出则可见
```

---

## 7 · 环境事实（别踩已知的坑）

```text
· 本机无 ROS2 —— 15-19 全部基于官方文档核实（Humble/Jazzy How-To、ros2/design 文章、issue #726），
  未在任何 rclcpp 实机上验证。真做 ROS2 时第一步是装环境。
· perf 硬件计数器不可用（cycles/instructions = not supported），只能 perf stat 的时间指标 + time。
· TSan 默认 FATAL: unexpected memory mapping → 必须 setarch $(uname -m) -R ./prog。
· /usr/bin/time 不存在 → 计时用 date +%s%N 或 shell time。
· Obsidian 1.13.7 在跑，vault 直接读本仓库（改文件即所见）。
· 本会话的验证脚本散落在 /tmp/v2、/tmp/audit、/tmp/l1check（一次性，非交付物；需要时重新跑文档里的命令）。
```

---

## 8 · 与用户（学习者）的沟通约定

```text
· 用中文交流；交互式教学格式：预测 → 实测 → 对账。
· 用户偏好：边界清晰、诚实（包括明确说"框架不覆盖什么"）、把学习当作"驾驭知识的能力"而非知识收藏。
· 不要为了"看起来全"而自动加文档——用户已明确：材料够了，下一步是动手。
· 相关持久记忆：cplusplusthings-repo-nature / cplusplusthings-auxiliary-framework（含 ROS2 方向）。
```