#ifndef UNIVERSAL_TESSELLATION_COMMON_INCLUDED
#define UNIVERSAL_TESSELLATION_COMMON_INCLUDED

#if defined(SHADER_API_XBOXONE) || defined(SHADER_API_PSSL)
// AMD recommand this value for GCN http://amd-dev.wpengine.netdna-cdn.com/wordpress/media/2013/05/GCNPerformanceTweets.pdf
#define MAX_TESSELLATION_FACTORS 15.0
#else
#define MAX_TESSELLATION_FACTORS 64.0
#endif

struct TessellationFactors
{
    float edge[3]  : SV_TessFactor;
    float inside   : SV_InsideTessFactor;
};

float4 GetTessellationFactors(float3 p0, float3 p1, float3 p2, float3 n0, float3 n1, float3 n2)
{
    bool3 frustumCullEdgesMainView = CullTriangleEdgesFrustum(p0, p1, p2, 0, _FrustumPlanes, 5); // Do not test the far plane

    float3 edgeTessFactors = float3(frustumCullEdgesMainView.x ? 0 : 1, frustumCullEdgesMainView.y ? 0 : 1, frustumCullEdgesMainView.z ? 0 : 1);

    /*
    // Adaptive screen space tessellation
    if (_TessellationFactorTriangleSize > 0.0)
    {
        // return a value between 0 and 1
        // Warning: '_ViewProjMatrix' can be the viewproj matrix of the light when we render shadows, that's why we use _CameraViewProjMatrix instead
        edgeTessFactors *= GetScreenSpaceTessFactor(p0, p1, p2, mul(unity_CameraProjection, unity_WorldToCamera), _ScreenParams, _TessellationFactorTriangleSize); // Use primary camera view
    }
    */

    // Distance based tessellation
    if (_TessellationFactorMaxDistance > 0.0)
    {
        float3 distFactor = GetDistanceBasedTessFactor(p0, p1, p2, _WorldSpaceCameraPos, _TessellationFactorMinDistance, _TessellationFactorMaxDistance);  // Use primary camera view
        // We square the disance factor as it allow a better percptual descrease of vertex density.
        edgeTessFactors *= distFactor * distFactor;
    }

    edgeTessFactors *= _TessellationFactor;

    // TessFactor below 1.0 have no effect. At 0 it kill the triangle, so clamp it to 1.0
    edgeTessFactors = max(edgeTessFactors, float3(1.0, 1.0, 1.0));

    return CalcTriTessFactorsFromEdgeTessFactors(edgeTessFactors);
}

[maxtessfactor(MAX_TESSELLATION_FACTORS)]
[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HullConstant")]
[outputcontrolpoints(3)]
VaryingsToDS Hull(
    InputPatch<VaryingsToDS, 3> input,
    uint id : SV_OutputControlPointID)
{
    return input[id];
}

TessellationFactors HullConstant(InputPatch<VaryingsToDS, 3> input)
{
    float4 tessellationFactor = GetTessellationFactors(
        input[0].positionWS, input[1].positionWS, input[2].positionWS,
        input[0].normalWS, input[1].normalWS, input[2].normalWS);

    TessellationFactors output;
    output.edge[0] = min(tessellationFactor.x, MAX_TESSELLATION_FACTORS);
    output.edge[1] = min(tessellationFactor.y, MAX_TESSELLATION_FACTORS);
    output.edge[2] = min(tessellationFactor.z, MAX_TESSELLATION_FACTORS);
    output.inside = min(tessellationFactor.w, MAX_TESSELLATION_FACTORS);

    return output;
}

[domain("tri")]
Varyings Domain(
    TessellationFactors factors,
    const OutputPatch<VaryingsToDS, 3> input,
    float3 baryCoords : SV_DomainLocation)
{
    VaryingsToVS output = InterpolateWithBaryCoordsToDS(input[0], input[1], input[2], baryCoords);
    UNITY_TRANSFER_INSTANCE_ID(input[0], output);

#ifdef _TESSELLATION_PHONG
    output.positionWS = PhongTessellation(
        output.positionWS,
        input[0].positionWS, input[1].positionWS, input[2].positionWS,
        input[0].normalWS, input[1].normalWS, input[2].normalWS,
        baryCoords, _TessellationShapeFactor
    );
#endif

    return TessellationVertex(output);
}

#endif // UNIVERSAL_TESSELLATION_COMMON_INCLUDED