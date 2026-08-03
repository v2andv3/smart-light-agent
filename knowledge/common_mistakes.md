# Common Mistakes and Fixes

This document lists frequently seen errors in generated Lua light effect scripts and their fixes.

## 1. Colon Notation (Most Common)

**Wrong:**
```lua
local speed = ctx:getNumber("speed")
local palette = ctx:getCpt("cpt")
```

**Correct:**
```lua
local speed = ctx.getNumber("speed")
local palette = ctx.getCpt("cpt")
```

**Rule:** Always use DOT notation for ctx methods.

---

## 2. Using math.random / math.randomseed

**Wrong:**
```lua
math.randomseed(os.time())
local r = math.random(0, 255)
```

**Correct:**
```lua
-- Deterministic pseudo-random
local r = (ctx.frameIndex * 7 + index * 13) % 256
```

**Rule:** math.random and math.randomseed are NOT available. Use deterministic hash.

---

## 3. Hardcoded Pixel Count

**Wrong:**
```lua
local pos = index / 100  -- assumes 100 pixels
```

**Correct:**
```lua
local pos = index / ctx.pixelCount
```

**Rule:** Never hardcode pixel count.

---

## 4. RGB Values Out of Range

**Wrong:**
```lua
return Color.RGB(brightness * 300, 128, 0)  -- may exceed 255
```

**Correct:**
```lua
local r = math.max(0, math.min(255, math.floor(brightness * 300)))
return Color.RGB(r, 128, 0)
```

**Rule:** Always clamp RGB to [0, 255] integers.

---

## 5. HSV Values Out of Range

**Wrong:**
```lua
return Color.HSV(hue, 1.2, 0.8)  -- S > 1.0!
```

**Correct:**
```lua
return Color.HSV(hue % 1.0, math.min(1.0, saturation), math.min(1.0, value))
```

**Rule:** H, S, V must all be in [0, 1]. Hue wraps (use % 1.0), S/V must be clamped.

---

## 6. Float RGB Values

**Wrong:**
```lua
return Color.RGB(brightness * 255, 0.5 * 255, 0)  -- floats!
```

**Correct:**
```lua
return Color.RGB(math.floor(brightness * 255), math.floor(0.5 * 255), 0)
```

**Rule:** RGB values MUST be integers. Use math.floor().

---

## 7. ctx.Time() with Float Duration

**Wrong:**
```lua
local t = ctx.Time(2000.5)
```

**Correct:**
```lua
local t = ctx.Time(2000)
```

**Rule:** ctx.Time() duration_ms parameter MUST be an integer.

---

## 8. Missing Return in onRender

**Wrong:**
```lua
function onRender(ctx, index)
    if index < 10 then
        return Color.RGB(255, 0, 0)
    end
    -- missing return for index >= 10!
end
```

**Correct:**
```lua
function onRender(ctx, index)
    if index < 10 then
        return Color.RGB(255, 0, 0)
    else
        return Color.RGB(0, 0, 0)
    end
end
```

**Rule:** ALL code paths must return a Color value.

---

## 9. Non-ASCII Characters in Code

**Wrong:**
```lua
local comment = "日落效果"  -- Chinese characters
```

**Correct:**
```lua
local comment = "sunset effect"  -- ASCII only
```

**Rule:** Only plain ASCII in script. No Chinese, no emoji, no special Unicode.

---

## 10. Metadata Not on Single Line

**Wrong:**
```lua
--[=[
{
  "applicationId": "com.example.test",
  "minSdkVersion": 1,
  ...
}
--]=]
```

**Correct:**
```lua
--[=[
{"applicationId":"com.example.test","minSdkVersion":1,"version":{"versionCode":1,"versionName":"1.0.0"},"frameDuration":50,"comment":["test"]}
--]=]
```

**Rule:** Metadata JSON must be compact, on a SINGLE line.

---

## 11. Wrong sliderInt8 Field Names

**Wrong:**
```json
{"paramKey":"speed","min":0,"max":255,"defaultVal":128,"comment":"speed"}
```

**Correct:**
```json
{"paramKey":"speed","minValue":0,"maxValue":255,"defaultValue":128,"comment":"speed"}
```

**Rule:** Must use exactly: paramKey, minValue, maxValue, defaultValue, comment.

---

## 12. Using getPixelCount() Instead of pixelCount

**Wrong:**
```lua
local count = ctx.getPixelCount()
local count = ctx:getPixelCount()
```

**Correct:**
```lua
local count = ctx.pixelCount
```

**Rule:** pixelCount is a property, not a method.
