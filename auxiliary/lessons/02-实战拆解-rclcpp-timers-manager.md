# 第 2 课 · 实战拆解：rclcpp `TimersManager`（陌生代码 30 分钟）

> **底本**：`ros2/rclcpp` @ `ffa07ee`（2026-09-16），文件 `rclcpp/src/rclcpp/experimental/timers_manager.cpp` + 同名 `.hpp`。
> **为什么挑它**：具身智能的定时器回调是最常见的"现场"，而这份代码**同一文件里两种写法并存**——正确与危险各一处，是"用体系拆陌生代码"的理想标本。
> **本课产出**：一条新判据（**thread-safe ≠ reentrant**）+ 一个可复用模式的命名（**锁内收集，锁外调用**）+ 一个确定性回归（`check.sh` 第 13 项）。
> **走法**：严格按 `03` 的**六步实证法**（定位 → 预测 → 实测 → 对账 → 反例 → 归档）。**① ② 步不允许看代码**——先查框架，先写预测。

---

## ① 定位（查框架，不看代码）

拿到"定时器管理器"这个题目，**先不打开源码**，回答：它挂在哪？

| 线索 | 定位结果 |
| --- | --- |
| 名字里有 `Manager`、`timers`、"storing and executing timer objects" | **不是** A3/T5（对象模型/虚分派）——没有类型层次问题 |
| 文档自述 "spawn a thread"、"on_ready_callback" | 落在 **`11` 并发与内存模型** + **`17` 事件驱动与执行器并发** |
| "weak pointers"、"locks them only when they need to be executed" | 同时落在 **`16` 所有权**（弱所有权 = 生命周期问题） |
| 涉及"内部堆 + 锁" | `10` 容器（堆不变量）作为背景，不是主线 |

**结论**：主战场是 **`17 §1.4 黄金规则` + `17 §1.5 线程安全判据`**，副战场是 **`16` 弱所有权**。→ 判据应从 `08 §1.8` 的"回调黄金规则"和 CG **CP.22** 里取。

---

## ② 预测（先写下来，再去验——这步不能跳）

来自体系的两条判据：

```text
判据 A（17 §1.4 黄金规则）：回调必须短小、非阻塞、不分配
判据 B（CG CP.22）        ：持锁时绝不调用未知代码（回调是未知代码的典型）
判据 C（危险信号⑥）      ：data race 是 UB —— 但这里要问的不是 race，是"锁范围"
```

**预测 P1**：该管理器若是"线程安全"，其内部必有一把 mutex；若它在**持锁状态下调用用户回调**，则回调里任何"回头调用本管理器 API"的动作会**同线程重入同一把非递归 mutex → 必然死锁**。
**预测 P2**：如果作者懂这条规则，应该能在代码里看到**为了"锁外调回调"而出现的显式作用域花括号**（这是该规则在代码上的指纹）。

> 预测写完了。**下面才开始看代码**——这是本课与"直接读源码"的全部差别。

---

## ③ 实测

### 3.1 代码证据：指纹出现了，而且是"两种写法并存"

`execute_ready_timer()` —— **正确**，锁被显式限制在一个花括号内：

```cpp
void TimersManager::execute_ready_timer(
  const rclcpp::TimerBase * timer_id, const std::shared_ptr<void> & data)
{
  TimerPtr ready_timer;
  {
    std::unique_lock<std::mutex> lock(timers_mutex_);
    ready_timer = weak_timers_heap_.get_timer(timer_id);
  }                                          // ★ 出花括号 = 解锁
  if (ready_timer) {
    ready_timer->execute_callback(data);      // ★ 锁外调未知代码
  }
}
```

`execute_head_timer()` —— **危险**，同一个文件，同一把锁，但回调在锁内：

```cpp
bool TimersManager::execute_head_timer()
{
  std::unique_lock<std::mutex> lock(timers_mutex_);   // ★ 一直持有到函数尾
  TimersHeap timers_heap = weak_timers_heap_.validate_and_lock();
  ...
  head_timer->execute_callback(data);                 // ★ 持锁调未知代码
  ...
}
```

**判据 B 的指纹出现了**：`execute_ready_timer` 里那对"多余"的花括号，正是作者知道规则、并刻意执行它的证据。既然如此，`execute_head_timer` 的写法就**不是风格差异，而是不一致**——不一致是真缺陷的强先兆。

