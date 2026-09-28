#!/usr/bin/env bash
set -euo pipefail

if command -v node >/dev/null 2>&1; then
    node_bin="$(command -v node)"
else
    node_bin=""
    for candidate in "$HOME"/.local/nodejs/node-v*/bin/node; do
        if [[ -x "$candidate" ]]; then
            node_bin="$candidate"
            break
        fi
    done
fi

[[ -n "$node_bin" ]] || { echo "Node.js is required for the VS Code launcher." >&2; exit 1; }
exec "$node_bin" "$@"
