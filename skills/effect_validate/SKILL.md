# Effect Validate

Validate and fix Lua light effect scripts by running them in Code Interpreter.

## When to Use

- After generating or modifying any effect (automatic)
- When user explicitly asks to validate/check a script
- When user reports a script isn't working

## Validation Steps

### Step 1: Syntax Check

Verify the script has:
- [ ] Metadata block `--[=[` ... `--]=]` present
- [ ] Metadata is valid JSON on a single line
- [ ] Required metadata fields: applicationId, minSdkVersion, version, frameDuration, comment
- [ ] `onRender(ctx, index)` function defined
- [ ] Returns a Color value (Color.RGB or Color.HSV)

### Step 2: Runtime Execution

Run the script with the test harness (100 pixels, 10 frames):

```lua
-- Color mock
Color = {
    RGB = function(r, g, b)
        r = math.floor(r); g = math.floor(g); b = math.floor(b)
        assert(r >= 0 and r <= 255, "R out of range: " .. tostring(r))
        assert(g >= 0 and g <= 255, "G out of range: " .. tostring(g))
        assert(b >= 0 and b <= 255, "B out of range: " .. tostring(b))
        return {r=r, g=g, b=b, type="rgb"}
    end,
    HSV = function(h, s, v)
        assert(h >= 0 and h <= 1, "H out of range: " .. tostring(h))
        assert(s >= 0 and s <= 1, "S out of range: " .. tostring(s))
        assert(v >= 0 and v <= 1, "V out of range: " .. tostring(v))
        return {h=h, s=s, v=v, type="hsv"}
    end
}

-- WaveForm mock
WaveForm = {
    Wave = function(v) return (math.sin(v * 2 * math.pi) + 1) / 2 end,
    Triangle = function(v) v = v % 1; return v < 0.5 and v * 2 or (1 - v) * 2 end,
    Sin8 = function(z) return math.floor((math.sin(z / 255 * 2 * math.pi) + 1) / 2 * 255) end,
    Triangle8 = function(z) z = z % 256; return z < 128 and z * 2 or (255 - z) * 2 end
}
```

### Step 3: Output Analysis

Check that:
- No nil returns from onRender
- RGB values are integers 0-255
- HSV values are floats 0-1
- No runtime errors across all frames and pixels
- No infinite loops (timeout after 5 seconds)

### Step 4: Common Fixes

| Error | Fix |
|-------|-----|
| `attempt to call nil value 'randomseed'` | Remove math.randomseed, use deterministic hash |
| `ctx:method()` colon notation | Change to `ctx.method()` dot notation |
| `ctx.getPixelCount()` | Change to `ctx.pixelCount` |
| RGB value > 255 or < 0 | Add `math.max(0, math.min(255, math.floor(v)))` |
| HSV value > 1 or < 0 | Add `math.max(0, math.min(1, v))` |
| `ctx.Time()` with float | Cast to integer: `ctx.Time(math.floor(duration))` |
| Non-ASCII characters | Replace with ASCII equivalents |
| Missing Color return | Ensure all code paths in onRender return Color.RGB/HSV |

### Step 5: Fix and Retry

If validation fails:
1. Identify the error from the runtime output
2. Apply the appropriate fix
3. Re-run the test harness
4. Repeat until passing (no hardcoded retry limit — use judgment)

## Success Criteria

Script passes when:
- ✅ 10 frames × 100 pixels all produce valid Color output
- ✅ No runtime errors
- ✅ No assertion failures (RGB in 0-255, HSV in 0-1)
- ✅ Executes within 5 second timeout
