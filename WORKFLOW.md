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

When you're done, prefer a focused workflow instead of `git add .`:

```bash
git status --short
git add content/drafts/your-draft.md
git commit -m "blog: add your draft"
git push
```

For published articles, stage only the article and any intentionally related assets:

```bash
git status --short
git add content/posts/your-post.md
git commit -m "blog: update your post"
git push
```

Avoid committing unrelated editor metadata, cache files, or accidental changes.

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
- `push draft` and `publish site` are different steps: pushing syncs source files; publishing rebuilds and deploys the site.
- Avoid editing the same article in two places without syncing first.
