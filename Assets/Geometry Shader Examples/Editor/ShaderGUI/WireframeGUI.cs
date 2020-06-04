using UnityEngine;
using UnityEngine.Rendering;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    public static class WireframeGUI
    {
        public enum WireframeMode
        {
            BarycentricSpace = 0,
            WorldSpace = 1
        }

        public static class Styles
        {
            public static GUIContent wireframeModeText = new GUIContent("Wireframe Options",
                "Wireframe options");

            public static GUIContent wireframeSizeText = new GUIContent("Size",
                "Controls the size of the wireframe.");

            public static GUIContent wireframeColorText = new GUIContent("Base Color",
                "Set the base color of the wireframe.");

            public static GUIContent wireframeQuadText = new GUIContent("Display Quad",
                "Display Quads instead of Triangles.");

            public static GUIContent wireframeSmoothnessText = new GUIContent("Smoothness",
                "Controls the spread of highlights and reflections of the wireframe.");

            public static GUIContent wireframeMetallicText = new GUIContent("Metallic",
                "Sets the metallic of the wireframe.");

            public static GUIContent wireframeSpecularText = new GUIContent("Specular",
                "Sets the specular color of the wireframe.");

            public static GUIContent wireframeEmissionText = new GUIContent("Emission Color",
                "Sets the emission color of the wireframe.");

            public static GUIContent wireframeStyleText = new GUIContent("Wireframe Style",
                "Enable style wireframe.");

            public static GUIContent wireframeSqueezeText = new GUIContent("Squeeze",
                "Enable squeeze.");

            public static GUIContent wireframeSqueezeMinText = new GUIContent("Midpoint Size",
                "Wireframe size at the midpoint.");

            public static GUIContent wireframeSqueezeMaxText = new GUIContent("Endpoint Size",
                "Wireframe size at the endpoint.");

            public static GUIContent wireframeDashText = new GUIContent("Dash",
                "Enable dash.");

            public static GUIContent wireframeDashRepeatText = new GUIContent("Repeat",
                "Control the repeat amount of dash. The higher the value means more dashes.");

            public static GUIContent wireframeDashLengthText = new GUIContent("Length",
                "Control the length of each dash in percentage.");

            public static GUIContent wireframeDashOverlapText = new GUIContent("Overlap Join",
                "Whether the dash should overlap on the join point.");

            public static readonly string[] wireframeModeName = { "Barycentric Space", "World Space" };
        }

        public struct WireframeProperties
        {
            // Wireframe Basic Props
            public MaterialProperty wireframeMode;
            public MaterialProperty wireframeSize;
            public MaterialProperty wireframeBaseColor;
            public MaterialProperty wireframeQuad;

            // Wireframe Surface Props
            public MaterialProperty wireframeSmoothness;
            public MaterialProperty wireframeMetallic;
            public MaterialProperty wireframeSpecColor;
            public MaterialProperty wireframeEmissionColor;

            // Wireframe Style Props
            public MaterialProperty wireframeStyle;
            public MaterialProperty wireframeSqueeze;
            public MaterialProperty wireframeSqueezeMin;
            public MaterialProperty wireframeSqueezeMax;
            public MaterialProperty wireframeDash;
            public MaterialProperty wireframeDashRepeat;
            public MaterialProperty wireframeDashLength;
            public MaterialProperty wireframeDashOverlap;

            public WireframeProperties(MaterialProperty[] properties)
            {
                // Wireframe Basic Props
                wireframeMode = BaseShaderGUI.FindProperty("_WireframeMode", properties);
                wireframeSize = BaseShaderGUI.FindProperty("_WireframeSize", properties);
                wireframeBaseColor = BaseShaderGUI.FindProperty("_WireframeBaseColor", properties, false);
                wireframeQuad = BaseShaderGUI.FindProperty("_WireframeQuad", properties, false);

                // Wireframe Surface Props
                wireframeSmoothness = BaseShaderGUI.FindProperty("_WireframeSmoothness", properties, false);
                wireframeMetallic = BaseShaderGUI.FindProperty("_WireframeMetallic", properties, false);
                wireframeSpecColor = BaseShaderGUI.FindProperty("_WireframeSpecColor", properties, false);
                wireframeEmissionColor = BaseShaderGUI.FindProperty("_WireframeEmissionColor", properties, false);

                // Wireframe Style Props
                wireframeStyle = BaseShaderGUI.FindProperty("_WireframeStyle", properties, false);
                wireframeSqueeze = BaseShaderGUI.FindProperty("_WireframeSqueeze", properties, false);
                wireframeSqueezeMin = BaseShaderGUI.FindProperty("_WireframeSqueezeMin", properties, false);
                wireframeSqueezeMax = BaseShaderGUI.FindProperty("_WireframeSqueezeMax", properties, false);
                wireframeDash = BaseShaderGUI.FindProperty("_WireframeDash", properties, false);
                wireframeDashRepeat = BaseShaderGUI.FindProperty("_WireframeDashRepeat", properties, false);
                wireframeDashLength = BaseShaderGUI.FindProperty("_WireframeDashLength", properties, false);
                wireframeDashOverlap = BaseShaderGUI.FindProperty("_WireframeDashOverlap", properties, false);
            }
        }

        public static void DoWireframe(WireframeProperties properties, MaterialEditor materialEditor, Material material)
        {
            EditorGUI.BeginChangeCheck();
            var wireframemode = (int)properties.wireframeMode.floatValue;
            wireframemode = EditorGUILayout.Popup(Styles.wireframeModeText, wireframemode, Styles.wireframeModeName);
            if (EditorGUI.EndChangeCheck())
                properties.wireframeMode.floatValue = wireframemode;

            EditorGUI.indentLevel++;
            EditorGUI.BeginChangeCheck();
            var wireframeSize = properties.wireframeSize.floatValue;
            wireframeSize = EditorGUILayout.FloatField(Styles.wireframeSizeText, wireframeSize, GUILayout.ExpandWidth(false));
            if (EditorGUI.EndChangeCheck())
                properties.wireframeSize.floatValue = wireframeSize;

            materialEditor.ShaderProperty(properties.wireframeQuad, Styles.wireframeQuadText);

            EditorGUI.BeginChangeCheck();
            Color baseColor = properties.wireframeBaseColor.colorValue;
            baseColor = EditorGUILayout.ColorField(Styles.wireframeColorText, baseColor, true, true, false, GUILayout.ExpandWidth(false));
            if (EditorGUI.EndChangeCheck())
                properties.wireframeBaseColor.colorValue = baseColor;

            if (properties.wireframeSmoothness != null)
            {
                DoWireframeSurfaceOptions(properties, materialEditor, material);
            }

            EditorGUI.indentLevel--;

            if (properties.wireframeStyle != null)
            {
                materialEditor.ShaderProperty(properties.wireframeStyle, Styles.wireframeStyleText);
                bool enableStyle = properties.wireframeStyle.floatValue != 0;

                if (enableStyle)
                {
                    EditorGUI.indentLevel++;
                    DoWireframeStyle(properties, materialEditor);
                    EditorGUI.indentLevel--;
                }
            }
        }

        public static void DoWireframeSurfaceOptions(WireframeProperties properties, MaterialEditor materialEditor, Material material)
        {
            materialEditor.ShaderProperty(properties.wireframeSmoothness, Styles.wireframeSmoothnessText);

            if (material.HasProperty("_WorkflowMode"))
            {
                bool isSpecularWorkFlow = (LitGUI.WorkflowMode)material.GetFloat("_WorkflowMode") == LitGUI.WorkflowMode.Specular;

                if (isSpecularWorkFlow)
                    materialEditor.ShaderProperty(properties.wireframeSpecColor, Styles.wireframeSpecularText);
                else
                    materialEditor.ShaderProperty(properties.wireframeMetallic, Styles.wireframeMetallicText);
            }

            EditorGUI.BeginChangeCheck();
            Color emissionColor = properties.wireframeEmissionColor.colorValue;
            emissionColor = EditorGUILayout.ColorField(Styles.wireframeEmissionText, emissionColor, true, false, true, GUILayout.ExpandWidth(false));
            if (EditorGUI.EndChangeCheck())
                properties.wireframeEmissionColor.colorValue = emissionColor;
        }

        public static void DoWireframeStyle(WireframeProperties properties, MaterialEditor materialEditor)
        {
            materialEditor.ShaderProperty(properties.wireframeSqueeze, Styles.wireframeSqueezeText);

            bool enableSqueeze = properties.wireframeSqueeze.floatValue != 0;
            EditorGUI.BeginDisabledGroup(!enableSqueeze);
            EditorGUI.indentLevel++;
            materialEditor.ShaderProperty(properties.wireframeSqueezeMin, Styles.wireframeSqueezeMinText);
            materialEditor.ShaderProperty(properties.wireframeSqueezeMax, Styles.wireframeSqueezeMaxText);
            EditorGUI.indentLevel--;
            EditorGUI.EndDisabledGroup();

            materialEditor.ShaderProperty(properties.wireframeDash, Styles.wireframeDashText);
            
            bool enableDash = properties.wireframeDash.floatValue != 0;
            EditorGUI.BeginDisabledGroup(!enableDash);
            EditorGUI.indentLevel++;

            WireframeMode wireframeMode = (WireframeMode)properties.wireframeMode.floatValue;

            if (wireframeMode == WireframeMode.BarycentricSpace)
            {
                EditorGUI.BeginChangeCheck();
                var dashRepeat = (int)properties.wireframeDashRepeat.floatValue;
                dashRepeat = EditorGUILayout.IntSlider(Styles.wireframeDashRepeatText, dashRepeat, 1, 10);
                if (EditorGUI.EndChangeCheck())
                    properties.wireframeDashRepeat.floatValue = dashRepeat;
            }
            else
            {
                materialEditor.ShaderProperty(properties.wireframeDashRepeat, Styles.wireframeDashRepeatText);
            }

            materialEditor.ShaderProperty(properties.wireframeDashLength, Styles.wireframeDashLengthText);

            if (wireframeMode == WireframeMode.BarycentricSpace)
                materialEditor.ShaderProperty(properties.wireframeDashOverlap, Styles.wireframeDashOverlapText);

            EditorGUI.indentLevel--;
            EditorGUI.EndDisabledGroup();
        }

        public static void SetMaterialKeywords(Material material)
        {
            if (material.HasProperty("_WireframeMode"))
            {
                WireframeMode wireframeMode = (WireframeMode)material.GetFloat("_WireframeMode");
                CoreUtils.SetKeyword(material, "_WIREFRAMEMODE_WORLDSPACE", wireframeMode == WireframeMode.WorldSpace);
            }

            if (material.HasProperty("_WireframeQuad"))
                CoreUtils.SetKeyword(material, "_WIREFRAMEQUAD_ON", material.GetFloat("_WireframeQuad") != 0.0f);

            if (material.HasProperty("_WireframeStyle"))
                CoreUtils.SetKeyword(material, "_WIREFRAMESTYLE_ON", material.GetFloat("_WireframeStyle") != 0.0f);

            if (material.HasProperty("_WireframeSqueeze"))
                CoreUtils.SetKeyword(material, "_WIREFRAMESQUEEZE_ON", material.GetFloat("_WireframeSqueeze") != 0.0f);

            if (material.HasProperty("_WireframeDash"))
                CoreUtils.SetKeyword(material, "_WIREFRAMEDASH_ON", material.GetFloat("_WireframeDash") != 0.0f);
        }
    }
}