+++
title = "CSAPP Shell Lab 学习记录 01：从 trace02 到 trace08"
date = 2026-04-16T00:00:00Z
draft = false
tags = ["csapp", "shell-lab", "process", "signal", "job-control"]
+++

今天把 CSAPP 的 Shell Lab 往前推进了一截，虽然还没有写完，但总算把最核心的那条主线理顺了：`eval`、`waitfg`、`sigchld_handler` 到底是什么关系，`SIGINT`、`SIGTSTP` 为什么不是“直接把 shell 杀掉”，以及 `pid`、`jid`、进程组之间到底谁是谁。

这篇不追求把 Shell Lab 一次讲完，而是把今天真正弄明白的东西记下来。对我来说，这次的进展不在于多过了几条 trace，而在于第一次开始用“进程 + 信号 + job 表”这个模型去看整个 lab，而不是只盯着某几行代码。

## 当前进度

今天的实现大概推进到了 `trace08` 左右。按 trace 数量粗看，已经走到一半；但如果按难度看，真实进度可能更接近 40% 到 45%。

已经基本打通的链路有：

- `eval` 能区分 builtin 和普通命令。
- 普通命令能 `fork` 出子进程，并由子进程 `execve` 运行。
- 父进程会把 job 加入 `jobs[]`。
- 前台 job 会通过 `waitfg(pid)` 等待。
- 子进程退出、被 `Ctrl+C` 终止、被 `Ctrl+Z` 暂停时，`sigchld_handler` 都能收到并更新状态。
- `SIGINT` 和 `SIGTSTP` 已经知道应该转发给“前台进程组”，而不是 shell 自己。
- `jobs` 内建命令已经有了基本行为。

还没真正完成的重点，是后半段的 `bg` / `fg`，也就是 `do_bgfg` 那条线。

## 这次真正搞清楚的主线

Shell Lab 不是一堆零散函数拼起来的，它其实一直都在围绕同一个闭环打转：

```c
eval -> addjob -> waitfg
               ^
               |
       sigchld_handler 更新 jobs[]
```

更完整一点，就是：

1. `main` 读到一行命令，调用 `eval(cmdline)`。
2. `eval` 先判断是不是 builtin。
3. 如果不是 builtin，就 `fork` 一个子进程。
4. 子进程里 `setpgid(0, 0)`，然后 `execve(argv[0], argv, environ)`。
5. 父进程把这个子进程登记到 `jobs[]` 里，状态设成 `FG` 或 `BG`。
6. 如果是前台 job，就进入 `waitfg(pid)`。
7. 当子进程退出、被信号终止、或被信号暂停时，内核给 shell 发 `SIGCHLD`。
8. shell 的 `sigchld_handler` 调用 `waitpid(...)`，更新 job 表。
9. `waitfg(pid)` 发现这个前台 job 已经不再是 `FG`，于是返回。
10. shell 再次打印新的 `tsh>`。

今天最重要的收获其实是：`waitfg` 能返回，不是因为它“自己知道前台进程结束了”，而是因为 `sigchld_handler` 改了 `jobs[]`，让 `fgpid(jobs)` 不再返回原来的那个 `pid`。

## `eval`、`waitfg`、`sigchld_handler` 的关系

我一开始一直卡在一个问题上：明明在 `eval` 里没有直接调用 `sigchld_handler`，那这三个函数到底是怎么配合起来的？

后来才彻底想通：这里不是普通函数调用链，而是“同步主流程 + 异步信号回调”的组合。

- `eval` 是主流程函数。
- `waitfg` 是 `eval` 直接调用的等待逻辑。
- `sigchld_handler` 不是 `eval` 调的，而是内核在收到 `SIGCHLD` 时异步打进来的。

也就是说：

- `eval` 负责启动 job。
- `waitfg` 负责“先别回到提示符”。
- `sigchld_handler` 负责“子进程状态变了，来收尸并更新状态”。

一旦这个关系理清，很多诡异现象就突然能解释了。

比如：

- 如果 `waitfg` 没写，shell 会太早打印新的 `tsh>`。
- 如果 `sigchld_handler` 没写，job 表不会更新，前台 job 可能永远留在 `FG`，于是 `waitfg` 会一直等。
- 如果两边都没配好，就会出现提示符和命令输出顺序乱掉、或者 job 不被清理的情况。

