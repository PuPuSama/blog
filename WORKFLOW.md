# Blog Workflow

## Directory rules

- `content/posts/` — published or publish-ready articles
- `content/drafts/` — AI-generated drafts and unfinished ideas
- `themes/` — Hugo theme source
- `hugo.toml` — site configuration

## Recommended local workflow

If you are not sure whether the remote repo changed, run:

```bash
git pull --ff-only
```

Then edit your markdown files in Obsidian or any editor.

When you're done:

```bash
git add .
git commit -m "your message"
git push
```

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
- Avoid editing the same article in two places without syncing first.
