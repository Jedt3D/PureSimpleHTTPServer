# Deployment Guide

PureSimpleHTTPServer supports three deployment modes. Choose based on your
traffic and TLS requirements.

## Mode 1: Standalone (Direct)

The simplest mode — one process, one port, no dependencies.

```bash
# Compile
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb

# Run
./PureSimpleHTTPServer --port 8080 --root /var/www
```

**When to use:** Development, internal tools, low-traffic sites (<2,000 req/sec).

**Capacity:** ~200-500 concurrent connections, ~2,000-5,000 req/sec for small
static files.

## Mode 2: HTTPS (Direct)

Serve HTTPS directly — no reverse proxy needed.

### Manual certificates

Provide your own certificate and key files:

```bash
./PureSimpleHTTPServer --port 443 --root /var/www \
    --tls-cert /etc/ssl/cert.pem --tls-key /etc/ssl/key.pem
```

### Automatic certificates (Let's Encrypt)

Zero-config HTTPS via acme.sh. The server obtains and renews certificates
automatically:

```bash
# Prerequisites: acme.sh installed, port 80 open, DNS configured
./PureSimpleHTTPServer --auto-tls example.com --root /var/www
```

This starts:
- HTTPS on port 443 (main server)
- HTTP on port 80 (ACME challenges + redirect to HTTPS)
- Background renewal thread (checks every 12 hours)

**When to use:** Single-server deployments where you want HTTPS without a
reverse proxy. Good for small-to-medium traffic.

**Capacity:** Same as standalone (~2,000-5,000 req/sec), but with TLS
overhead (~10-20% reduction for small files).

## Mode 3: Reverse Proxy (Recommended for Production)

Run multiple server instances behind Caddy or nginx. The proxy handles TLS,
HTTP/2, gzip, and load balancing.

```
Clients (HTTPS/HTTP2) → Caddy → PureSimple:8080
                               → PureSimple:8081
                               → PureSimple:8082
                               → PureSimple:8083
```

### Quick start

```bash
# 1. Start 4 backend instances
cd deploy
./launch.sh 4 --root /var/www

# 2. Edit Caddyfile: replace example.com with your domain
vim Caddyfile

# 3. Start Caddy
caddy run --config Caddyfile
```

### What the proxy provides

| Feature | Backend | Proxy |
|---------|---------|-------|
| TLS (HTTPS) | Connection: close | Auto Let's Encrypt |
| HTTP/2 | Not supported | Full support |
| Gzip | Dynamic (v2.3.0+) | Proxy can also compress |
| Keep-alive | Not supported | Maintained to clients |
| Slow client buffering | Thread held for duration | Proxy buffers, fast localhost relay |
| Load balancing | Single process | Round-robin across N instances |
| Rate limiting | Not built-in | Caddy/nginx handles it |

### Capacity estimates

| Setup | Concurrent | Requests/sec |
|-------|------------|--------------|
| 1 instance, no proxy | ~200-500 | ~2,000-5,000 |
| 1 instance + Caddy | ~500-1,000 | ~5,000-10,000 |
| 4 instances + Caddy | ~2,000-4,000 | ~15,000-30,000 |
| 8 instances + Caddy | ~4,000-8,000 | ~25,000-50,000 |

Numbers are for small static files on localhost. The proxy's biggest win is
protecting backends from slow clients — a 3G mobile user holding a connection
for 2 seconds blocks a thread for 2 seconds without a proxy; with a proxy,
the thread lives ~2 milliseconds (fast localhost transfer).

### Multi-instance management

**With launch.sh:**

```bash
# Start
./deploy/launch.sh 4 --root /var/www --log /var/log/pshs/access.log

# Stop
./deploy/launch.sh stop
```

**With systemd (Linux):**

```bash
# Install
sudo cp PureSimpleHTTPServer /usr/local/bin/
sudo cp deploy/systemd/puresimple@.service /etc/systemd/system/
sudo useradd -r -s /usr/sbin/nologin puresimple
sudo mkdir -p /var/www /var/log/pshs
sudo chown puresimple:puresimple /var/www /var/log/pshs
sudo systemctl daemon-reload

# Start 4 instances
for port in 8080 8081 8082 8083; do
    sudo systemctl enable --now puresimple@$port
done

# Check status
sudo systemctl status 'puresimple@*'

# View logs
journalctl -u puresimple@8080 -f
```

Each instance gets its own access log, error log, and PID file (port number
in the filename).

## When to Use Which Mode

| Scenario | Recommended Mode |
|----------|-----------------|
| Local development | Standalone |
| Internal tool / intranet | Standalone |
| Small public site (<5k req/sec) | HTTPS (auto-TLS) |
| Medium site (5k-30k req/sec) | Reverse proxy (4 instances) |
| High-traffic site (>30k req/sec) | Reverse proxy (8+ instances) |
| Need HTTP/2 for browsers | Reverse proxy |
| Need rate limiting / WAF | Reverse proxy |

## File Reference

```
deploy/
  Caddyfile                      Example Caddy reverse proxy config
  launch.sh                      Multi-instance start/stop script
  systemd/
    puresimple@.service          Systemd template unit (Linux)
```
