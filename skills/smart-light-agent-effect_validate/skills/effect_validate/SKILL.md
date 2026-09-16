# Effect Validate

Validate Lua light effect scripts by submitting them to the remote light-effect
validation API. The API checks the script and, on success, renders a preview GIF
whose URL is returned to the user.

## When to Use

- After generating or modifying any effect (automatic)
- When the user explicitly asks to validate/check a script
- When the user reports a script isn't working
- Invoked via the `/validate` command

## The Validation API

- **URL**: `http://82.157.181.194:8080/api/light-effect/check-and-render`
- **Method**: `POST`
- **Content-Type**: `application/json`
- **Request body**:

```json
{
  "script": "<the full Lua script as a JSON string>",
  "pixelCount": 60,
  "frameCount": 30
}
```

- `script` — the complete Lua script (metadata block + functions), as a JSON
  string. Newlines and quotes MUST be properly JSON-escaped. Do NOT hand-escape;
  build the body programmatically (e.g. `json.dumps` in Python) so escaping is correct.
- `pixelCount` — LED count to simulate. Default **60**. Allow the user to override.
- `frameCount` — number of frames to render. Default **30**. Allow the user to override.

## How to Call It

Use Code Interpreter to POST the script. Preferred (Python):

```python
import json, urllib.request

script = open("effect.lua").read()          # or the in-memory script string
body = json.dumps({"script": script, "pixelCount": 60, "frameCount": 30}).encode()
req = urllib.request.Request(
    "http://82.157.181.194:8080/api/light-effect/check-and-render",
    data=body,
    headers={"Content-Type": "application/json"},
    method="POST",
)
with urllib.request.urlopen(req, timeout=60) as r:
    resp = json.loads(r.read())
print(json.dumps(resp, ensure_ascii=False, indent=2))
```

A ready-made helper script `validate_effect.sh` is included in this skill folder
(uses curl + Python to build the body safely). See README.md.

## Response Shapes (parse defensively)

The API may return either of two shapes. **Always handle both.**

**Shape 1 — nested** (`check` and optional `render`):

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "check":  { "valid": true, "errors": [], "warnings": [], "output": "校验通过" },
    "render": { "success": true, "url": "http://82.157.181.194:8080/gif/effect_XXXX.gif",
                "filePath": "...", "frameCount": 30, "pixelCount": 60, "message": "渲染成功" }
  }
}
```

**Shape 2 — flat** (no `render`):

```json
{
  "code": 0,
  "message": "success",
  "data": { "valid": true, "errors": [], "warnings": [], "output": "校验通过" }
}
```

**Parsing rules:**

```
d       = response["data"]
check   = d["check"] if "check" in d else d
valid   = check.get("valid")
errors  = check.get("errors", [])
warnings= check.get("warnings", [])
output  = check.get("output", "")
render  = d.get("render")                    # may be absent
gifUrl  = render.get("url") if render else None
```

## Behavior

### On success (`valid == true`)

1. Tell the user **校验通过** (validation passed).
2. If there are `warnings`, list them (the script is valid but could be improved).
3. If a `gifUrl` is present, **return that URL to the user as a plain clickable
   link** so they can preview the rendered GIF themselves. Do NOT download or
   embed the GIF — just present the URL, e.g.:

   > ✅ 校验通过。预览: http://82.157.181.194:8080/gif/effect_XXXX.gif

### On failure (`valid == false`)

1. Show the `output` message and list all `errors` (and any `warnings`).
2. **Fix the script** based on the reported errors (see the common-fix table in
   the `effect_generate` skill and `knowledge/common_mistakes.md`).
3. Re-submit the corrected script to the API.
4. Repeat until `valid == true` or the user stops. No hardcoded retry limit —
   use judgment; if the same error persists after a couple of attempts, explain
   the blocker to the user.

### On HTTP / network error

If the request fails (non-200 status, timeout, connection refused, malformed
JSON), **report the failure clearly and do NOT claim the script is valid.**
Tell the user the validation service could not be reached and suggest retrying.
Distinguish "the service said the script is invalid" from "the service was
unreachable" — never conflate the two.

## Common Fixes (when the API reports errors)

| Error signal | Fix |
|--------------|-----|
| `ctx:method()` colon notation | Change to `ctx.method()` dot notation |
| `ctx.getPixelCount()` | Change to `ctx.pixelCount` |
| RGB value > 255 or < 0 | Clamp: `math.max(0, math.min(255, math.floor(v)))` |
| HSV value > 1 or < 0 | Clamp: `math.max(0, math.min(1, v))` |
| `ctx.Time()` with float | Cast to integer: `ctx.Time(math.floor(duration))` |
| `math.random` / `math.randomseed` / `os.*` | Not available — use `ctx.frameIndex + index` hash |
| Missing Color return | Ensure all `onRender` paths return `Color.RGB` / `Color.HSV` |
| Non-ASCII in code | Replace with ASCII equivalents |
| Metadata not valid JSON on one line | Compact the `--[=[ ... --]=]` metadata to a single JSON line |

## Success Criteria

Script passes when the API returns `valid == true`. When a render URL is
included, hand it to the user for preview.
