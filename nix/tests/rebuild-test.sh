#!/usr/bin/env bash
set -eu

root=$(cd "$(dirname "$0")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/home/.dotfiles/stow" "$tmp/bin"

cat > "$tmp/bin/sudo" <<'EOF'
#!/usr/bin/env bash
echo rebuild >> "$LOG"
exit "${REBUILD_EXIT:-0}"
EOF
cat > "$tmp/home/.dotfiles/stow/install.sh" <<'EOF'
#!/usr/bin/env bash
echo "stow:$PWD" >> "$LOG"
exit "${STOW_EXIT:-0}"
EOF
chmod +x "$tmp/bin/sudo"
export HOME="$tmp/home" PATH="$tmp/bin:$PATH" LOG="$tmp/log" SKIP_COMMIT=1

cd "$tmp"
bash "$root/nix/rebuild.sh" >/dev/null
test "$(head -n 1 "$LOG")" = rebuild
test "$(tail -n 1 "$LOG")" = "stow:$HOME/.dotfiles"

: > "$LOG"
if REBUILD_EXIT=1 bash "$root/nix/rebuild.sh" >/dev/null; then
  echo 'Expected rebuild failure' >&2; exit 1
fi
test "$(wc -l < "$LOG")" -eq 1

: > "$LOG"
if STOW_EXIT=1 bash "$root/nix/rebuild.sh" >/dev/null; then
  echo 'Expected Stow failure' >&2; exit 1
fi
test "$(wc -l < "$LOG")" -eq 2

echo 'rebuild tests passed'
