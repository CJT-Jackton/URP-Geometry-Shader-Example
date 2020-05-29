#ifndef UNIVERSAL_EXTRUDE_SHADOW_CASTER_PASS_INCLUDED
#define UNIVERSAL_EXTRUDE_SHADOW_CASTER_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

float3 _LightDirection;

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VaryingsToGeometry
{
    float3 positionWS   : TEXCOORD0;
    float3 normalWS     : TEXCOORD1;
    float2 texcoord     : TEXCOORD2;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionCS   : SV_POSITION;
};

float4 GetShadowPositionHClip(float3 positionWS, float3 normalWS)
{
    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

#if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return positionCS;
}

VaryingsToGeometry ShadowPassVertex(Attributes input)
{
    VaryingsToGeometry output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.texcoord = TRANSFORM_TEX(input.texcoord, _BaseMap);

    return output;
}

// Gold Noise ©2015 dcerisano@standard3d.com
// - based on the Golden Ratio
// - uniform normalized distribution
// - fastest static noise generator function (also runs at low precision)
// float PHI = 1.61803398874989484820459;  // Φ = Golden Ratio
float gold_noise(in float2 uv, in float seed)
{
    return frac(tan(distance(uv * 1.61803398874989484820459, uv) * seed) * uv.x);
}

[maxvertexcount(15)]
void ShadowPassGeometry(triangle VaryingsToGeometry input[3], inout TriangleStream<Varyings> outputStream)
{
    Varyings output = (Varyings)0;
    VaryingsToGeometry top[3];

    float3 dir[3];

    [unroll(3)]
    for (int k = 0; k < 3; ++k)
    {
        dir[k] = input[(k + 1) % 3].positionWS.xyz - input[k].positionWS.xyz;
    }

    float3 extrudeDirWS = normalize(cross(dir[0], -dir[2]));
#if defined(_EXTRUDEANIMATION_OFF)
    float extrudeAmount = _ExtrudeSize;
#else
    float extrudeAmount = _ExtrudeSize * (sin((gold_noise(input[0].texcoord, 810) * 2 + _Time.y * _ExtrudeAnimationSpeed) * PI * 2) + 1);
#endif

    [unroll(3)]
    for (int i = 0; i < 3; ++i)
    {
        top[i] = input[i];
        top[i].positionWS.xyz += extrudeDirWS * extrudeAmount;

        output.uv = top[i].texcoord;
        output.positionCS = GetShadowPositionHClip(top[i].positionWS, top[i].normalWS);

        outputStream.Append(output);
    }

    outputStream.RestartStrip();

    [unroll(3)]
    for (int j = 0; j < 3; ++j)
    {
        float3 sideNormalWS = normalize(cross(dir[j], extrudeDirWS));

        output.uv = top[(j + 1) % 3].texcoord;
        output.positionCS = GetShadowPositionHClip(top[(j + 1) % 3].positionWS, sideNormalWS);
        outputStream.Append(output);

        output.uv = top[j].texcoord;
        output.positionCS = GetShadowPositionHClip(top[j].positionWS, sideNormalWS);
        outputStream.Append(output);

        output.uv = input[(j + 1) % 3].texcoord;
        output.positionCS = GetShadowPositionHClip(input[(j + 1) % 3].positionWS, sideNormalWS);
        outputStream.Append(output);

        output.uv = input[j].texcoord;
        output.positionCS = GetShadowPositionHClip(input[j].positionWS, sideNormalWS);
        outputStream.Append(output);

        outputStream.RestartStrip();
    }
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    return 0;
}

#endif
