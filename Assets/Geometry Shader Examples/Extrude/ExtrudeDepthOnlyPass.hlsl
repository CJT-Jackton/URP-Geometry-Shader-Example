#ifndef UNIVERSAL_EXTRUDE_DEPTH_ONLY_PASS_INCLUDED
#define UNIVERSAL_EXTRUDE_DEPTH_ONLY_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VaryingsToGeometry
{
    float3 positionWS   : TEXCOORD0;
    float2 texcoord     : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv           : TEXCOORD0;
    float4 positionCS   : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

VaryingsToGeometry DepthOnlyVertex(Attributes input)
{
    VaryingsToGeometry output = (VaryingsToGeometry)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
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
void DepthOnlyGeometry(triangle VaryingsToGeometry input[3], inout TriangleStream<Varyings> outputStream)
{
    VaryingsToGeometry top[3];
    Varyings output[6];

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
        UNITY_TRANSFER_INSTANCE_ID(input[i], output[i]);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output[i]);
        output[i].uv = input[i].texcoord;
        output[i].positionCS = TransformWorldToHClip(input[i].positionWS);

        top[i] = input[i];
        top[i].positionWS.xyz += extrudeDirWS * extrudeAmount;

        UNITY_TRANSFER_INSTANCE_ID(top[i], output[i + 3]);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output[i + 3]);
        output[i + 3].uv = top[i].texcoord;
        output[i + 3].positionCS = TransformWorldToHClip(top[i].positionWS);

        outputStream.Append(output[i]);
    }

    outputStream.RestartStrip();

    [unroll(3)]
    for (int j = 0; j < 3; ++j)
    {
        outputStream.Append(output[(j + 1) % 3 + 3]);
        outputStream.Append(output[j + 3]);
        outputStream.Append(output[(j + 1) % 3]);
        outputStream.Append(output[j]);

        outputStream.RestartStrip();
    }
}

half4 DepthOnlyFragment(Varyings input) : SV_TARGET
{
    //UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    Alpha(SampleAlbedoAlpha(input.uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    return 0;
}
#endif
