#!/usr/bin/env bash
set -euo pipefail

# Pick fusermount(3)
if command -v fusermount >/dev/null; then FUSERMOUNT=fusermount
elif command -v fusermount3 >/dev/null; then FUSERMOUNT=fusermount3
else echo "fusermount(3) not found"; exit 1; fi

echo "Scanning for Cryptomator (fuse-nio-adapter) mounts..."
# Match either source ($1) or fstype ($3)
mapfile -t crypt_mounts < <(
  awk '($1=="fuse-nio-adapter" || $3 ~ /^fuse(\.|$).*fuse-nio-adapter$/) \
       { gsub("\\040"," ",$2); print $2 }' /proc/mounts
)

if [[ ${#crypt_mounts[@]} -eq 0 ]]; then
  echo "No fuse-nio-adapter mounts found."
  exit 0
fi

echo "Found mounts:"
for m in "${crypt_mounts[@]}"; do echo "  - $m"; done
echo

# Returns non-empty only if something that looks like Cryptomator is running
running="$(pgrep -a -f -i '(^|[/. -])cryptomator([ /.:-]|$)' 2>/dev/null || true)"

if [[ -n "$running" ]]; then

  echo "⚠ Cryptomator process appears to be running."
  read -rp "Continue anyway? [y/N] " cont
  [[ "$cont" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

read -rp "Unmount all (a), ask per mount (y), or cancel (N)? [y/N/a]: " mode

unmount_one() {
  local m="$1"
  echo "→ Unmounting $m"
  if ! $FUSERMOUNT -u -z "$m" 2>/dev/null; then
    umount -l "$m" 2>/dev/null || echo "  (failed or already gone)"
  fi
}

case "$mode" in
  [aA])
    for m in "${crypt_mounts[@]}"; do unmount_one "$m"; done
    ;;
  [yY])
    for m in "${crypt_mounts[@]}"; do
      read -rp "Unmount $m ? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && unmount_one "$m"
    done
    ;;
  *)
    echo "Aborted."; exit 0 ;;
esac

echo "Done."