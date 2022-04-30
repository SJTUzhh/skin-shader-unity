using UnityEngine;
using UnityEditor;


namespace AmazingAssets.SubsurfaceScatteringShader
{
    public class DefaultShaderGUI : ShaderGUI
    {
        static MaterialProperty _CurvedWorldBendSettings;


        static MaterialProperty _SSS_TranslucencyDistortion;
        static MaterialProperty _SSS_TranslucencyPower;
        static MaterialProperty _SSS_TranslucencyScale;

        static MaterialProperty _SSS_ADVANCED_TRANSLUCENCY;
        static MaterialProperty _SSS_TranslucencyColor;
        static MaterialProperty _SSS_TranslucencyMap;
        static MaterialProperty _SSS_TranslucencyBackfaceIntensity;

        static MaterialProperty _SSS_DirectionalLightStrength;
        static MaterialProperty _SSS_NonDirectionalLightStrength;
        static MaterialProperty _SSS_LightAttenuation;        
        static MaterialProperty _SSS_Emission;
        static MaterialProperty _SSS_NormalizeLightVector;

        static MaterialProperty _SSS_FRESNEL;
        static MaterialProperty _SSS_FresnelColor;
        static MaterialProperty _SSS_FresnelPower;


        static Material targetMaterial;
        static string materialTag;


        static public void Init(MaterialProperty[] props)
        {
            _CurvedWorldBendSettings = FindProperty("_CurvedWorldBendSettings", props, false);

            _SSS_TranslucencyDistortion = FindProperty("_SSS_TranslucencyDistortion", props);
            _SSS_TranslucencyPower = FindProperty("_SSS_TranslucencyPower", props);
            _SSS_TranslucencyScale = FindProperty("_SSS_TranslucencyScale", props);

            _SSS_ADVANCED_TRANSLUCENCY = FindProperty("_SSS_ADVANCED_TRANSLUCENCY", props);
            _SSS_TranslucencyColor = FindProperty("_SSS_TranslucencyColor", props);
            _SSS_TranslucencyMap = FindProperty("_SSS_TranslucencyMap", props);            
            _SSS_TranslucencyBackfaceIntensity = FindProperty("_SSS_TranslucencyBackfaceIntensity", props);

            _SSS_DirectionalLightStrength = FindProperty("_SSS_DirectionalLightStrength", props);
            _SSS_NonDirectionalLightStrength = FindProperty("_SSS_NonDirectionalLightStrength", props);
            _SSS_LightAttenuation = FindProperty("_SSS_LightAttenuation", props);           
            _SSS_Emission = FindProperty("_SSS_Emission", props);
            _SSS_NormalizeLightVector = FindProperty("_SSS_NormalizeLightVector", props);

            _SSS_FRESNEL = FindProperty("_SSS_FRESNEL", props);
            _SSS_FresnelColor = FindProperty("_SSS_FresnelColor", props);
            _SSS_FresnelPower = FindProperty("_SSS_FresnelPower", props);


            materialTag = targetMaterial.GetTag("SSSType", false);
        }

        public override void OnGUI(UnityEditor.MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            DrawCuvedWorld(materialEditor);

            base.OnGUI(materialEditor, properties);



            targetMaterial = (Material)materialEditor.target;
            Init(properties);


            materialEditor.SetDefaultGUIWidths();
            UnityEditor.EditorGUIUtility.fieldWidth = 56;

            GUILayout.Space(10);
            DrawHeader();

            DrawMainSettings(materialEditor);

            DrawRimEffect(materialEditor);

            DrawAdditionalLightSettings(materialEditor);           
        }

        static void DrawCuvedWorld(UnityEditor.MaterialEditor materialEditor)
        {
            if(_CurvedWorldBendSettings != null)
            {
                EditorGUILayout.BeginVertical(EditorStyles.helpBox);
                {
                    EditorGUILayout.LabelField("Curved World", EditorStyles.boldLabel);
                    materialEditor.ShaderProperty(_CurvedWorldBendSettings, string.Empty);
                }
                EditorGUILayout.EndVertical();

                GUILayout.Space(10);
            }
        }


