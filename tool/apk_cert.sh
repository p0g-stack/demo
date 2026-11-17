#!/usr/bin/env bash
# The signing certificate SHA-256 of the app-plane APK inside a WebUI module
# zip (webui_app_plane/app.apk), from apksigner: the APK must verify and carry
# exactly one signer certificate. Usage: tool/apk_cert.sh MODULE.zip
# APKSIGNER overrides the apksigner on PATH.
set -euo pipefail
zip=${1:?usage: apk_cert.sh MODULE.zip}
apksigner=${APKSIGNER:-apksigner}
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
unzip -q -d "$tmp" "$zip" webui_app_plane/app.apk
"$apksigner" verify --print-certs "$tmp/webui_app_plane/app.apk" > "$tmp/certs"
mapfile -t certs < <(sed -n 's/.*certificate SHA-256 digest: \([0-9a-f]\{64\}\)$/\1/p' "$tmp/certs" | sort -u)
if [ "${#certs[@]}" -ne 1 ]; then
  echo "apk_cert: expected one signer certificate in $zip, found ${#certs[@]}:" >&2
  cat "$tmp/certs" >&2
  exit 1
fi
echo "${certs[0]}"
