--[=[
{"applicationId":"com.smartlight.sunset_breathing","minSdkVersion":1,"version":{"versionCode":1,"versionName":"1.0.0"},"frameDuration":50,"comment":["Warm sunset breathing effect with orange-red gradient"],"sliderInt8":[{"paramKey":"speed","minValue":0,"maxValue":255,"defaultValue":128,"comment":"breathing speed"}],"colorPalette":[{"paramKey":"cpt","defaultCpt":[[0,255,60,0],[128,255,140,0],[255,200,50,0]],"comment":"sunset palette"}]}
--]=]

function onRender(ctx, index)
    local speed = ctx.getNumber("speed")
    local duration = math.floor(1000 + (255 - speed) * 20)
    local breath = WaveForm.Wave(ctx.Time(duration))
    
    local palette = ctx.getCpt("cpt")
    local pos = math.floor(index / ctx.pixelCount * 255)
    local r, g, b = palette.getRGB(pos)
    
    local brightness = 0.3 + breath * 0.7
    return Color.RGB(
        math.floor(r * brightness),
        math.floor(g * brightness),
        math.floor(b * brightness)
    )
end
