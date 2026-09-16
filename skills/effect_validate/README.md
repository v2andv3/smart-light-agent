# effect_validate skill

Validates smart-light Lua effect scripts against the remote light-effect
validation API, and returns the rendered preview GIF URL to the user.

This replaces the old local Code-Interpreter-only validation with a real
server-side check + render.

## Files

- `SKILL.md` — the skill instructions the agent follows (matches the plain
  Markdown style of the other skills in this repo).
- `validate_effect.sh` — a standalone helper to POST a script to the API and
  report the result. Handy for manual testing and reproducibility.
- `README.md` — this file.

## The API

- **URL**: `https://d1vsg15w9yes9v.cloudfront.net/api/light-effect/check-and-render`
- **Method**: POST, `Content-Type: application/json`
- **Body**: `{"script": "<lua as JSON string>", "pixelCount": 60, "frameCount": 30}`
  - `pixelCount` default 60, `frameCount` default 30 (both overridable).

### Response — two shapes, parse defensively

- Nested: `data.check.{valid,errors,warnings,output}` + optional
  `data.render.{url,filePath,frameCount,pixelCount,success,message}`
- Flat: `data.{valid,errors,warnings,output}` (no `render`)

Parse rule: `check = data.check if present else data`; read
`valid/errors/warnings/output` from `check`; `gifUrl = data.render.url` if
`data.render` exists else none.

## Helper usage

```bash
chmod +x validate_effect.sh
./validate_effect.sh path/to/effect.lua            # defaults 60 / 30
./validate_effect.sh path/to/effect.lua 60 30      # explicit
API_BASE=http://other-host:8080 ./validate_effect.sh effect.lua   # override base URL
```

Exit codes: `0` valid · `1` invalid · `2` usage/input error · `3` HTTP/network/parse error.

Requires `curl` and either `python3` (preferred) or `jq` to build/parse JSON.

## Behavior summary

- **valid = true** → report 校验通过, list any warnings, and hand the user the
  GIF URL as a plain clickable link (do not download/embed).
- **valid = false** → show errors/warnings, fix the script, re-validate, loop
  until valid or the user stops.
- **HTTP/network error** → report the failure; never claim the script is valid
  when the service was merely unreachable.

## Uploading to GitHub / Harness

Copy the `skills/effect_validate/` folder into your `smart-light-agent` repo
(overwriting the existing `effect_validate` skill), commit, push, then reload
the agent in Harness ("Load an agent from Git"). Optionally update
`commands/validate.md` to mention that `/validate` now uses the remote API and
returns a preview GIF URL.
