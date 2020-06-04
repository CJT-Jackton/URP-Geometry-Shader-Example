#ifndef UNIVERSAL_WIREFRAME_UNLIT_INPUT_INCLUDED
#define UNIVERSAL_WIREFRAME_UNLIT_INPUT_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"

CBUFFER_START(UnityPerMaterial)
float4 _BaseMap_ST;
half4 _BaseColor;
half4 _WireframeBaseColor;
half _Cutoff;
half _WireframeSize;
half _WireframeSqueezeMin;
half _WireframeSqueezeMax;
half _WireframeDashRepeat;
half _WireframeDashLength;
half _WireframeDashOverlap;
CBUFFER_END

#endif