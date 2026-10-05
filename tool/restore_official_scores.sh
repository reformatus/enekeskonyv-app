#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

apk_path="${1:-}"

pull_from_device() {
  local package_path
  package_path="$(adb shell pm path com.github.reformatus.enekeskonyv | sed -n 's/^package://p' | head -n1 | tr -d '\r')"
  if [[ -z "$package_path" ]]; then
    echo "Could not find com.github.reformatus.enekeskonyv on the connected device." >&2
    exit 1
  fi

  apk_path="$work_dir/official.apk"
  adb pull "$package_path" "$apk_path" >/dev/null
}

extract_from_zip() {
  local zip_path="$1"
  unzip -p "$zip_path" '*.apk' > "$work_dir/official.apk"
  apk_path="$work_dir/official.apk"
}

if [[ -z "$apk_path" ]]; then
  pull_from_device
elif [[ "$apk_path" == *.zip ]]; then
  extract_from_zip "$apk_path"
fi

if [[ ! -f "$apk_path" ]]; then
  echo "APK not found: $apk_path" >&2
  exit 1
fi

mkdir -p "$repo_root/assets/ref21" "$repo_root/assets/ref48"
unzip -o "$apk_path" \
  'assets/flutter_assets/assets/ref21/*' \
  'assets/flutter_assets/assets/ref48/*' \
  -d "$work_dir/extracted" >/dev/null

rsync -a --delete \
  "$work_dir/extracted/assets/flutter_assets/assets/ref21/" \
  "$repo_root/assets/ref21/"
rsync -a --delete \
  "$work_dir/extracted/assets/flutter_assets/assets/ref48/" \
  "$repo_root/assets/ref48/"

printf 'tracked placeholder for local score restores\n' > "$repo_root/assets/ref21/.gitkeep"
printf 'tracked placeholder for local score restores\n' > "$repo_root/assets/ref48/.gitkeep"

echo "Restored official ref21/ref48 score assets into $repo_root/assets"
