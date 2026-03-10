# Blog Workflow

## Directory rules

- `content/posts/` — published or publish-ready articles
- `content/drafts/` — AI-generated drafts and unfinished ideas
- `themes/` — Hugo theme source
- `hugo.toml` — site configuration

## Recommended local workflow

Before editing, sync first if you are not sure whether the remote repo changed:

```bash
git pull --ff-only
```

Then edit your markdown files in Obsidian or any editor.

When you're done:

```bash
git status --short
git add -A
git commit -m "your message"
git push
```

This repo already ignores editor metadata and build output, so `git add -A` is acceptable here for normal use.
If `git status --short` shows something surprising, stop and check before committing.

## Server publish workflow

On the server, publish with:

```bash
/root/.openclaw/workspace/publish-blog.sh
```

That script does:

1. `git pull --ff-only`
2. Hugo build
3. Sync `public/` to `/var/www/blog.pu0.me`
4. Fix permissions for Caddy

## Collaboration rule

- Final articles are mainly edited locally.
- AI-generated content should go into `content/drafts/` first.
- Move a draft into `content/posts/` only after manual review and cleanup.
- Renaming or moving a draft into `content/posts/` is fine; `git add -A` will correctly record the move/delete pair.
- `push draft` and `publish site` are different steps: pushing syncs source files; publishing rebuilds and deploys the site.
- Avoid editing the same article in two places without syncing first.
