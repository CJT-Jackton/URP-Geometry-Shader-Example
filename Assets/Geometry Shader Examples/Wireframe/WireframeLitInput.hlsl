#ifndef UNIVERSAL_WIREFRAME_LIT_INPUT_INCLUDED
#define UNIVERSAL_WIREFRAME_LIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _SpecColor;
half4 _EmissionColor;
half4 _WireframeBaseColor;
half4 _WireframeSpecColor;
half4 _WireframeEmissionColor;
half _Cutoff;
half _Smoothness;
half _Metallic;
half _BumpScale;
half _OcclusionStrength;
half _WireframeSize;
half _WireframeSmoothness;
half _WireframeMetallic;
CBUFFER_END

TEXTURE2D(_OcclusionMap);       SAMPLER(sampler_OcclusionMap);
TEXTURE2D(_MetallicGlossMap);   SAMPLER(sampler_MetallicGlossMap);
TEXTURE2D(_SpecGlossMap);       SAMPLER(sampler_SpecGlossMap);

#ifdef _SPECULAR_SETUP
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_SpecGlossMap, sampler_SpecGlossMap, uv)
#else
    #define SAMPLE_METALLICSPECULAR(uv) SAMPLE_TEXTURE2D(_MetallicGlossMap, sampler_MetallicGlossMap, uv)
#endif

half4 SampleMetallicSpecGloss(float2 uv, half albedoAlpha)
{
    half4 specGloss;

#ifdef _METALLICSPECGLOSSMAP
    specGloss = SAMPLE_METALLICSPECULAR(uv);
    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;
    #else
        specGloss.a *= _Smoothness;
    #endif
#else // _METALLICSPECGLOSSMAP
    #if _SPECULAR_SETUP
        specGloss.rgb = _SpecColor.rgb;
    #else
        specGloss.rgb = _Metallic.rrr;
    #endif

    #ifdef _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
        specGloss.a = albedoAlpha * _Smoothness;
    #else
        specGloss.a = _Smoothness;
    #endif
#endif

    return specGloss;
}

half SampleOcclusion(float2 uv)
{
#ifdef _OCCLUSIONMAP
// TODO: Controls things like these by exposing SHADER_QUALITY levels (low, medium, high)
#if defined(SHADER_API_GLES)
    return SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
#else
    half occ = SAMPLE_TEXTURE2D(_OcclusionMap, sampler_OcclusionMap, uv).g;
    return LerpWhiteTo(occ, _OcclusionStrength);
#endif
#else
    return 1.0;
#endif
}

inline void InitializeWireframeLitSurfaceData(float2 uv, float3 baryCoord, out SurfaceData outSurfaceData)
{
    half wireframe = saturate(WireframeBS(baryCoord, _WireframeSize));

    half4 albedoAlpha = SampleAlbedoAlpha(uv, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap));
    outSurfaceData.alpha = Alpha(min(albedoAlpha.a, wireframe), _BaseColor, _Cutoff);

    half4 specGloss = SampleMetallicSpecGloss(uv, albedoAlpha.a);
    outSurfaceData.albedo = lerp(albedoAlpha.rgb * _BaseColor.rgb, _WireframeBaseColor.rgb, wireframe);

#if _SPECULAR_SETUP
    outSurfaceData.metallic = 1.0h;
    outSurfaceData.specular = lerp(specGloss.rgb, _WireframeSpecColor.rgb, wireframe);
#else
    outSurfaceData.metallic = lerp(specGloss.r, _WireframeMetallic, wireframe);
    outSurfaceData.specular = half3(0.0h, 0.0h, 0.0h);
#endif

    outSurfaceData.smoothness = lerp(specGloss.a, _WireframeSmoothness, wireframe);
    outSurfaceData.normalTS = lerp(SampleNormal(uv, TEXTURE2D_ARGS(_BumpMap, sampler_BumpMap), _BumpScale), half3(0.0h, 0.0h, 1.0h), wireframe);
    outSurfaceData.occlusion = lerp(SampleOcclusion(uv), 1.0, wireframe);
    outSurfaceData.emission = lerp(SampleEmission(uv, _EmissionColor.rgb, TEXTURE2D_ARGS(_EmissionMap, sampler_EmissionMap)), _WireframeEmissionColor.rgb, wireframe);
}

#endif // UNIVERSAL_INPUT_SURFACE_PBR_INCLUDED
