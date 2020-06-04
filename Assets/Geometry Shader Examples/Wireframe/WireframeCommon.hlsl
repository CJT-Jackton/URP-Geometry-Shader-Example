#ifndef UNIVERSAL_WIREFRAME_COMMON_INCLUDED
#define UNIVERSAL_WIREFRAME_COMMON_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Macros.hlsl"

float AntiAliasStep(float threshold, float dist) {
  float afwidth = fwidth(dist) * 0.5;
  return smoothstep(threshold - afwidth, threshold + afwidth, dist);
}

half SolidWireframe(half3 baryCoord, half wireframeSize)
{
    half minBary = min(baryCoord.x, min(baryCoord.y, baryCoord.z));
    return 1.0 - AntiAliasStep(wireframeSize, minBary);
}

half StyledWireframeBS(half3 baryCoord, half wireframeSize, half squeezeMin, half squeezeMax, half dashRepeat, half dashLength, half dashOverlap)
{
    half minBary = min(baryCoord.x, min(baryCoord.y, baryCoord.z));

    half positionAlong = max(baryCoord.x, baryCoord.y);
    if (baryCoord.y < baryCoord.x && baryCoord.y < baryCoord.z)
        positionAlong = 1.0 - positionAlong;

#if defined(_WIREFRAMESQUEEZE_ON)
    wireframeSize *= lerp(squeezeMin, squeezeMax, (1.0 - sin(positionAlong * PI)));
#endif
#if defined(_WIREFRAMEDASH_ON)
    half offset = 1.0 / dashRepeat * dashLength / 2.0;
    offset += dashOverlap > 0.0 ? 1.0 / dashRepeat / 2.0 : 0.0;

    half pattern = frac((positionAlong + offset) * dashRepeat);
    wireframeSize *= 1.0 - AntiAliasStep(dashLength, pattern);
#endif

    return 1.0 - AntiAliasStep(wireframeSize, minBary);
}

half StyledWireframeWS(half3 distToEdge, half3 distToVertex, half3 baryCoord, half wireframeSize, half squeezeMin, half squeezeMax, half dashRepeat, half dashLength, half dashOverlap)
{
    half minDistToEdge = min(distToEdge.x, min(distToEdge.y, distToEdge.z));
    half minDistToVertex = min(distToVertex.x, min(distToVertex.y, distToVertex.z));
    half distAlongEdge = sqrt(minDistToVertex * minDistToVertex - minDistToEdge * minDistToEdge);

    half positionAlong = max(baryCoord.x, baryCoord.y);
    if (baryCoord.y < baryCoord.x && baryCoord.y < baryCoord.z)
        positionAlong = 1.0 - positionAlong; 

#if defined(_WIREFRAMESQUEEZE_ON)
    wireframeSize *= lerp(squeezeMin, squeezeMax, (1.0 - sin(positionAlong * PI)));
#endif
#if defined(_WIREFRAMEDASH_ON)
    half offset = dashRepeat * dashLength / 2.0;
    half pattern = frac(distAlongEdge * dashRepeat + offset);
    wireframeSize *= 1.0 - AntiAliasStep(dashLength, pattern);
#endif

    return 1.0 - AntiAliasStep(wireframeSize, minDistToEdge);
}

half WireframeBS(half3 baryCoord, half wireframeSize, half squeezeMin = 0, half squeezeMax = 1, half dashRepeat = 1, half dashLength = 1, half dashOverlap = 0)
{
#if defined(_WIREFRAMESTYLE_ON)
    return StyledWireframeBS(baryCoord, wireframeSize, squeezeMin, squeezeMax, dashRepeat, dashLength, dashOverlap);
#else
    return SolidWireframe(baryCoord, wireframeSize);
#endif
}

half WireframeWS(half3 distToEdge, half3 distAlongEdge, half3 baryCoord, half wireframeSize, half squeezeMin = 0, half squeezeMax = 1, half dashRepeat = 1, half dashLength = 1, half dashOverlap = 0)
{
#if defined(_WIREFRAMESTYLE_ON)
    return StyledWireframeWS(distToEdge, distAlongEdge, baryCoord, wireframeSize, squeezeMin, squeezeMax, dashRepeat, dashLength, dashOverlap);
#else
    return SolidWireframe(distToEdge, wireframeSize);
#endif
}

