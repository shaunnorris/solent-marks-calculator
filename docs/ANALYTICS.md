# Analytics Setup Guide

All analytics for the Solent stack now flows through a **shared Umami instance** that lives outside this repository. Each application loads the tracking script directly from that centralized service and only needs two environment variables:

| Variable | Description |
| --- | --- |
| `UMAMI_SCRIPT_URL` | Full URL to the shared Umami JavaScript (for example `https://analytics.xonedesign.com/script.js`). Leave unset to disable tracking. |
| `UMAMI_WEBSITE_ID` | UUID for this application's property within Umami. |

Both values are issued by ops. Keep them in your `.env` and avoid committing them to git.

## Configure the Marks App

```bash
cd /srv/deploy/solent-marks-calculator
cat <<'EOF' > .env
WEB_HOST_PORT=127.0.0.1:8000
UMAMI_SCRIPT_URL=https://analytics.xonedesign.com/script.js
UMAMI_WEBSITE_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
EOF
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

The template only injects the `<script>` tag when both values are present, so leaving either blank disables analytics.

## Accessing the Dashboard

- **URL**: provided by ops (for example `https://analytics.xonedesign.com/login`)
- **Accounts**: personal logins are managed centrally; request access if you need to view metrics.
- **Websites**: each app gets its own Website ID. If you add a new site, create the property in the shared Umami instance and update the `.env`.

## Custom Events

The frontend can continue to push custom events if needed:

```javascript
umami.track('calculate-bearing', { zone: '2' });
```

Just ensure the global `umami` object exists before calling it (wrap calls in a guard).

## Other Apps

When new services join the stack:

1. Request a Website ID + script URL from ops.
2. Set `UMAMI_SCRIPT_URL` / `UMAMI_WEBSITE_ID` in that app's `.env`.
3. Insert the same conditional script snippet as in `templates/lookup.html`.

No additional containers or databases are required per app.

- **Umami Docs**: https://umami.is/docs
- **GitHub**: https://github.com/umami-software/umami
- **Issues**: Report via GitHub issues

## Security Notes

- Ops maintains the shared Umami instance (patching, backups, user management).
- Request access instead of creating ad-hoc accounts.
- Treat `UMAMI_SCRIPT_URL` as trusted infrastructure—only point at approved domains.
