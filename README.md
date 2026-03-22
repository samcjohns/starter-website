# starter-website

Powerful and free website stack using WordPress and n8n.

## Purpose

This repository provides a powerful and free website stack that can achieve most
applications that a website may need. Included:

### Wordpress Containers

- `wordpress-mysql` (MySQL 8): persistent relational database for WordPress content, users, media metadata, and plugin/theme state.
- `wordpress` (WordPress): CMS application container that serves your website and connects to the MySQL container over the internal Docker network.
- Data persistence is handled with Docker volumes so content survives container recreation.

### n8n Container

- `n8n`: workflow automation service for integrations, scheduled jobs, and webhook-driven automations.
- Protected with basic auth via environment variables in `app/.env`.
- Persists workflow history and configuration in a dedicated Docker volume.

### Cloudflare Tunnel Container

- `cloudflared`: securely exposes your internal containers to the internet without opening direct inbound ports on the VPS.
- Routes hostnames (defined in `app/cloudflared/config.yml`) to internal services like WordPress, redirect, and n8n.
- Uses Cloudflare tunnel credentials so access is managed through Cloudflare rather than raw server networking.

### nginx Container

- `redirect` (nginx): lightweight redirect service for legacy or alternate hostnames.
- Receives requests from Cloudflare Tunnel and returns clean 301 redirects to your primary domain.
- Keeps redirect rules isolated from WordPress so domain migrations and alias handling stay simple.

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

## VPS bootstrap script

For Ubuntu/Debian droplets or VPS hosts, run:

```bash
chmod +x setup.sh
./setup.sh
```

What it does:

- Runs apt update/upgrade.
- Applies baseline hardening (`ufw`, `fail2ban`, unattended security updates, conservative SSH settings).
- Starts `docker compose` in `app/` with `.env`.
- Prints a message if `app/.env` is missing.

## Before publishing your own fork

- Confirm `app/.env` is not tracked.
- Confirm `app/cloudflared/*.json` files are not tracked.
- Rotate any credentials that were ever committed accidentally.
