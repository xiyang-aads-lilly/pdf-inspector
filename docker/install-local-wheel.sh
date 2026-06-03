#!/usr/bin/env sh
set -eu

WHEEL_DIR="${1:-/opt/wheels}"

if [ ! -d "$WHEEL_DIR" ]; then
  echo "Wheel directory not found: $WHEEL_DIR" >&2
  exit 1
fi

WHEEL_PATH="$(ls -1 "$WHEEL_DIR"/*.whl 2>/dev/null | head -n 1 || true)"

if [ -z "$WHEEL_PATH" ]; then
  echo "No .whl files found in $WHEEL_DIR" >&2
  exit 1
fi

echo "Installing wheel: $WHEEL_PATH"
python -m pip install --no-cache-dir "$WHEEL_PATH"
