#!/usr/bin/env bash
set -Eeuo pipefail

WORKDIR=${WORKDIR:-/workspace}
LOG_DIR="${WORKDIR}/logs"
mkdir -p "$LOG_DIR"

# Ensure Genie workspace initialized
if [ ! -f "${WORKDIR}/.genie/state/version.json" ]; then
  echo ">> initializing Genie workspace in ${WORKDIR}"
  (cd "$WORKDIR" && npx --yes automagik-genie init --yes) >/dev/null
fi

FORGE_PORT=${FORGE_PORT:-8887}
FORGE_HOST=${FORGE_HOST:-0.0.0.0}
FORGE_LOG="${LOG_DIR}/forge.log"

MCP_PORT=${MCP_PORT:-9998}
MCP_HOST=${MCP_HOST:-0.0.0.0}

cleanup() {
  if [[ -n "${FORGE_PID:-}" ]]; then
    echo ">> stopping automagik-forge (pid ${FORGE_PID})"
    kill "${FORGE_PID}" 2>/dev/null || true
    wait "${FORGE_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

echo ">> starting automagik-forge on ${FORGE_HOST}:${FORGE_PORT}"
PORT="${FORGE_PORT}" \
FORGE_PORT="${FORGE_PORT}" \
BACKEND_PORT="${FORGE_PORT}" \
HOST="${FORGE_HOST}" \
npx --yes automagik-forge >"${FORGE_LOG}" 2>&1 &
FORGE_PID=$!

for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:${FORGE_PORT}/health" >/dev/null 2>&1; then
    echo ">> forge ready"
    break
  fi

  if ! kill -0 "${FORGE_PID}" 2>/dev/null; then
    echo ">> forge process exited early; last log lines:"
    tail -n 40 "${FORGE_LOG}" || true
    exit 1
  fi

  sleep 1
done

if ! curl -fsS "http://127.0.0.1:${FORGE_PORT}/health" >/dev/null 2>&1; then
  echo ">> forge failed to become healthy within timeout; last log lines:"
  tail -n 40 "${FORGE_LOG}" || true
  exit 1
fi

echo ">> launching MCP proxy on ${MCP_HOST}:${MCP_PORT}"
exec npx --yes mcp-proxy npx automagik-genie mcp --host "${MCP_HOST}" --port "${MCP_PORT}"
