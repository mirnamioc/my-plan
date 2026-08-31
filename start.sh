#!/bin/bash
set -e

echo "🚀 Starting X-UI + nginx reverse proxy..."

echo "🔧 Tuning system limits..."

ulimit -n 65535 || true

sysctl -w net.core.somaxconn=4096 2>/dev/null || true
sysctl -w net.ipv4.tcp_fin_timeout=30 2>/dev/null || true
sysctl -w net.ipv4.tcp_keepalive_time=120 2>/dev/null || true
sysctl -w net.ipv4.tcp_keepalive_intvl=30 2>/dev/null || true
sysctl -w net.ipv4.tcp_keepalive_probes=5 2>/dev/null || true
sysctl -w net.core.rmem_max=16777216 2>/dev/null || true
sysctl -w net.core.wmem_max=16777216 2>/dev/null || true
sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" 2>/dev/null || true
sysctl -w net.ipv4.tcp_wmem="4096 65536 16777216" 2>/dev/null || true
sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null || true

echo "✅ System tuning applied (some settings may be skipped due to container restrictions)"

export NGINX_PORT=3000

cd /usr/local/x-ui

echo "🔧 Applying panel settings via x-ui CLI..."
./x-ui setting -port 2053 -webBasePath /managepanel/ || true

echo "🔧 Building nginx.conf for fixed port: $NGINX_PORT"
envsubst '${NGINX_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

echo "▶️ Starting x-ui in background..."
./x-ui &
X_UI_PID=$!
sleep 3

echo "▶️ Starting nginx in foreground on port $NGINX_PORT..."
nginx -t
exec nginx -g "daemon off;"
