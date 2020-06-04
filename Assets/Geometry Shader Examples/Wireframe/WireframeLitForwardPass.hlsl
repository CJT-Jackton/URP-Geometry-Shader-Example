#ifndef UNIVERSAL_WIREFRAME_FORWARD_LIT_PASS_INCLUDED
#define UNIVERSAL_WIREFRAME_FORWARD_LIT_PASS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT;
    float2 texcoord     : TEXCOORD0;
    float2 lightmapUV   : TEXCOORD1;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct VaryingsToGS
{
    float3 positionWS   : TEXCOORD0;
    float3 normalWS     : TEXCOORD1;
    float4 tangentWS    : TEXCOORD2;
    float2 texcoord     : TEXCOORD3;
    float2 lightmapUV   : TEXCOORD4;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float2 uv                       : TEXCOORD0;
    DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 1);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    float3 positionWS               : TEXCOORD2;
#endif

#ifdef _NORMALMAP
    float4 normalWS                 : TEXCOORD3;    // xyz: normal, w: viewDir.x
    float4 tangentWS                : TEXCOORD4;    // xyz: tangent, w: viewDir.y
    float4 bitangentWS              : TEXCOORD5;    // xyz: bitangent, w: viewDir.z
#else
    float3 normalWS                 : TEXCOORD3;
    float3 viewDirWS                : TEXCOORD4;
#endif

    half4 fogFactorAndVertexLight   : TEXCOORD6; // x: fogFactor, yzw: vertex light

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    float4 shadowCoord              : TEXCOORD7;
#endif

    float3 barycentricCoord         : TEXCOORD8;

    float4 positionCS               : SV_POSITION;
    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};

void InitializeInputData(Varyings input, half3 normalTS, out InputData inputData)
{
    inputData = (InputData)0;

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    inputData.positionWS = input.positionWS;
#endif

#ifdef _NORMALMAP
    half3 viewDirWS = half3(input.normalWS.w, input.tangentWS.w, input.bitangentWS.w);
    inputData.normalWS = TransformTangentToWorld(normalTS,
        half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz));
#else
    half3 viewDirWS = input.viewDirWS;
    inputData.normalWS = input.normalWS;
#endif

    inputData.normalWS = NormalizeNormalPerPixel(inputData.normalWS);
    viewDirWS = SafeNormalize(viewDirWS);
    inputData.viewDirectionWS = viewDirWS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    inputData.shadowCoord = input.shadowCoord;
#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
    inputData.shadowCoord = TransformWorldToShadowCoord(inputData.positionWS);
#else
    inputData.shadowCoord = float4(0, 0, 0, 0);
#endif

    inputData.fogCoord = input.fogFactorAndVertexLight.x;
    inputData.vertexLighting = input.fogFactorAndVertexLight.yzw;
    inputData.bakedGI = SAMPLE_GI(input.lightmapUV, input.vertexSH, inputData.normalWS);
}

///////////////////////////////////////////////////////////////////////////////
//                  Vertex, Geometry and Fragment functions                  //
///////////////////////////////////////////////////////////////////////////////

VaryingsToGS LitPassPackVaryingsToGS(Attributes input)
{
    VaryingsToGS output = (VaryingsToGS)0;
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);

    output.positionWS = TransformObjectToWorld(input.positionOS.xyz);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
    output.tangentWS.xyz = TransformObjectToWorldDir(input.tangentOS.xyz);
    output.tangentWS.w = input.tangentOS.w;
    output.texcoord = input.texcoord;
    output.lightmapUV = input.lightmapUV;

    return output;
}

// Used in Standard (Physically Based) shader
Varyings LitPassVertex(VaryingsToGS input)
{
    Varyings output = (Varyings)0;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_TRANSFER_INSTANCE_ID(input, output);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    VertexPositionInputs vertexInput;
    vertexInput.positionWS = input.positionWS;
    vertexInput.positionCS = TransformWorldToHClip(input.positionWS);

    VertexNormalInputs normalInput;
    normalInput.normalWS = input.normalWS;
    normalInput.tangentWS = input.tangentWS.xyz;
    normalInput.bitangentWS = cross(input.normalWS, input.tangentWS.xyz) * input.tangentWS.w * GetOddNegativeScale();

    half3 viewDirWS = GetCameraPositionWS() - vertexInput.positionWS;
    half3 vertexLight = VertexLighting(vertexInput.positionWS, normalInput.normalWS);
    half fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.uv = TRANSFORM_TEX(input.texcoord, _BaseMap);

#ifdef _NORMALMAP
    output.normalWS = half4(normalInput.normalWS, viewDirWS.x);
    output.tangentWS = half4(normalInput.tangentWS, viewDirWS.y);
    output.bitangentWS = half4(normalInput.bitangentWS, viewDirWS.z);
#else
    output.normalWS = NormalizeNormalPerVertex(normalInput.normalWS);
    output.viewDirWS = viewDirWS;
#endif

    OUTPUT_LIGHTMAP_UV(input.lightmapUV, unity_LightmapST, output.lightmapUV);
    OUTPUT_SH(output.normalWS.xyz, output.vertexSH);

    output.fogFactorAndVertexLight = half4(fogFactor, vertexLight);

#if defined(REQUIRES_WORLD_SPACE_POS_INTERPOLATOR)
    output.positionWS = vertexInput.positionWS;
#endif

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
    output.shadowCoord = GetShadowCoord(vertexInput);
#endif

    output.positionCS = vertexInput.positionCS;

    return output;
}

[maxvertexcount(3)]
void WireframeLitPassGeometry(triangle VaryingsToGS input[3], inout TriangleStream<Varyings> outputStream)
{
    Varyings output[3];
    output[0] = LitPassVertex(input[0]);
    output[1] = LitPassVertex(input[1]);
    output[2] = LitPassVertex(input[2]);

#if defined(_WIREFRAMEMODE_WORLDSPACE)
    InitializeDistanceToEdge(
        input[0].positionWS, input[1].positionWS, input[2].positionWS,
        output[0].barycentricCoord, output[1].barycentricCoord, output[2].barycentricCoord);
#else
    InitializeBarycentricCoordinate(
        input[0].positionWS, input[1].positionWS, input[2].positionWS,
        output[0].barycentricCoord, output[1].barycentricCoord, output[2].barycentricCoord);
#endif

    outputStream.Append(output[0]);
    outputStream.Append(output[1]);
    outputStream.Append(output[2]);
}

// Used in Standard (Physically Based) shader
half4 LitPassFragment(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    SurfaceData surfaceData;
    InitializeWireframeLitSurfaceData(input.uv, input.barycentricCoord, surfaceData);

    InputData inputData;
    InitializeInputData(input, surfaceData.normalTS, inputData);

    half4 color = UniversalFragmentPBR(inputData, surfaceData.albedo, surfaceData.metallic, surfaceData.specular, surfaceData.smoothness, surfaceData.occlusion, surfaceData.emission, surfaceData.alpha);

    color.rgb = MixFog(color.rgb, inputData.fogCoord);
    return color;
}

#endif
