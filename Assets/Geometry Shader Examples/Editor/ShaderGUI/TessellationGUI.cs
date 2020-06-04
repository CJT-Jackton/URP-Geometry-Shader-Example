using UnityEngine;
using UnityEngine.Rendering;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    public static class TessellationGUI
    {
        public enum TessellationMode
        {
            None = 0,
            Phong = 1
        }

        public static class Styles
        {
            public static GUIContent tessellationModeText = new GUIContent("Tessellation Options",
                "Tessellation options");

            public static GUIContent tessellationFactorText = new GUIContent("Tessellation Factor",
                "Controls the strength of the tessellation effect. Higher values result in more tessellation. Maximum tessellation factor is 15 on the Xbox One and PS4.");

            public static GUIContent tessellationFactorMinDistanceText = new GUIContent("Start Fade Distance",
                "Sets the distance (in meters) at which tessellation begins to fade out.");

            public static GUIContent tessellationFactorMaxDistanceText = new GUIContent("End Fade Distance",
                "Sets the maximum distance (in meters) to the Camera where URP tessellates triangle.");

            public static GUIContent tessellationFactorTriangleSizeText = new GUIContent("Triangle Size",
                "Sets the desired screen space size of triangles (in pixels). Smaller values result in smaller triangle.");

            public static GUIContent tessellationShapeFactorText = new GUIContent("Shape Factor",
                "Controls the strength of Phong tessellation shape (lerp factor).");

            public static readonly string[] tessellationModeNames = { "None", "Phong" };
        }

        public struct TessellationProperties
        {
            public MaterialProperty tessellationMode;
            public MaterialProperty tessellationFactor;
            public MaterialProperty tessellationFactorMinDistance;
            public MaterialProperty tessellationFactorMaxDistance;
            public MaterialProperty tessellationFactorTriangleSize;
            public MaterialProperty tessellationShapeFactor;

            public TessellationProperties(MaterialProperty[] properties)
            {
                tessellationMode = BaseShaderGUI.FindProperty("_TessellationMode", properties);
                tessellationFactor = BaseShaderGUI.FindProperty("_TessellationFactor", properties, false);
                tessellationFactorMinDistance = BaseShaderGUI.FindProperty("_TessellationFactorMinDistance", properties, false);
                tessellationFactorMaxDistance = BaseShaderGUI.FindProperty("_TessellationFactorMaxDistance", properties, false);
                tessellationFactorTriangleSize = BaseShaderGUI.FindProperty("_TessellationFactorTriangleSize", properties, false);
                tessellationShapeFactor = BaseShaderGUI.FindProperty("_TessellationShapeFactor", properties, false);
            }
        }

        public static void DoTessellation(TessellationProperties properties, MaterialEditor materialEditor)
        {
            EditorGUI.BeginChangeCheck();
            var tessmode = (int)properties.tessellationMode.floatValue;
            tessmode = EditorGUILayout.Popup(Styles.tessellationModeText, tessmode, Styles.tessellationModeNames);
            if (EditorGUI.EndChangeCheck())
                properties.tessellationMode.floatValue = tessmode;

            EditorGUI.indentLevel++;
            materialEditor.ShaderProperty(properties.tessellationFactor, Styles.tessellationFactorText);

            EditorGUI.BeginChangeCheck();
            var minDist = properties.tessellationFactorMinDistance.floatValue;
            var maxDist = properties.tessellationFactorMaxDistance.floatValue;
            var triSize = properties.tessellationFactorTriangleSize.floatValue;

            minDist = EditorGUILayout.FloatField(Styles.tessellationFactorMinDistanceText, minDist, GUILayout.ExpandWidth(false));
            maxDist = EditorGUILayout.FloatField(Styles.tessellationFactorMaxDistanceText, maxDist, GUILayout.ExpandWidth(false));
            triSize = EditorGUILayout.FloatField(Styles.tessellationFactorTriangleSizeText, triSize, GUILayout.ExpandWidth(false));

            if (EditorGUI.EndChangeCheck())
            {
                properties.tessellationFactorMinDistance.floatValue = minDist;
                properties.tessellationFactorMaxDistance.floatValue = maxDist;
                properties.tessellationFactorTriangleSize.floatValue = triSize;
            }

            materialEditor.ShaderProperty(properties.tessellationShapeFactor, Styles.tessellationShapeFactorText);
            EditorGUI.indentLevel--;
        }

        public static void SetMaterialKeywords(Material material)
        {
            if (material.HasProperty("_TessellationMode"))
            {
                TessellationMode tessMode = (TessellationMode)material.GetFloat("_TessellationMode");
                CoreUtils.SetKeyword(material, "_TESSELLATION_PHONG", tessMode == TessellationMode.Phong);
            }
        }
    }
}