## `execve` 和 `environ`

今天另外一个关键点，是把 `execve` 的语义彻底分清。

```c
execve(argv[0], argv, environ);
```

这里的 `environ` 是当前进程继承下来的环境变量表，本质上就是一组字符串，例如：

- `PATH=...`
- `HOME=...`
- `TERM=...`

`execve` 的三个参数分别表示：

- 要执行哪个程序
- 新程序收到的参数数组
- 新程序继承的环境变量数组

更重要的是：`execve` 成功以后不会返回。也就是说，一旦成功，当前子进程的代码和地址空间都会被新程序替换掉。只有在 `execve` 失败时，后面的 `printf("Command not found")` 和 `exit(0)` 才会继续执行。

这也解释了另一个很容易混淆的问题：`SIGCHLD` 不是“执行到 `execve` 就触发”，而是要等子进程真正退出、终止或暂停以后，内核才会给父进程发送 `SIGCHLD`。

## 为什么要 block `SIGCHLD`

在 `eval` 里有一段看起来很绕的代码：

```c
sigset_t mask, prev;
sigemptyset(&mask);
sigaddset(&mask, SIGCHLD);
sigprocmask(SIG_BLOCK, &mask, &prev);
```

这段代码一开始完全像咒语，后来总算弄明白它的目的：防 race condition。

场景是这样的：

1. 父进程刚 `fork()`。
2. 子进程非常快地退出。
3. 内核立刻给父进程发送 `SIGCHLD`。
4. `sigchld_handler` 先跑了，把子进程回收掉。
5. 但父进程还没来得及 `addjob(jobs, pid, ...)`。

这样 job 表就会乱掉。

所以正确顺序应该是：

1. 先 block `SIGCHLD`
2. 再 `fork`
3. 父进程先安全地 `addjob`
4. 再恢复原来的 mask

这一段最容易死记硬背，但一旦把 race 的图景想明白，就知道不是为了“格式好看”，而是真的在防错误。

## `WNOHANG` 和 `WUNTRACED` 到底在干嘛

这两个 flag 是今天最值得单独记一笔的东西。

### `WNOHANG`

```c
waitpid(-1, &status, WNOHANG)
```

它的意思是：如果现在没有可处理的子进程状态变化，就立刻返回，不要阻塞。

这一点特别关键，因为 `sigchld_handler` 不能傻等未来某个子进程变化。它只应该把“现在已经发生变化”的那些子进程处理掉，然后赶紧返回。

### `WUNTRACED`

```c
waitpid(-1, &status, WNOHANG | WUNTRACED)
```

它的作用是：除了退出和终止之外，被暂停的子进程也要报告给我。

这正是 `trace08` 需要的。因为 `Ctrl+Z` 之后，前台进程不是死了，而是进入 `stopped` 状态。如果没有 `WUNTRACED`，`sigchld_handler` 很可能根本拿不到这个状态变化，也就没法把 job 改成 `ST`。

## 为什么 `Ctrl+C` 和 `Ctrl+Z` 要发给进程组

这是今天最容易绕晕、但一旦想清楚就很舒服的一块。

我一开始总想：既然 job 有 `jid`，那是不是应该按 `jid` 去“杀死”任务？

后来才理清这三个概念：

- `pid` 是系统进程号
- `pgid` 是系统进程组号
- `jid` 是 shell 自己维护出来给用户看的 job 编号

所以内核和 `kill` 真正认得的是 `pid` / `pgid`，不是 `jid`。

而且 shell 实现 job control 时，管理的对象本来就是“作业”，而作业在系统层面更接近“进程组”，不是某一个单独进程。所以当 shell 收到 `SIGINT` 或 `SIGTSTP` 时，正确的做法不是把信号发给自己，也不是只发给某一个用户态编号，而是发给当前前台 job 所在的整个进程组。

这也就是为什么子进程里要写：

```c
setpgid(0, 0);
```

它的作用是把新 job 放到自己的进程组里，避免 shell 和子进程待在同一个组里被一起干掉。

## `status` 那套宏终于不再像黑魔法

