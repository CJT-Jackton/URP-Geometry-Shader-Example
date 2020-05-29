#ifndef UNIVERSAL_GEOMETRY_EXTRUDE_INCLUDED
#define UNIVERSAL_GEOMETRY_EXTRUDE_INCLUDED

[maxvertexcount(15)]
void LitPassGeometry(triangle Varyings input[3], inout TriangleStream<Varyings> outputStream)
{
    Varyings output = (Varyings)0;
    Varyings top[3];

    float3 dir[3];

    [unroll(3)]
    for (int k = 0; k < 3; ++k)
    {
        dir[k] = input[(k + 1) % 3].positionWS - input[k].positionWS;
    }

    float3 extrudeDir = normalize(cross(dir[0], -dir[2]));

    // Extrude face
    [unroll(3)]
    for (int i = 0; i < 3; ++i)
    {
        top[i] = input[i];
        top[i].positionWS = top[i].positionWS + extrudeDir * _ExtrudeSize;
        top[i].positionCS = TransformWorldToHClip(top[i].positionWS);

        // LWRP shadow coordinate
        VertexPositionInputs vertexInput = (VertexPositionInputs)0;
        vertexInput.positionWS = top[i].positionWS;
        vertexInput.positionCS = top[i].positionCS;

#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
        top[i].shadowCoord = GetShadowCoord(vertexInput);
#endif

        outputStream.Append(top[i]);
    }

    outputStream.RestartStrip();

    // Construct sides
    [unroll(3)]
    for (int j = 0; j < 3; ++j)
    {
        half3 normalWS = normalize(cross(dir[j], extrudeDir));

        output = top[(j + 1) % 3];
        output.normalWS = normalWS;
        outputStream.Append(output);
        output = top[j];
        output.normalWS = normalWS;
        outputStream.Append(output);
        output = input[(j + 1) % 3];
        output.normalWS = normalWS;
        outputStream.Append(output);
        output = input[j];
        output.normalWS = normalWS;
        outputStream.Append(output);

        outputStream.RestartStrip();
    }
}

#endif // UNIVERSAL_GEOMETRY_EXTRUDE_INCLUDED