#!/bin/bash
set -uo pipefail

REPO_DIR="/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
PYTHON_BIN="/usr/bin/python3"

exec "$PYTHON_BIN" "$REPO_DIR/scripts/collect_vercel_analytics.py" "$@"
