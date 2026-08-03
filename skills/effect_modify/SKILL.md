# Effect Modify

Modify an existing light effect script based on user instructions.

## When to Use

User wants to MODIFY the current effect. Signals:
- "brighter", "dimmer", "faster", "slower"
- "more X", "less X"
- "change color to X"
- "add more twinkle", "make it smoother"
- Any relative adjustment word referencing the current effect

## Workflow

1. Retrieve the user's current/last effect script from conversation context
2. Understand the modification intent
3. Apply the change to the COMPLETE script (output full script, not a diff)
4. Validate by running in Code Interpreter
5. Return the complete modified script

## Modification Patterns

### Color Changes
- "change to red" → modify Color.RGB values or palette defaultCpt
- "warmer" → shift hue toward orange/yellow
- "cooler" → shift hue toward blue/cyan
- "more saturated" → increase S in HSV
- "pastel" → decrease S, increase V

### Speed Changes
- "faster" → decrease frameDuration (min 30) or increase time multiplier
- "slower" → increase frameDuration (max 100) or decrease time multiplier
- Alternatively adjust ctx.Time() duration parameter

### Brightness Changes
- "brighter" → multiply RGB values toward 255 (cap at 255)
- "dimmer" → multiply RGB values toward 0
- Alternatively adjust V channel if using HSV

### Animation Changes
- "add breathing" → apply sine wave to brightness
- "add chase" → add position-based offset to time
- "smoother" → reduce step sizes, add interpolation
- "more variation" → add noise/randomness via deterministic hash

## Rules

- Always output the COMPLETE modified script (including metadata block)
- Keep the same script structure and style as the original
- Update the `comment` field in metadata to reflect the change
- Preserve user parameters (sliderInt8, colorPalette) unless the change requires removing them
- If modification conflicts with existing logic, prefer the user's new instruction
- Validate after modification — the script must still pass the test harness