void InitializeBarycentricCoordinate(float3 position0, float3 position1, float3 position2, out float3 baryCoord0, out float3 baryCoord1, out float3 baryCoord2)
{
#if !defined(_WIREFRAMEQUAD_ON)
    baryCoord0 = float3(0, 1, 0);
    baryCoord1 = float3(0, 0, 1);
    baryCoord2 = float3(1, 0, 0);
#else
    float3 dir[3];
    float sqLen[3];

    dir[0] = position1 - position0;
    dir[1] = position2 - position1;
    dir[2] = position0 - position2;

    sqLen[0] = dot(dir[0], dir[0]);
    sqLen[1] = dot(dir[1], dir[1]);
    sqLen[2] = dot(dir[2], dir[2]);

    if(sqLen[0] > sqLen[1] && sqLen[0] > sqLen[2])
    {
        baryCoord0 = float3(1, 1, 0);
        baryCoord1 = float3(1, 0, 1);
        baryCoord2 = float3(1, 0, 0);
    }
    else if(sqLen[1] > sqLen[0] && sqLen[1] > sqLen[2])
    {
        baryCoord0 = float3(0, 1, 0);
        baryCoord1 = float3(0, 1, 1);
        baryCoord2 = float3(1, 1, 0);
    }
    else
    {
        baryCoord0 = float3(0, 1, 1);
        baryCoord1 = float3(0, 0, 1);
        baryCoord2 = float3(1, 0, 1);
    }
#endif
}

void InitializeDistanceToEdge(float3 position0, float3 position1, float3 position2,
    out float3 distToEdge0, out float3 distToEdge1, out float3 distToEdge2)
{
    float3 dir[3];
    float sqLen[3];
    float height[3];

    dir[0] = position1 - position0;
    dir[1] = position2 - position1;
    dir[2] = position0 - position2;

    sqLen[0] = dot(dir[0], dir[0]);
    sqLen[1] = dot(dir[1], dir[1]);
    sqLen[2] = dot(dir[2], dir[2]);

    height[0] = sqLen[2] / 2 - sqLen[0] / 4 + sqLen[1] / 2
        - (sqLen[2] * sqLen[2] - 2 * sqLen[2] * sqLen[1] + sqLen[1] * sqLen[1]) / (4 * sqLen[0]);
    height[0] = sqrt(height[0]);

    height[1] = sqLen[0] / 2 - sqLen[1] / 4 + sqLen[2] / 2
        - (sqLen[0] * sqLen[0] - 2 * sqLen[0] * sqLen[2] + sqLen[2] * sqLen[2]) / (4 * sqLen[1]);
    height[1] = sqrt(height[1]);

    height[2] = sqLen[1] / 2 - sqLen[2] / 4 + sqLen[0] / 2
        - (sqLen[1] * sqLen[1] - 2 * sqLen[1] * sqLen[0] + sqLen[0] * sqLen[0]) / (4 * sqLen[2]);
    height[2] = sqrt(height[2]);

#if !defined(_WIREFRAMEQUAD_ON)
    distToEdge0 = float3(0, height[1], 0);
    distToEdge1 = float3(0, 0, height[2]);
    distToEdge2 = float3(height[0], 0, 0);
#else
    if(sqLen[0] > sqLen[1] && sqLen[0] > sqLen[2])
    {
        float offset = height[1] + height[2];
        distToEdge0 = float3(offset, height[1], 0);
        distToEdge1 = float3(offset, 0, height[2]);
        distToEdge2 = float3(height[0] + offset, 0, 0);
    }
    else if(sqLen[1] > sqLen[0] && sqLen[1] > sqLen[2])
    {
        float offset = height[0] + height[2];
        distToEdge0 = float3(0, offset + height[1], 0);
        distToEdge1 = float3(0, offset, height[2]);
        distToEdge2 = float3(height[0], offset, 0);
    }
    else
    {
        float offset = height[0] + height[1];
        distToEdge0 = float3(0, height[1], offset);
        distToEdge1 = float3(0, 0, height[2] + offset);
        distToEdge2 = float3(height[0], 0, offset);
    }
#endif
}

#endif // UNIVERSAL_WIREFRAME_COMMON_INCLUDED
