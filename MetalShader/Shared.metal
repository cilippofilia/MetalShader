//
//  Shared.metal
//  MetalShader
//
//  Created by Filippo Cilia on 17/02/2026.
//

#include <metal_stdlib>
using namespace metal;

struct FullscreenVertexOut {
    float4 position [[position]];
    float2 uv;
};
