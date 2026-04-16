# Security Exceptions

## Semgrep Nginx Findings — Accepted Risk

**Date:** 2026-04-15
**Reviewed by:** raulgonzalezdev
**Status:** Accepted Risk

### Finding: `request-host-used` (HIGH)

**Description:** Semgrep flags `proxy_set_header Host $host` as potentially dangerous because an attacker could inject a malicious Host header.

**Why it's acceptable:**
- `proxy_set_header Host $host` is the standard nginx reverse proxy pattern.
- All traffic passes through **Cloudflare proxy** (`proxied: true`) before reaching nginx, which validates and normalizes Host headers.
- nginx `server_name` directives restrict accepted hostnames to known domains (`*.zentto.net`).
- There is no Host-based routing logic that could lead to SSRF or cache poisoning.

**Affected files:** `nginx/*.conf`

### Finding: `possible-nginx-h2c-smuggling` (HIGH)

**Description:** Semgrep flags `proxy_pass` combined with `Upgrade` / `Connection` headers as potential HTTP/2 cleartext smuggling.

**Why it's acceptable:**
- The `Upgrade` and `Connection` headers are used intentionally for **WebSocket** support (real-time features: notifications, live updates).
- Upstream targets are internal Docker containers on a private bridge network (`172.18.0.0/16`), not reachable from the internet.
- Cloudflare terminates TLS; nginx-to-container traffic is on localhost/Docker network only.
- No h2c (HTTP/2 cleartext) is enabled on upstream services; the upgrade mechanism is exclusively for WebSocket.

**Affected files:** `nginx/*.conf`

### Mitigation via `.semgrepignore`

A `.semgrepignore` file excludes nginx config directories from Semgrep scans to prevent these known-acceptable patterns from generating noise in CI.
