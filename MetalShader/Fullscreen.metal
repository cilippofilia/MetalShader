//
//  Fullscreen.metal
//  MetalShader
//
//  Created by Filippo Cilia on 17/02/2026.
//

#include "Shared.metal"

vertex FullscreenVertexOut fullscreen_vertex(uint vertexID [[vertex_id]]) {
    // Full-screen triangle (faster than a quad, no diagonal seam).
    float2 positions[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };

    FullscreenVertexOut out;
    out.position = float4(positions[vertexID], 0.0, 1.0);
    out.uv = positions[vertexID] * 0.5 + 0.5;
    return out;
}
