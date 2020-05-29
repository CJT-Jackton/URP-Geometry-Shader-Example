using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace UnityEditor.Rendering.Universal.ShaderGUI
{
    public static class ExtrudeGUI
    {

        public static class Styles
        {
            public static GUIContent extrudeSizeText = new GUIContent("Extrude Size",
                "Controls the extrusion amount.");

            public static GUIContent extrudeAnimationText = new GUIContent("Extrude Animation",
                "Enable animation for extrusion.");

            public static GUIContent extrudeAnimationSpeedText = new GUIContent("Speed",
                "Playback speed of the extrusion animation.");
        }

        public struct ExtrudeProperties
        {
            public MaterialProperty extrudeSize;
            public MaterialProperty extrudeAnimation;
            public MaterialProperty extrudeAnimationSpeed;

            public ExtrudeProperties(MaterialProperty[] properties)
            {
                extrudeSize = BaseShaderGUI.FindProperty("_ExtrudeSize", properties, false);
                extrudeAnimation = BaseShaderGUI.FindProperty("_ExtrudeAnimation", properties, false);
                extrudeAnimationSpeed = BaseShaderGUI.FindProperty("_ExtrudeAnimationSpeed", properties, false);
            }
        }

        public static void DoExtrude(ExtrudeProperties properties, MaterialEditor materialEditor)
        {
            materialEditor.ShaderProperty(properties.extrudeSize, Styles.extrudeSizeText);
            
            bool enableAnimation = false;
            enableAnimation = properties.extrudeAnimation.floatValue == 1;

            materialEditor.ShaderProperty(properties.extrudeAnimation, Styles.extrudeAnimationText);
            EditorGUI.indentLevel++;
            EditorGUI.BeginDisabledGroup(!enableAnimation);
            materialEditor.ShaderProperty(properties.extrudeAnimationSpeed, Styles.extrudeAnimationSpeedText);
            EditorGUI.EndDisabledGroup();
            EditorGUI.indentLevel--;
        }

        public static void SetMaterialKeywords(Material material)
        {
            if (material.HasProperty("_ExtrudeAnimation"))
                CoreUtils.SetKeyword(material, "_EXTRUDEANIMATION_OFF",
                    material.GetFloat("_ExtrudeAnimation") == 0.0f);
        }
    }
}