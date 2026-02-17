//
//  Halo.metal
//  MetalShader
//
//  Created by Filippo Cilia on 17/02/2026.
//

#include "../Shared.metal"

struct HaloFragmentUniforms {
    float time;
    float2 viewSize;
    float cornerRadius;
    float edgeInset;
    float waveInsetPixels;
    float waveAmplitudePixels;
    float waveCount;
    float waveSpeedMultiplier;
    float waveSpeedOffset;
    float coreWidth;
    float glowWidth;
    float mistWidth;
    float haloStrength;
    float pulseBase;
    float pulseAmount;
    float pulseSpeed;
    float colorShiftSpeed;
};

float sdRoundedBox(float2 p, float2 halfSize, float radius) {
    // Signed distance to a rounded rectangle centered at origin.
    float2 q = abs(p) - (halfSize - radius);
    return length(max(q, float2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

float3 siriSpectrum(float t) {
    // Hand-tuned palette approximating Siri's neon gradient cycle.
    float3 c0 = float3(0.18, 0.88, 1.00);
    float3 c1 = float3(0.13, 0.53, 1.00);
    float3 c2 = float3(0.70, 0.33, 1.00);
    float3 c3 = float3(1.00, 0.40, 0.72);
    float3 c4 = float3(1.00, 0.63, 0.36);
    float3 c5 = float3(0.22, 0.92, 0.98);

    float u = fract(t) * 5.0;
    float i = floor(u);
    float f = fract(u);

    if (i < 1.0) return mix(c0, c1, f);
    if (i < 2.0) return mix(c1, c2, f);
    if (i < 3.0) return mix(c2, c3, f);
    if (i < 4.0) return mix(c3, c4, f);
    return mix(c4, c5, f);
}

fragment float4 halo_fragment(
    FullscreenVertexOut in [[stage_in]],
    constant HaloFragmentUniforms &uniforms [[buffer(0)]]
) {
    float aspect = max(uniforms.viewSize.x / max(uniforms.viewSize.y, 1.0), 0.001);
    float2 p = in.uv - 0.5;
    p.x *= aspect;

    // Distance from current pixel to the rounded border path.
    float2 halfSize = float2(0.5 * aspect - uniforms.edgeInset, 0.5 - uniforms.edgeInset);
    float borderDistance = sdRoundedBox(p, halfSize, uniforms.cornerRadius);

    // Position around the ring used for hue and wave motion.
    float ringPhase = atan2(p.y, p.x) * 0.15915494309 + 0.5;
    float angle = atan2(p.y, p.x) * 0.15915494309 + 0.5 + uniforms.time * uniforms.colorShiftSpeed;
    float3 haloColor = siriSpectrum(angle);

    // Three layered gaussian bands create a rich, soft halo.
    float pulse = uniforms.pulseBase + uniforms.pulseAmount * sin(uniforms.time * uniforms.pulseSpeed);
    // True geometric wave: displace the border path itself over time.
    float minDimension = max(min(uniforms.viewSize.x, uniforms.viewSize.y), 1.0);
    float waveInset = uniforms.waveInsetPixels / minDimension;
    float waveAmplitude = uniforms.waveAmplitudePixels / minDimension;
    float wave = sin(ringPhase * 6.28318530718 * uniforms.waveCount - uniforms.time * (uniforms.pulseSpeed * uniforms.waveSpeedMultiplier + uniforms.waveSpeedOffset));
    float wavedDistance = borderDistance + waveInset + wave * waveAmplitude;
    float core = exp(-pow(wavedDistance / max(uniforms.coreWidth, 0.0001), 2.0)) * 0.28;
    float mid = exp(-pow(wavedDistance / max(uniforms.glowWidth, 0.0001), 2.0)) * 0.26 * pulse;
    float mist = exp(-pow(wavedDistance / max(uniforms.mistWidth, 0.0001), 2.0)) * 0.16 * pulse;

    float innerFade = mix(smoothstep(-uniforms.mistWidth, 0.0, borderDistance), 1.0, step(0.0, borderDistance));
    float alpha = (core + mid + mist) * innerFade * uniforms.haloStrength;
    alpha = clamp(alpha, 0.0, 1.0);

    float3 premultiplied = haloColor * alpha;
    return float4(premultiplied, alpha);
}
