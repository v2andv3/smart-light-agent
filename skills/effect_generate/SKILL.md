# Effect Generate

Generate complete Lua light effect scripts from natural language descriptions.

## When to Use

User wants to create a NEW light effect. Signals:
- Describes a visual effect ("sunset gradient", "blue starry sky", "rainbow chase")
- Asks for an effect without referencing an existing one
- Short descriptions of effects even without "I want" prefix

## Script Structure

Output a complete Lua script with:

### 1. Metadata Block (REQUIRED)

```lua
--[=[
{"applicationId":"com.example.effect_name","minSdkVersion":1,"version":{"versionCode":1,"versionName":"1.0.0"},"frameDuration":50,"comment":["Effect description"],"colorPalette":[{"paramKey":"cpt","defaultCpt":[[0,255,0,0],[128,0,255,0],[255,0,0,255]],"comment":"palette"}]}
--]=]
```

Required metadata fields:
- `applicationId` — unique identifier (com.smartlight.xxx)
- `minSdkVersion` — always 1
- `version` — object: `{"versionCode":1,"versionName":"1.0.0"}`
- `frameDuration` — milliseconds per frame (30-100)
- `comment` — array with effect description

Optional metadata fields:
- `sliderInt8` — array of slider controls
- `colorPalette` — array of palette definitions
- `color` — array of color parameters

### 2. sliderInt8 Format (strict, all fields required)

```json
{"paramKey":"speed","minValue":0,"maxValue":255,"defaultValue":128,"comment":"speed control"}
```

MUST use exactly: `paramKey`, `minValue`, `maxValue`, `defaultValue`, `comment`
NEVER use: `min`, `max`, `defaultVal`, `maxVal` (these are WRONG field names)

### 3. colorPalette Format

```json
{"paramKey":"cpt","defaultCpt":[[0,255,0,0],[128,0,255,0],[255,0,0,255]],"comment":"palette"}
```

- `defaultCpt`: array of `[position(0-255), R, G, B]`

## Functions to Implement

- `onInit(ctx)` — one-time setup (optional)
- `onFrame(ctx)` — called each frame (optional)
- `onRender(ctx, index)` — called for each pixel, MUST return a Color

## API Reference

### Context Fields
- `ctx.pixelCount` — total LED count (integer)
- `ctx.frameIndex` — current frame number
- `ctx.pts` — presentation timestamp
- `ctx.sdkVersion` — SDK version

### Context Methods (DOT notation, NOT colon!)
- `ctx.getNumber("paramKey")` — read sliderInt8 value
- `ctx.getCpt("paramKey")` — get ColorPaletteTable
- `ctx.getColor("paramKey")` — get color
- `ctx.getColorRGB("paramKey")` — get r,g,b
- `ctx.Time(duration_ms)` — sawtooth [0..1], duration_ms MUST be integer

### Color
- `Color.RGB(r, g, b)` — r,g,b in [0..255]
- `Color.HSV(h, s, v)` — h,s,v in [0..1]

### ColorPaletteTable (from ctx.getCpt)
- `palette.getColor(z)` — z is integer [0..255], returns color
- `palette.getRGB(z)` — returns r,g,b

### WaveForm
- `WaveForm.Wave(v)` — sine [0..1]
- `WaveForm.Triangle(v)` — triangle [0..1]
- `WaveForm.Sin8(z)` — 8-bit sine, z [0..255]
- `WaveForm.Triangle8(z)` — 8-bit triangle, z [0..255]

## Critical Rules

1. Use `ctx.pixelCount` (NOT `ctx:getPixelCount()` or `ctx.getPixelCount()`)
2. Use DOT notation: `ctx.getCpt("key")`, NOT `ctx:getCpt("key")`
3. Color values MUST be integers 0-255
4. frameDuration: 30-100
5. NEVER hardcode pixel count, always use `ctx.pixelCount`
6. `onRender` MUST return `Color.RGB()` or `Color.HSV()`
7. Use `math.floor()` for float-to-int conversion
8. ONLY plain ASCII characters (no Chinese, no emoji in code)
9. Lua 5.4 syntax
10. Metadata MUST be compact JSON on a SINGLE LINE

## FORBIDDEN (not available in runtime)

- `math.randomseed` — NOT available
- `os.time`, `os.clock` — NOT available
- `math.random` — NOT available, use `ctx.frameIndex + index` for pseudo-randomness
- `require`, `dofile`, `loadfile` — NOT available
- `io`, `os`, `string.dump` — NOT available

For randomness, use deterministic hash:
```lua
(ctx.frameIndex * 7 + index * 13) % 256
```

## Validation

After generating, ALWAYS run the script in Code Interpreter with this test harness:

```lua
-- Test harness (simulate execution)
local pixelCount = 100
local frameCount = 10

-- Mock ctx
local ctx = {
    pixelCount = pixelCount,
    frameIndex = 0,
    pts = 0,
    sdkVersion = 1,
    getNumber = function(key) return 128 end,
    getCpt = function(key)
        return {
            getColor = function(z) return Color.RGB(z, 255-z, 128) end,
            getRGB = function(z) return z, 255-z, 128 end
        }
    end,
    Time = function(duration) return (ctx.frameIndex * 50 % duration) / duration end
}

-- Run frames
for f = 0, frameCount-1 do
    ctx.frameIndex = f
    ctx.pts = f * 50
    if onInit and f == 0 then onInit(ctx) end
    if onFrame then onFrame(ctx) end
    for i = 0, pixelCount-1 do
        local color = onRender(ctx, i)
        assert(color ~= nil, "onRender must return a Color at frame=" .. f .. " index=" .. i)
    end
end
print("VALIDATION PASSED: " .. frameCount .. " frames x " .. pixelCount .. " pixels")
```

If validation fails, fix the error and re-run until it passes.
