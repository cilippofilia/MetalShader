//
//  Curtains.metal
//  MetalShader
//
//  Created by Filippo Cilia on 17/02/2026.
//

#include "../Shared.metal"

struct CurtainsPaletteUniforms {
    float4 topColor;
    float4 bottomColor;
    float4 glowColor;
    float padding;
};

struct CurtainsEffectUniforms {
    float waveAmplitude;
    float waveFrequency;
    float waveSpeed;
    float touchGlowRadius;
    float touchGlowIntensity;
    float softGlowEnabled;
    float2 padding;
};

fragment float4 curtains_fragment(
    FullscreenVertexOut in [[stage_in]],
    constant float &time [[buffer(0)]],
    constant float2 &touch [[buffer(1)]],
    constant CurtainsPaletteUniforms &palette [[buffer(2)]],
    constant CurtainsEffectUniforms &effects [[buffer(3)]]
) {
    // Distort gradient with a horizontal sine wave.
    float wave = effects.waveAmplitude * sin((in.uv.x + time * effects.waveSpeed) * effects.waveFrequency);
    float t = clamp(in.uv.y + wave, 0.0, 1.0);
    float3 color = mix(palette.bottomColor.rgb, palette.topColor.rgb, t);

    // Radial glow that follows the latest touch point.
    float dist = distance(in.uv, touch);
    float glow = smoothstep(effects.touchGlowRadius, 0.0, dist) * effects.touchGlowIntensity * effects.softGlowEnabled;
    color += palette.glowColor.rgb * glow;
    return float4(color, 1.0);
}
