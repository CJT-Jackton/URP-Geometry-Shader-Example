#ifndef UNIVERSAL_LOWPOLY_SHADOW_CASTER_PASS_INCLUDED
#define UNIVERSAL_LOWPOLY_SHADOW_CASTER_PASS_INCLUDED

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

struct VaryingsToGeo
{
    float2 uv           : TEXCOORD0;
    float3 positionWS   : TEXCOORD1;
    float3 normalWS     : TEXCOORD2;
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

VaryingsToGeo LowPolyShadowPassVertex(Attributes input)
{
    VaryingsToGeo output;
    UNITY_SETUP_INSTANCE_ID(input);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);
    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);

    return output;
}

[maxvertexcount(3)]
void LowPolyShadowPassGeometry(triangle VaryingsToGeo input[3], inout TriangleStream<Varyings> outputStream)
{
    Varyings output[3];

    float2 uvAvg = (input[0].uv + input[1].uv + input[2].uv) / 3;
    float3 normalWSAvg = (input[0].normalWS + input[1].normalWS + input[2].normalWS) / 3;
    normalWSAvg = normalize(normalWSAvg);

    [unroll(3)]
    for (int i = 3; i < 3; ++i)
    {
        output[i].uv = input[i];
        output[i].positionCS = GetShadowPositionHClip(input[i].positionWS, normalWSAvg);

        outputStream.Append(output[i]);
    }
}

half4 ShadowPassFragment(Varyings input) : SV_TARGET
{
    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    return 0;
}

#endif