### 3.2 但"两种写法"还不够：判据 B 必须先查**契约与配置**

这里是最容易误报的地方。`run_timers()` 的锁作用域是**整个循环体**：

```cpp
while (rclcpp::ok(context_) && running_) {
  std::unique_lock<std::mutex> lock(timers_mutex_);   // 循环体内声明
  ...
  this->execute_ready_timers_unsafe();                // 锁仍持有
}
```

而 `execute_ready_timers_unsafe()` 有**两条分支**：

```cpp
if (on_ready_callback_) {
  on_ready_callback_(head_timer.get(), data);   // 分支一
} else {
  head_timer->execute_callback(data);           // 分支二：直接在锁内跑用户回调
}
```

再去问**谁传了这个回调**（`events_executor.cpp`）：

```cpp
if (!execute_timers_separate_thread) {
  timer_on_ready_cb = [this](const rclcpp::TimerBase * timer_id, const std::shared_ptr<void> & data) {
      ExecutorEvent event = {timer_id, data, -1, ExecutorEventType::TIMER_EVENT, 1};
      this->events_queue_->enqueue(event);      // ★ 只入队，立即返回
    };
}
timers_manager_ = std::make_shared<TimersManager>(context_, timer_on_ready_cb);
```

**于是结论必须按配置分支给出**（否则就是乱报警）：

| 配置 | 锁内实际执行的东西 | 判定 |
| --- | --- | --- |
| `on_ready_callback` **有**（`execute_timers_separate_thread = false`，**默认**） | `enqueue()` 一次入队，**不含用户代码** | ✅ 安全：出锁后执行器再调 `execute_ready_timer`（锁外跑回调） |
| `on_ready_callback` **无**（`execute_timers_separate_thread = true`） | `head_timer->execute_callback(data)` = **用户回调** | ❌ 持锁调未知代码 |
| 任何配置下调 `execute_head_timer()`（公开 API，手动泵路径） | **用户回调** | ❌ 同上 |

**危险的三要素合取**：非递归 `std::mutex` ∧ 锁内调未知代码 ∧ 回调回头调用本管理器 API。

### 3.3 机制实测：三组对照 + gdb 抓栈

rclcpp 本体在本机无法构建（无 ROS2 环境），所以**复刻锁纪律做最小重现**（这是机制证明，不是 rclcpp 本体运行——如实标注）：

```text
① std::mutex          + 回调重入 add_timer   → 挂死 ❌
② std::recursive_mutex + 回调重入 add_timer   → 正常 ✅
③ std::mutex          + 回调只入队(默认路径)  → 正常 ✅
```

**因果被钉死**：问题既不是"锁"（③ 正常），也不是"重入"（② 正常），而是**三者的合取**。这与"危险信号⑨？"式的单点记忆不同，必须记成组合条件。

gdb 抓栈（程序 `alarm(2)`，gdb `handle SIGALRM stop nopass` 捕获），**同一线程卡在自己已持有的锁上**：

```text
#0  futex_wait (futex_word=0x7fffffffdc70, expected=2, private=0)
#1  __GI___lll_lock_wait (futex=futex@entry=0x7fffffffdc70)
#3  ___pthread_mutex_lock (mutex=0x7fffffffdc70)
#5  std::mutex::lock (this=0x7fffffffdc70)
#6  std::unique_lock<std::mutex>::lock
#8  MiniManager::add_timer (this=0x7fffffffdc70)     ← 想拿锁
#9  operator() (__closure=...)                       ← 用户回调
#10 std::__invoke_impl<void, main()::<lambda()>&>     ← 经 std::function 调用
```

`add_timer` 的 `this` 与 `std::mutex::lock` 的 `this` 是**同一个地址**：同线程、同一把锁、非递归 ⟹ `futex_wait` 永不返回。

---

## ④ 对账：上游怎么看

这一步决定了"我发现的"是"真问题"还是"我少见多怪"。检索上游后：

| 上游证据 | 原话 | 与本次拆解的关系 |
| --- | --- | --- |
| **PR #2890**（修 issue #2889） | "the events executor **just deadlocks if you reset a timer from within a timer**" | ✅ 预测的场景逐字命中 |
| **commit 5ecf85a**（#3097） | "fix deadlock due to **double acquisition of an internal lock within the timer manager**" | ✅ 与 gdb 栈（同线程重入）**同一根因表述** |
| 上游**新组件** `events_cbg_executor/timer_manager.hpp` | "We need to do this **out of the scope of the mutex, to avoid a deadlock**, as the timer_ready function will need to acquire the callback group mutex" | ✅ 上游自己写出了本课判据 B |