        static void DrawMainSettings(UnityEditor.MaterialEditor materialEditor)
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            {
                EditorGUILayout.LabelField("Translucency", EditorStyles.boldLabel);

                EditorGUI.indentLevel++;
                {
                    materialEditor.ShaderProperty(_SSS_TranslucencyDistortion, "Distortion");

                    materialEditor.ShaderProperty(_SSS_TranslucencyPower, "Power");

                    materialEditor.ShaderProperty(_SSS_TranslucencyScale, "Scale");
                    if (_SSS_TranslucencyScale.floatValue < 0.0f)
                        _SSS_TranslucencyScale.floatValue = 0.0f;
                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();

            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            {
                EditorGUILayout.LabelField("More Color Options", EditorStyles.boldLabel);

                EditorGUI.indentLevel++;
                {
                    materialEditor.ShaderProperty(GUILayoutUtility.GetLastRect(), _SSS_ADVANCED_TRANSLUCENCY, " ");

                    if (_SSS_ADVANCED_TRANSLUCENCY.floatValue > 0.5f == true)
                    {
                        if (materialTag.Contains("OnePass"))
                        {
                            materialEditor.ShaderProperty(_SSS_TranslucencyColor, "Color (RGB)");

                            materialEditor.ShaderProperty(_SSS_TranslucencyBackfaceIntensity, "Instensity");
                            if (_SSS_TranslucencyBackfaceIntensity.floatValue < 0f)
                                _SSS_TranslucencyBackfaceIntensity.floatValue = 0f;
                        }
                        else
                        {
                            materialEditor.ShaderProperty(_SSS_TranslucencyColor, "Color (RGB)");
                            materialEditor.ShaderProperty(_SSS_TranslucencyMap, "Map (RGB)");

                            materialEditor.ShaderProperty(_SSS_TranslucencyBackfaceIntensity, "Instensity");
                            if (_SSS_TranslucencyBackfaceIntensity.floatValue < 0f)
                                _SSS_TranslucencyBackfaceIntensity.floatValue = 0f;
                        }
                    }
                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }

        static void DrawAdditionalLightSettings(UnityEditor.MaterialEditor materialEditor)
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            {
                EditorGUILayout.LabelField("Lighting", EditorStyles.boldLabel);

                EditorGUI.indentLevel++;
                {                    
                    materialEditor.ShaderProperty(_SSS_DirectionalLightStrength, "Directional Light Strength");
                    if (_SSS_DirectionalLightStrength.floatValue < 0f)
                        _SSS_DirectionalLightStrength.floatValue = 0f;

                    materialEditor.ShaderProperty(_SSS_NonDirectionalLightStrength, "Point/Spot Lights Strength");
                    if (_SSS_NonDirectionalLightStrength.floatValue < 0f)
                        _SSS_NonDirectionalLightStrength.floatValue = 0f;

                    if (targetMaterial.shader.name.Contains("VertexLit") == false)
                        materialEditor.ShaderProperty(_SSS_LightAttenuation, "Light Attenuation");


                    materialEditor.ShaderProperty(_SSS_Emission, "Emission");
                    if (_SSS_Emission.floatValue < 0f)
                        _SSS_Emission.floatValue = 0f;


                    bool normalizeDiff = _SSS_NormalizeLightVector.floatValue > 0.5;
                    EditorGUI.BeginChangeCheck();
                    normalizeDiff = EditorGUILayout.ToggleLeft(" Normalize Light Vector", normalizeDiff);
                    if (EditorGUI.EndChangeCheck())
                    {
                        _SSS_NormalizeLightVector.floatValue = normalizeDiff ? 1 : 0;
                    }
                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }

        static void DrawRimEffect(UnityEditor.MaterialEditor materialEditor)
        {
            EditorGUILayout.BeginVertical(EditorStyles.helpBox);
            {
                EditorGUILayout.LabelField("Fresnel", EditorStyles.boldLabel);

                EditorGUI.indentLevel++;
                {
                    materialEditor.ShaderProperty(GUILayoutUtility.GetLastRect(), _SSS_FRESNEL, " ");

                    if (_SSS_FRESNEL.floatValue > 0.5f)
                    {
                        EditorGUI.indentLevel++;
                        {
                            materialEditor.ShaderProperty(_SSS_FresnelColor, "Rim Color");

                            if (string.IsNullOrEmpty(materialTag) == false && materialTag.Contains("OnePass"))
                            {
                                //Empty
                            }
                            else
                            {
                                materialEditor.ShaderProperty(_SSS_FresnelPower, "Rim Power");
                            }
                        }
                        EditorGUI.indentLevel--;
                    }
                }
                EditorGUI.indentLevel--;
            }
            EditorGUILayout.EndVertical();
        }


        static void DrawHeader()
        {
            Rect labelRect = EditorGUILayout.GetControlRect();


            Rect headerRect = labelRect;
            headerRect.xMin = 10;
            headerRect.yMax -= 2;
            EditorGUI.DrawRect(headerRect, Color.black * 0.6f);


            Rect lineRect = headerRect;
            lineRect.yMin = lineRect.yMax;
            lineRect.height = 2;
            EditorGUI.DrawRect(lineRect, new Color(0.92f, 0.65f, 0, 1));


            EditorGUI.LabelField(labelRect, "Subsurface Scattering Options", EditorStyles.whiteLabel);
        }
    }
}