# Lua Light Effect API Reference

This document is the complete API reference for writing LED light effect scripts.

## Runtime Environment

- Lua 5.4
- No external libraries (no require/dofile/loadfile)
- No io, os, string.dump
- No math.random, math.randomseed, os.time, os.clock
- Deterministic execution only

## Script Lifecycle

```
onInit(ctx)         -- Called once on first load
onFrame(ctx)        -- Called once per frame (before pixels)
onRender(ctx, index) -- Called for each pixel, MUST return Color
```

### Execution Order Per Frame

1. `onFrame(ctx)` — update frame-level state
2. For each pixel 0..ctx.pixelCount-1:
   - `onRender(ctx, index)` → Color

## Context Object (`ctx`)

### Properties (read-only)

| Property | Type | Description |
|----------|------|-------------|
| `ctx.pixelCount` | integer | Total number of LEDs in the strip |
| `ctx.frameIndex` | integer | Current frame number (0-based, incrementing) |
| `ctx.pts` | integer | Presentation timestamp in milliseconds |
| `ctx.sdkVersion` | integer | SDK version number |

### Methods (DOT notation only!)

```lua
-- ✅ CORRECT
local speed = ctx.getNumber("speed")
local palette = ctx.getCpt("cpt")
local t = ctx.Time(2000)

-- ❌ WRONG (colon notation)
local speed = ctx:getNumber("speed")  -- DO NOT USE
```

| Method | Returns | Description |
|--------|---------|-------------|
| `ctx.getNumber(paramKey)` | integer | Read sliderInt8 parameter value (0-255) |
| `ctx.getCpt(paramKey)` | ColorPaletteTable | Get color palette table |
| `ctx.getColor(paramKey)` | Color | Get single color parameter |
| `ctx.getColorRGB(paramKey)` | r, g, b | Get color as RGB components |
| `ctx.Time(duration_ms)` | float [0..1] | Sawtooth wave with period `duration_ms`. **duration_ms MUST be integer** |

## Color

### Constructors

```lua
Color.RGB(r, g, b)  -- r,g,b: integers [0..255]
Color.HSV(h, s, v)  -- h,s,v: floats [0..1]
```

### Usage in onRender

```lua
function onRender(ctx, index)
    return Color.RGB(255, 128, 0)  -- warm orange
end
```

**onRender MUST always return a Color value. No nil, no number, no string.**

## ColorPaletteTable

Obtained via `ctx.getCpt("paramKey")`.

| Method | Returns | Description |
|--------|---------|-------------|
| `palette.getColor(z)` | Color | Get interpolated color at position z [0..255] |
| `palette.getRGB(z)` | r, g, b | Get interpolated RGB at position z [0..255] |

### Palette Definition in Metadata

```json
"colorPalette": [{
  "paramKey": "cpt",
  "defaultCpt": [[0,255,0,0], [128,0,255,0], [255,0,0,255]],
  "comment": "rainbow"
}]
```

Each entry: `[position(0-255), R, G, B]`

## WaveForm

Utility functions for common wave patterns:

| Function | Input | Output | Description |
|----------|-------|--------|-------------|
| `WaveForm.Wave(v)` | float | float [0..1] | Sine wave |
| `WaveForm.Triangle(v)` | float | float [0..1] | Triangle wave |
| `WaveForm.Sin8(z)` | int [0..255] | int [0..255] | 8-bit sine |
| `WaveForm.Triangle8(z)` | int [0..255] | int [0..255] | 8-bit triangle |

## Metadata Block

### Required Format

```lua
--[=[
{"applicationId":"com.smartlight.effect_name","minSdkVersion":1,"version":{"versionCode":1,"versionName":"1.0.0"},"frameDuration":50,"comment":["Description"]}
--]=]
```

**MUST be compact JSON on a SINGLE LINE between `--[=[` and `--]=]`**

### sliderInt8 Definition

```json
"sliderInt8": [
  {"paramKey":"speed","minValue":0,"maxValue":255,"defaultValue":128,"comment":"animation speed"}
]
```

All five fields are REQUIRED: `paramKey`, `minValue`, `maxValue`, `defaultValue`, `comment`

### frameDuration Guidelines

| Value | Speed | Use Case |
|-------|-------|----------|
| 30 | Very fast | Strobe, rapid chase |
| 50 | Normal | Standard animations |
| 80 | Slow | Breathing, gentle waves |
| 100 | Very slow | Meditation, ambient |

## Pseudo-Randomness

Since `math.random` is NOT available, use deterministic patterns:

```lua
-- Simple hash for pseudo-random per pixel
local hash = (ctx.frameIndex * 7 + index * 13) % 256

-- More varied hash
local hash2 = (ctx.frameIndex * 31 + index * 97 + 17) % 256

-- Combine frame and pixel for animated noise
local noise = (ctx.frameIndex * 3 + index * 7 + ctx.frameIndex * index) % 256
```

## Common Patterns

### Breathing Effect
```lua
function onRender(ctx, index)
    local brightness = WaveForm.Wave(ctx.Time(3000))
    return Color.RGB(
        math.floor(255 * brightness),
        math.floor(128 * brightness),
        math.floor(0)
    )
end
```

### Chase / Running Light
```lua
function onRender(ctx, index)
    local pos = (index / ctx.pixelCount + ctx.Time(2000)) % 1.0
    local brightness = WaveForm.Wave(pos)
    return Color.HSV(pos, 1.0, brightness)
end
```

### Gradient with Palette
```lua
function onRender(ctx, index)
    local z = math.floor(index / ctx.pixelCount * 255)
    local palette = ctx.getCpt("cpt")
    return palette.getColor(z)
end
```