上游新组件的修法，就是本课要命名的模式：

```cpp
std::vector<std::function<void()>> ready_timer_callbacks;
{
  std::scoped_lock l(mutex);
  ready_timer_callbacks = get_ready_timer_callbacks();   // 锁内：只收集数据
}                                                         // ★ 解锁
for (const std::function<void()> & f : ready_timer_callbacks) {
  f();                                                    // 锁外：调未知代码
}
```

**命名：锁内收集，锁外调用**（collect-under-lock, invoke-outside）。三个要点：① 收集到**局部容器**（延长实体生命周期，防悬垂）；② 用**作用域**结束锁，不靠手工 unlock；③ 只把"数据"带出锁，不把"待执行的动作"在锁内执行。

---

## ⑤ 反例：什么情况下这**不是** bug（防误报）

`29` 已经教过一次：读陌生代码先问"它的契约是什么"，而不是直接判定缺陷。本例的三道"免责"检查：

1. **默认配置是安全的**。`execute_timers_separate_thread` 默认 `false` ⟹ 默认走 `enqueue` 路径。说"rclcpp 定时器回调死锁"而**不提配置**，就是错报。
2. **文档有契约声明**（`timers_manager.hpp` 末尾）："This class assumes that the `execute_callback()` API of the stored timers is **never called by other entities**, but it can only be called from here." —— 管理器把自己当成唯一执行者。**但这句契约并没有说"回调内不得回头调用本类 API"**，而 API 文档却承诺 "All public APIs provided by this class are **thread-safe**" ⟹ 这正是 §⑥ 要固化的判据漏洞。
3. **弱所有权本身不是缺陷**。`WeakTimersHeap` 因 `weak_ptr` 会失效而破坏堆不变量，作者用 `validate_and_lock()` 重建堆——这是**自觉的取舍**（用一次重堆换"定时器析构不会悬垂"），不是失误。

> **误报与真报的分界线**：真报要求指出**触发条件**（哪个配置/哪条入口）+ **后果**（死锁，而非"结果不确定"）+ **证据**（栈或上游确认）。只说"这里持锁调回调，危险"，是半成品。

---

## ⑥ 归档

| 动作 | 落点 |
| --- | --- |
| 新判据 **thread-safe ≠ reentrant** | `08 §1.8`（必背）+ 本课 |
| 新判据 **持锁不调未知代码**（含"锁内收集、锁外调用"模式） | `17 §1.4` 黄金规则补第 4 条 |
| 反例条目 | `08 §3.2` 反例档案 |
| 确定性回归 | `check.sh` **第 13 项**（三组合取：非递归锁 + 锁内调未知代码 + 重入 ⟹ 挂死） |
| 可复用模式 | 本课 §④（命名：锁内收集，锁外调用） |

---

## ⑦ 方法复盘（本课真正的收获）

**体系起作用的三个时刻**：

1. **① 定位让"先看哪里"变成了机械动作**——不用通读 `.cpp`，先由"线程 + 回调 + 弱指针"三个词定位到 `17`/`16`，判据随即到手。
2. **② 预测先于阅读**——预测 P2（"应该能看到为锁外调用而存在的花括号"）让"两种写法并存"从"没注意"变成"证据"。**先写预测，才能把阅读变成验证。**
3. **③ 实测把"我觉得"变成"同一地址"**——`this` 地址相同这一条，比任何说理都硬。

**差点误报的一刻（最值得记）**：读完 `execute_head_timer` 时，"持锁调回调"已经成立，很容易直接下结论。是**回到契约与配置**（`on_ready_callback` 是否存在、默认值是多少、文档承诺了什么）才把结论收窄成"按配置分支"的精确判断。**判据给出怀疑，契约给出边界。**

**本课与 `29` 的关系**：`29` 的教训是"Eigen 写裸 `new` 是契约，不是缺陷"；本课的教训是"rclcpp 默认配置安全，危险在可选分支"。**同一个纪律：先读契约，再谈缺陷。**
