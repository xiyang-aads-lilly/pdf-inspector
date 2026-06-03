#!/usr/bin/env bash
# Build Linux wheels using the maturin Docker image.
# Wheels land in target/wheels/ and can be installed offline with pip.
#
# Preferred: ghcr.io/pyo3/maturin (manylinux, broadest compat)
# Fallback:  docker/Dockerfile.build-wheel (python:3.11-slim, no registry needed)
#
# Usage:
#   ./docker/build-linux-wheels.sh              # current arch, all Python versions
#   ./docker/build-linux-wheels.sh --py 3.11    # current arch, Python 3.11 only
#   ./docker/build-linux-wheels.sh --arch x86_64
#   ./docker/build-linux-wheels.sh --arch aarch64 --py 3.11
#   ./docker/build-linux-wheels.sh --local      # force local Dockerfile fallback

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATURIN_IMAGE="ghcr.io/pyo3/maturin:latest"

TARGET_ARCH=""
PYTHON_VERSION=""
FORCE_LOCAL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --arch)   TARGET_ARCH="$2"; shift 2 ;;
    --py)     PYTHON_VERSION="$2"; shift 2 ;;
    --local)  FORCE_LOCAL=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

PLATFORM_FLAG=""
if [[ -n "$TARGET_ARCH" ]]; then
  case "$TARGET_ARCH" in
    x86_64)  PLATFORM_FLAG="--platform linux/amd64" ;;
    aarch64) PLATFORM_FLAG="--platform linux/arm64" ;;
    *) echo "Unsupported arch: $TARGET_ARCH (use x86_64 or aarch64)"; exit 1 ;;
  esac
fi

# Check if maturin image is reachable (skip if --local forced)
USE_LOCAL=false
if [[ "$FORCE_LOCAL" == true ]]; then
  USE_LOCAL=true
else
  echo "Checking registry access to $MATURIN_IMAGE ..."
  # shellcheck disable=SC2086
  if ! docker pull $PLATFORM_FLAG "$MATURIN_IMAGE" > /dev/null 2>&1; then
    echo "Cannot reach $MATURIN_IMAGE — falling back to local Dockerfile.build-wheel"
    USE_LOCAL=true
  fi
fi

mkdir -p "${REPO_ROOT}/target/wheels"

if [[ "$USE_LOCAL" == true ]]; then
  echo "Building local Docker image from docker/Dockerfile.build-wheel ..."
  # shellcheck disable=SC2086
  docker build $PLATFORM_FLAG \
    -f "${REPO_ROOT}/docker/Dockerfile.build-wheel" \
    -t pdf-inspector-wheel-builder \
    "${REPO_ROOT}"

  # shellcheck disable=SC2086
  docker run --rm $PLATFORM_FLAG \
    -v "${REPO_ROOT}/target/wheels:/io/target/wheels" \
    pdf-inspector-wheel-builder
else
  MATURIN_ARGS="build --release"
  if [[ -n "$PYTHON_VERSION" ]]; then
    MATURIN_ARGS="$MATURIN_ARGS --interpreter python${PYTHON_VERSION}"
  fi

  # shellcheck disable=SC2086
  docker run --rm $PLATFORM_FLAG \
    -v "${REPO_ROOT}:/io" \
    "$MATURIN_IMAGE" $MATURIN_ARGS
fi

echo ""
echo "Wheels written to: target/wheels/"
ls -lh "${REPO_ROOT}/target/wheels/"*.whl
