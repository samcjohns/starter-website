# starter-website

Powerful and free website stack using WordPress and n8n.

## Privacy-safe template defaults

This repository is set up as a public-safe starter:

- Real credentials are not stored in git.
- Use `app/.env.example` as your starting point.
- `app/.env` is gitignored and should stay local only.
- Cloudflare tunnel credential JSON files are gitignored.

## Quick start

1. Copy `app/.env.example` to `app/.env`.
2. Replace all `change-me` values with strong secrets.
3. Update hostnames/domains from `example.com` to your real domain.
4. Run the stack from `app/`.

```bash
cd app
cp .env.example .env
docker compose up -d
```

## Before publishing your own fork

- Confirm `app/.env` is not tracked.
- Confirm `app/cloudflared/*.json` files are not tracked.
- Rotate any credentials that were ever committed accidentally.
