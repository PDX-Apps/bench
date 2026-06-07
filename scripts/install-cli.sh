#!/usr/bin/env bash
# install-cli.sh — OPTIONAL: install a global `bench` symlink.
#
# This is a power-user convenience. The recommended way to use Bench is:
#   /path/to/bench/bin/bench build    # once per project (full path)
#   ./bench rebuild | status | addon ...   # from inside the project (shim created by init)
#
# Only run this script if you want `bench build` available from anywhere without
# typing the full path to the bench source repo. No sudo required — symlinks
# into ~/.local/bin (XDG convention).
#
# Usage:
#   ./scripts/install-cli.sh              # install
#   ./scripts/install-cli.sh --uninstall  # remove the symlink
#
# Options:
#   BENCH_INSTALL_DIR=/path  override the install location (default: ~/.local/bin)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCH_ROOT="$(dirname "$SCRIPT_DIR")"
BENCH_BIN="$BENCH_ROOT/bin/bench"

UNINSTALL=false
for arg in "$@"; do
  case "$arg" in
    --uninstall) UNINSTALL=true ;;
    -h|--help)
      grep -E '^#( |$)' "${BASH_SOURCE[0]}" | sed 's/^# //; s/^#//'
      exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

if [[ ! -x "$BENCH_BIN" ]]; then
  echo "ERROR: can't find bench at $BENCH_BIN" >&2
  exit 1
fi

TARGET_DIR="${BENCH_INSTALL_DIR:-$HOME/.local/bin}"
TARGET="$TARGET_DIR/bench"

if $UNINSTALL; then
  if [[ -L "$TARGET" ]]; then
    rm "$TARGET"
    echo "✓ Removed $TARGET"
  elif [[ -e "$TARGET" ]]; then
    echo "ERROR: $TARGET exists but isn't a symlink. Inspect manually." >&2
    exit 1
  else
    echo "Nothing to uninstall (no symlink at $TARGET)."
  fi
  exit 0
fi

mkdir -p "$TARGET_DIR"

if [[ -L "$TARGET" ]]; then
  EXISTING="$(readlink "$TARGET")"
  if [[ "$EXISTING" == "$BENCH_BIN" ]]; then
    echo "✓ Already installed: $TARGET → $BENCH_BIN"
  else
    rm "$TARGET"
    ln -s "$BENCH_BIN" "$TARGET"
    echo "✓ Updated symlink: $TARGET → $BENCH_BIN  (was → $EXISTING)"
  fi
elif [[ -e "$TARGET" ]]; then
  echo "ERROR: $TARGET exists and is not a symlink. Refusing to overwrite." >&2
  exit 1
else
  ln -s "$BENCH_BIN" "$TARGET"
  echo "✓ Installed: $TARGET → $BENCH_BIN"
fi

echo ""
case ":$PATH:" in
  *":$TARGET_DIR:"*)
    echo "✓ $TARGET_DIR is on your PATH."
    echo ""
    echo "Try: bench help"
    ;;
  *)
    echo "⚠️  $TARGET_DIR is NOT on your PATH."
    echo ""
    SHELL_NAME="$(basename "${SHELL:-bash}")"
    case "$SHELL_NAME" in
      zsh|bash)
        RC_FILE="$HOME/.${SHELL_NAME}rc"
        echo "Add to $RC_FILE (then open a new terminal):"
        echo ""
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
      fish)
        echo "Run once: fish_add_path \$HOME/.local/bin"
        ;;
      *)
        echo "Add $TARGET_DIR to your PATH (your shell: $SHELL_NAME)."
        ;;
    esac
    echo ""
    echo "Then: bench help"
    ;;
esac
