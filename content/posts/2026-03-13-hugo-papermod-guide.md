---
title: "Hugo + PaperMod 写作指南：Front Matter 模板、Draft 草稿与发布流程"
date: 2026-03-13T00:00:00Z
lastmod: 2026-03-13T00:00:00Z
draft: false
categories: ["Blog"]
tags: ["Hugo", "PaperMod", "写作", "工作流"]
# cover:
#   image: ""
#   alt: ""
#   caption: ""
#   relative: false
#   hidden: false
---

这篇文章是给未来的自己（以及偶尔帮我写稿的 AI）准备的：**博客怎么写、文件放哪里、Front Matter（文章头部元数据）怎么填、草稿（draft）怎么控制，以及本仓库常用的本地预览/发布流程**。

> 本站技术栈：Hugo + PaperMod。

---

## 1. 写在哪：posts vs drafts

本仓库约定：

- **正式文章**放在：`content/posts/`
- **草稿**放在：`content/drafts/`

两者都是 Hugo 的内容目录（content section）。区别主要靠 Front Matter 里的 `draft` 字段控制。

### 为什么不要让 drafts 出现在首页？

Hugo 的“是否渲染/是否输出”主要取决于：

- 文章是否 `draft: true`
- 构建命令是否带 `-D`（或 buildDrafts=true）

**推荐默认策略：**

- 草稿写在 `content/drafts/`，并设置 `draft: true`
- 本地预览草稿时用 `hugo server -D`
- 线上发布时不带 `-D`（这样草稿不会进入 public，也不会上首页）

---

## 2. Front Matter 模板（直接复制用）

### 2.1 正式文章模板（posts）

新文章建议按下面填：

```yaml
---
title: "这里写标题"
date: 2026-03-13T00:00:00Z
lastmod: 2026-03-13T00:00:00Z
draft: false
categories: ["Blog"]
tags: ["Hugo", "PaperMod"]
---

正文从这里开始。
```

字段解释：

- `title`：文章标题
- `date`：首次发布时间（影响排序）
- `lastmod`：最后修改时间（可选，但建议写，便于主题显示“更新时间”）
- `draft`：是否草稿。`false` 才会进入正式构建/发布
- `categories`/`tags`：分类与标签（PaperMod 支持；是否展示取决于站点配置）

### 2.2 草稿模板（drafts）

```yaml
---
title: "这里写草稿标题"
date: 2026-03-13T00:00:00Z
lastmod: 2026-03-13T00:00:00Z
draft: true
categories: ["Draft"]
tags: []
---

先把想法写下来。
```

**关键点：`draft: true`**。

---

## 3. 本地预览（强烈建议）

在仓库根目录（`blog/`）运行：

- 只看正式文章：
  ```bash
  hugo server
  ```

- 连草稿一起看（包含 `draft: true` 的页面）：
  ```bash
  hugo server -D
  ```

如果你发现“草稿出现在首页”，先检查两件事：

1) 草稿文件是否真的写了 `draft: true`
2) 你是否在用 `-D` 启动/构建

---

## 4. 发布流程（本仓库约定）

一般写作流程：

1. 在 `content/drafts/` 写草稿（`draft: true`）
2. 写完后移动到 `content/posts/`，并把 `draft` 改为 `false`
3. `git add` → `git commit` → `git push`
4. 触发部署/发布脚本

如果你用的是本仓库的发布脚本（在 OpenClaw 机器上）：

```bash
/root/.openclaw/workspace/publish-blog.sh
```

它会大致做这些事：拉取最新代码 → Hugo 构建 → 同步到 Web 目录 → 修权限。

---

## 5. 常见坑（以及怎么避免）

### 坑 1：草稿目录被当成普通文章列出来

只要满足以下两点，草稿就不会被正式构建发布：

- 草稿写 `draft: true`
- 发布构建不带 `-D`

### 坑 2：文件在 drafts 里，但忘了写 `draft: true`

这种情况下 Hugo 会把它当正常文章（因为目录名本身不代表草稿）。

建议：**把草稿模板固定下来**，每次创建草稿都从模板复制。

### 坑 3：想“永远不构建 drafts”

可以在 `hugo.toml` 里用 `ignoreFiles` 之类的方式强行忽略某目录，但这会带来维护成本（例如你未来想临时预览 drafts 也会更麻烦）。

我更推荐用 `draft: true` + `hugo server -D` 这套 Hugo 原生机制。

---

## 6. 给 AI 的写作约束（可选）

如果你让 AI 帮你起草文章，可以直接贴这段要求：

- 输出为一篇 Hugo Markdown（含 Front Matter）
- 保持段落短、标题清晰
- 给出可复制的模板块（YAML front matter）
- 草稿默认 `draft: true`，正式发布 `draft: false`

---

写作愉快。下一篇就从一个小问题开始：记录它、写清楚它、发布它。