`waitpid` 给回来的 `status` 不是“一个简单数字”，而是编码后的状态字，所以不能直接打印。

必须配套用这些宏：

- `WIFEXITED(status)`：是不是正常退出
- `WIFSIGNALED(status)`：是不是被信号终止
- `WIFSTOPPED(status)`：是不是被信号暂停

然后对应地再取细节：

- `WEXITSTATUS(status)`：正常退出的退出码
- `WTERMSIG(status)`：终止它的信号编号
- `WSTOPSIG(status)`：暂停它的信号编号

这套名字今天终于看出规律了：

- `WIF...` 是判断“属于哪一类状态”
- `...SIG` / `...STATUS` 是在某一类状态下进一步取细节

所以：

- `WIFSIGNALED` 要配 `WTERMSIG`
- `WIFSTOPPED` 要配 `WSTOPSIG`

不能混用。

## 各个 trace 里我真正学到的东西

### `trace03`

第一次真正跑通普通前台命令。重点不是 `/bin/ls` 能不能输出，而是 shell 能不能等它结束，再打印新的提示符。

### `trace04`

明白了后台任务和前台任务的关键差异不在于“启动方式完全不同”，而在于父进程后续行为不同：

- 前台 job 要 `waitfg(pid)`
- 后台 job 不等，直接打印 `[jid] (pid) cmdline`

### `trace05`

`jobs` 其实相对简单，关键是别把它神秘化。它本质上只是把当前 `jobs[]` 里的内容打印出来。

### `trace06`

明确了 `SIGINT` 就是 `Ctrl+C`，shell 不应该被自己干掉，而应该把信号转发给前台进程组。

### `trace08`

理清楚了 `SIGTSTP`、`SIGCHLD` 和 `WUNTRACED` 的关系。此前最困惑的问题是：子进程又没退出，为什么 shell 还能收到 `SIGCHLD`？

答案是：`SIGCHLD` 表示的是“子进程状态变化”，不只是“子进程死亡”。被 `Ctrl+Z` 暂停同样属于状态变化。

## 目前还没做完、但方向已经清楚的部分

现在最明显的未完成部分是 `bg` / `fg`。

这部分还没真正展开实现，但今天至少先把概念分开了：

- `bg` 不是“新开一个后台任务”
- `fg` 也不只是“唤醒后台任务”

更准确地说：

- `bg`：把一个 `Stopped` 的 job 放到后台继续运行
- `fg`：把一个 `Stopped` 或 `BG` 的 job 切回前台

也就是说，后半程的重点会转移到：

- 参数解析：用户给的是 `%jid` 还是 `pid`
- `do_bgfg` 的 job 查找
- `SIGCONT` 的发送
- `BG / FG / ST` 三种状态之间的切换

## 今天最大的变化

今天最有价值的不是“又多写了几个函数”，而是开始能解释自己的代码为什么这样写。

以前看到 `sigprocmask`、`waitpid(..., WNOHANG | WUNTRACED)`、`kill(-pid, SIGTSTP)` 这种代码时，很容易把它们看成模板。现在至少已经能用自己的话解释：

- 为什么要 block `SIGCHLD`
- 为什么 `waitfg` 和 `sigchld_handler` 必须配套
- 为什么 `jid` 不能直接拿去 `kill`
- 为什么 `Ctrl+Z` 之后还会触发 `SIGCHLD`
- 为什么 stop 和 terminate 取信号号时不是同一个宏

这说明目前虽然 lab 还没完成，但模型已经开始搭起来了。

## 下一步

下一次继续写 Shell Lab 时，不应该再回头纠结 `SIGINT` / `SIGTSTP` 这一段，而是直接推进 `do_bgfg`。

最值得优先做的事是：

1. 在 `builtin_cmd` 里正确接 `bg` / `fg`
2. 解析 `%jid` 和 `pid`
3. 找到对应 job
4. 用 `SIGCONT` 恢复它
5. 根据命令把状态切换成 `BG` 或 `FG`
6. 如果是 `fg`，最后进入 `waitfg(pid)`

今天先到这里。虽然还没到能交作业的程度，但至少这次不是糊里糊涂地“抄出一个 shell”，而是开始真的能看懂它为什么会这样工作了。
