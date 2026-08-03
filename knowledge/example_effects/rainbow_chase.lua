--[=[
{"applicationId":"com.smartlight.rainbow_chase","minSdkVersion":1,"version":{"versionCode":1,"versionName":"1.0.0"},"frameDuration":30,"comment":["Rainbow chase effect - colors move along the strip"],"sliderInt8":[{"paramKey":"speed","minValue":0,"maxValue":255,"defaultValue":180,"comment":"chase speed"},{"paramKey":"width","minValue":0,"maxValue":255,"defaultValue":128,"comment":"color segment width"}]}
--]=]

function onRender(ctx, index)
    local speed = ctx.getNumber("speed")
    local width = ctx.getNumber("width")
    
    local duration = math.floor(500 + (255 - speed) * 15)
    local segments = 1 + math.floor(width / 32)
    
    local pos = (index / ctx.pixelCount * segments + ctx.Time(duration)) % 1.0
    local hue = pos
    local brightness = WaveForm.Wave(pos)
    
    return Color.HSV(hue, 1.0, 0.3 + brightness * 0.7)
end
