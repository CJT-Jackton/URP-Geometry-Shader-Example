Shader "Universal Render Pipeline/Wireframe/Unlit"
{
    Properties
    {
        _BaseMap("Texture", 2D) = "white" {}
        _BaseColor("Color", Color) = (1, 1, 1, 1)
        _Cutoff("AlphaCutout", Range(0.0, 1.0)) = 0.5
        
        // Wireframe Base Properties
        [Enum(BarycentricSpace, 0, WorldSpace, 1)] _WireframeMode("Wireframe Mode", Float) = 0
        _WireframeSize("Wireframe Size", Float) = 0.1
        [HDR] _WireframeBaseColor("Wireframe Color", Color) = (0, 0, 0, 1)
        [Toggle] _WireframeQuad("Wireframe Display Quad", Float) = 0.0

        // Wireframe Style Properties
        [Toggle] _WireframeStyle("Enable Style", Float) = 0.0
        [Toggle] _WireframeSqueeze("Enable Squeeze", Float) = 0.0
        _WireframeSqueezeMin("Squeeze Min", Range(0.0, 1.0)) = 0.5
        _WireframeSqueezeMax("Squeeze Max", Range(0.0, 1.0)) = 1.0
        [Toggle] _WireframeDash("Enable Dash", Float) = 0.0
        _WireframeDashRepeat("Dash Repeat", Float) = 0.5
        _WireframeDashLength("Dash Length", Range(0.0, 1.0)) = 0.7
        [Toggle] _WireframeDashOverlap("Dash Overlap Join", Float) = 1.0

        // BlendMode
        [HideInInspector] _Surface("__surface", Float) = 0.0
        [HideInInspector] _Blend("__blend", Float) = 0.0
        [HideInInspector] _AlphaClip("__clip", Float) = 0.0
        [HideInInspector] _SrcBlend("Src", Float) = 1.0
        [HideInInspector] _DstBlend("Dst", Float) = 0.0
        [HideInInspector] _ZWrite("ZWrite", Float) = 1.0
        [HideInInspector] _Cull("__cull", Float) = 2.0

        // Editmode props
        [HideInInspector] _QueueOffset("Queue offset", Float) = 0.0

        // ObsoleteProperties
        [HideInInspector] _MainTex("BaseMap", 2D) = "white" {}
        [HideInInspector] _Color("Base Color", Color) = (0.5, 0.5, 0.5, 1)
        [HideInInspector] _SampleGI("SampleGI", float) = 0.0 // needed from bakedlit
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        LOD 100

        Blend [_SrcBlend][_DstBlend]
        ZWrite [_ZWrite]
        Cull [_Cull]

        Pass
        {
            Name "Unlit"
            Tags{"LightMode" = "SRPDefaultUnlit"}

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 5.0
            #pragma require geometry

            #pragma vertex UnlitPassPackVaryingsToGS
            #pragma geometry WireframeUnlitPassGeometry
            #pragma fragment UnlitPassFragment

            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _ALPHAPREMULTIPLY_ON

            // -------------------------------------
            // Wireframe keywords
            #pragma shader_feature _WIREFRAMEMODE_WORLDSPACE
            #pragma shader_feature _WIREFRAMEQUAD_ON
            #pragma shader_feature _WIREFRAMESTYLE_ON
            #pragma shader_feature _WIREFRAMESQUEEZE_ON
            #pragma shader_feature _WIREFRAMEDASH_ON

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #include "WireframeCommon.hlsl"
            #include "WireframeUnlitInput.hlsl"
            #include "WireframeUnlitForwardPass.hlsl"
            ENDHLSL
        }
        Pass
        {
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }

        // This pass it not used during regular rendering, only for lightmap baking.
        Pass
        {
            Name "Meta"
            Tags{"LightMode" = "Meta"}

            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma vertex UniversalVertexMeta
            #pragma fragment UniversalFragmentMetaUnlit

            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitMetaPass.hlsl"

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "UnityEditor.Rendering.Universal.ShaderGUI.WireframeUnlitShader"
}