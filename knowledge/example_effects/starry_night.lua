--[=[
{"applicationId":"com.smartlight.starry_night","minSdkVersion":1,"version":{"versionCode":1,"versionName":"1.0.0"},"frameDuration":50,"comment":["Starry night twinkle effect with blue-white stars"],"sliderInt8":[{"paramKey":"density","minValue":0,"maxValue":255,"defaultValue":100,"comment":"star density"},{"paramKey":"speed","minValue":0,"maxValue":255,"defaultValue":150,"comment":"twinkle speed"}]}
--]=]

function onRender(ctx, index)
    local density = ctx.getNumber("density")
    local speed = ctx.getNumber("speed")
    
    -- Deterministic "random" per pixel
    local hash = (index * 31 + 17) % 256
    local isActive = hash < density
    
    if not isActive then
        -- Dark background (deep blue)
        return Color.RGB(0, 0, 20)
    end
    
    -- Twinkle animation per star
    local duration = math.floor(800 + (255 - speed) * 10)
    local phase = (hash * 7) % 256 / 256.0
    local twinkle = WaveForm.Wave(ctx.Time(duration) + phase)
    
    -- Mix between blue and white based on twinkle
    local r = math.floor(100 + twinkle * 155)
    local g = math.floor(100 + twinkle * 155)
    local b = math.floor(180 + twinkle * 75)
    
    return Color.RGB(r, g, b)
end
