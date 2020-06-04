#ifndef UNIVERSAL_WIREFRAME_FORWARD_UNLIT_PASS_INCLUDED
#define UNIVERSAL_WIREFRAME_FORWARD_UNLIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS       : POSITION;
    float2 uv               : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VaryingsToGS
{
    float3 positionWS       : TEXCOORD0;
    float2 uv               : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                  : TEXCOORD0;
    float fogCoord             : TEXCOORD1;
    float3 barycentricCoord    : TEXCOORD2;

#if defined(_WIREFRAMEMODE_WORLDSPACE)
    float3 positionWS                          : TEXCOORD3;
    float3 distanceToEdge                      : TEXCOORD4;
    nointerpolation float3 vertex0positionWS   : TEXCOORD5;
    nointerpolation float3 vertex1positionWS   : TEXCOORD6;
    nointerpolation float3 vertex2positionWS   : TEXCOORD7;
#endif

    float4 positionCS          : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

///////////////////////////////////////////////////////////////////////////////
//                  Vertex, Geometry and Fragment functions                  //
///////////////////////////////////////////////////////////////////////////////

VaryingsToGS UnlitPassPackVaryingsToGS(Attributes input)
{
    VaryingsToGS output = (VaryingsToGS)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

    return output;
}

Varyings UnlitPassVertex(VaryingsToGS input)
{
    Varyings output = (Varyings)0;
    
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
    
    output.uv = input.uv;
    float4 positionCS = TransformWorldToHClip(input.positionWS);
    output.fogCoord = ComputeFogFactor(positionCS.z);
#if defined(_WIREFRAMEMODE_WORLDSPACE)
    output.positionWS = input.positionWS;
#endif
    output.positionCS = positionCS;

    return output;
}

[maxvertexcount(3)]
void WireframeUnlitPassGeometry(triangle VaryingsToGS input[3], inout TriangleStream<Varyings> outputStream)
{
    Varyings output[3];
    output[0] = UnlitPassVertex(input[0]);
    output[1] = UnlitPassVertex(input[1]);
    output[2] = UnlitPassVertex(input[2]);

    InitializeBarycentricCoordinate(
        input[0].positionWS, input[1].positionWS, input[2].positionWS,
        output[0].barycentricCoord, output[1].barycentricCoord, output[2].barycentricCoord);

#if defined(_WIREFRAMEMODE_WORLDSPACE)
    InitializeDistanceToEdge(
        input[0].positionWS, input[1].positionWS, input[2].positionWS,
        output[0].distanceToEdge, output[1].distanceToEdge, output[2].distanceToEdge);
    
    output[0].vertex0positionWS = input[0].positionWS;
    output[1].vertex0positionWS = input[0].positionWS;
    output[2].vertex0positionWS = input[0].positionWS;

    output[0].vertex1positionWS = input[1].positionWS;
    output[1].vertex1positionWS = input[1].positionWS;
    output[2].vertex1positionWS = input[1].positionWS;

    output[0].vertex2positionWS = input[2].positionWS;
    output[1].vertex2positionWS = input[2].positionWS;
    output[2].vertex2positionWS = input[2].positionWS;
#endif

    outputStream.Append(output[0]);
    outputStream.Append(output[1]);
    outputStream.Append(output[2]);
}

half4 UnlitPassFragment(Varyings input, bool frontFace : SV_IsFrontFace) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

#if defined(_WIREFRAMEMODE_WORLDSPACE)
    half3 distanceAlongEdge = half3(
        distance(input.positionWS, input.vertex0positionWS),
        distance(input.positionWS, input.vertex1positionWS),
        distance(input.positionWS, input.vertex2positionWS));


    half wireframe = WireframeWS(
        input.distanceToEdge, distanceAlongEdge, input.barycentricCoord,
        _WireframeSize, _WireframeSqueezeMin, _WireframeSqueezeMax,
        _WireframeDashRepeat, _WireframeDashLength, _WireframeDashOverlap);
#else
    half wireframe = WireframeBS(
        input.barycentricCoord,
        _WireframeSize, _WireframeSqueezeMin, _WireframeSqueezeMax,
        _WireframeDashRepeat, _WireframeDashLength, _WireframeDashOverlap);
#endif

    half3 wireframeColor = _WireframeBaseColor.rgb;

    /*
    half desaturateFactor = 0.7;
    half luminance = 0.299 * wireframeColor.x + 0.587 * wireframeColor.y + 0.114 * wireframeColor.z;
    half3 wireframeAltColor = lerp(wireframeColor, 0.5, desaturateFactor);
    wireframeColor = frontFace ? wireframeColor : wireframeAltColor; 
    */

    half2 uv = input.uv;
    half4 texColor = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, uv);
    half3 color = lerp(texColor.rgb * _BaseColor.rgb, wireframeColor, wireframe);
    half alpha = texColor.a * _BaseColor.a;
    AlphaDiscard(min(alpha, wireframe + _Cutoff), _Cutoff);

#ifdef _ALPHAPREMULTIPLY_ON
    color *= alpha;
#endif

    color = MixFog(color, input.fogCoord);
    
    return half4(color, alpha);
}

#endif // UNIVERSAL_WIREFRAME_FORWARD_UNLIT_PASS_INCLUDED