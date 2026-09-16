#!/usr/bin/env bash
#
# validate_effect.sh — submit a Lua light-effect script to the validation API
# and report whether it is valid, plus the rendered GIF URL if present.
#
# Usage:
#   ./validate_effect.sh <script.lua> [pixelCount] [frameCount]
#
# Examples:
#   ./validate_effect.sh effect.lua
#   ./validate_effect.sh effect.lua 60 30
#
# Exit codes:
#   0  -> script is valid (API returned valid=true)
#   1  -> script is invalid (API returned valid=false)
#   2  -> usage / input error
#   3  -> HTTP / network / parse error (service unreachable or bad response)
#
# The API base URL is configurable via the API_BASE env var or the constant below.

set -u

API_BASE="${API_BASE:-http://82.157.181.194:8080}"
API_PATH="/api/light-effect/check-and-render"
API_URL="${API_BASE}${API_PATH}"

SCRIPT_FILE="${1:-}"
PIXEL_COUNT="${2:-60}"
FRAME_COUNT="${3:-30}"

if [ -z "$SCRIPT_FILE" ] || [ ! -f "$SCRIPT_FILE" ]; then
  echo "ERROR: provide a path to an existing .lua script file." >&2
  echo "Usage: $0 <script.lua> [pixelCount] [frameCount]" >&2
  exit 2
fi

# --- Build the JSON request body safely (prefer python3, fall back to jq) ---
BODY_FILE="$(mktemp)"
trap 'rm -f "$BODY_FILE" "$RESP_FILE" 2>/dev/null' EXIT

if command -v python3 >/dev/null 2>&1; then
  python3 - "$SCRIPT_FILE" "$PIXEL_COUNT" "$FRAME_COUNT" > "$BODY_FILE" <<'PY'
import json, sys
script = open(sys.argv[1], encoding="utf-8").read()
pixel = int(sys.argv[2]); frame = int(sys.argv[3])
print(json.dumps({"script": script, "pixelCount": pixel, "frameCount": frame}))
PY
elif command -v jq >/dev/null 2>&1; then
  jq -Rs --argjson p "$PIXEL_COUNT" --argjson f "$FRAME_COUNT" \
     '{script: ., pixelCount: $p, frameCount: $f}' "$SCRIPT_FILE" > "$BODY_FILE"
else
  echo "ERROR: need python3 or jq to build the JSON body safely." >&2
  exit 2
fi

echo "== Request body (first 300 chars) =="
head -c 300 "$BODY_FILE"; echo; echo

# --- POST to the API ---
RESP_FILE="$(mktemp)"
HTTP_STATUS="$(curl -s -o "$RESP_FILE" -w "%{http_code}" \
  --max-time 60 \
  -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  --data @"$BODY_FILE" 2>/dev/null)"
CURL_RC=$?

if [ $CURL_RC -ne 0 ]; then
  echo "ERROR: request to $API_URL failed (curl rc=$CURL_RC). Service unreachable?" >&2
  exit 3
fi

echo "== HTTP status: $HTTP_STATUS =="
echo "== Full response =="
cat "$RESP_FILE"; echo; echo

if [ "$HTTP_STATUS" != "200" ]; then
  echo "ERROR: non-200 HTTP status ($HTTP_STATUS). Not treating script as valid." >&2
  exit 3
fi

# --- Parse the response defensively (handle nested data.check.* and flat data.*) ---
if ! command -v python3 >/dev/null 2>&1; then
  echo "NOTE: python3 not available for parsing; see raw response above." >&2
  exit 3
fi

python3 - "$RESP_FILE" <<'PY'
import json, sys
try:
    resp = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception as e:
    print("ERROR: could not parse JSON response:", e); sys.exit(3)

d = resp.get("data", {}) or {}
check = d.get("check", d)                 # nested if present, else flat
valid = check.get("valid")
errors = check.get("errors", []) or []
warnings = check.get("warnings", []) or []
output = check.get("output", "")
render = d.get("render")
gif = render.get("url") if isinstance(render, dict) else None

print("== Parsed ==")
print("valid   :", valid)
print("output  :", output)
print("errors  :", errors)
print("warnings:", warnings)
print("gifUrl  :", gif if gif else "(none)")

if valid is True:
    if gif:
        print("\n✅ 校验通过。预览:", gif)
    else:
        print("\n✅ 校验通过。(未返回渲染 URL)")
    sys.exit(0)
else:
    print("\n❌ 校验失败。请根据 errors 修正脚本后重试。")
    sys.exit(1)
PY
exit $?
