Shader "Amazing Assets/Subsurface Scattering/Reflective/Specular" 
{
	Properties 
	{
//[HideInInspector][CurvedWorldBendSettings] _CurvedWorldBendSettings("0|1|1", Vector) = (0, 0, 0, 0)

		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 1)
		_Shininess ("Shininess", Range (0.03, 1)) = 0.078125
		_MainTex ("Base (RGB) RefStrGloss (A)", 2D) = "white" {} 	
		_ReflectColor ("Reflection Color", Color) = (1,1,1,0.5)
		_Cube ("Reflection Cubemap", Cube) = "_Skybox" { }

		
		//Subsurface Scattering Options
		[HideInInspector] _SSS_TranslucencyDistortion ("",Range(0,0.5)) = 0.1
		[HideInInspector] _SSS_TranslucencyPower("",Range(1.0,16.0)) = 1.0
		[HideInInspector] _SSS_TranslucencyScale("", Float) = 1.0

		[HideInInspector] [KeywordEnum(Off, On)] _SSS_ADVANCED_TRANSLUCENCY ("", Float) = 0
		[HideInInspector] _SSS_TranslucencyColor ("", color) = (1, 1, 1, 1)
		[HideInInspector][NoScaleOffset] _SSS_TranslucencyMap ("",2D) = "white" {}
		[HideInInspector] _SSS_TranslucencyBackfaceIntensity("", Float) = 0.15

		[HideInInspector] _SSS_DirectionalLightStrength("", Float) = 0.2
		[HideInInspector] _SSS_NonDirectionalLightStrength("", Float) = 0.5
        [HideInInspector] _SSS_LightAttenuation("", Float) = 2        
		[HideInInspector] _SSS_Emission("", Float) = 0
		[HideInInspector] _SSS_NormalizeLightVector("", Float) = 1

		[HideInInspector] [KeywordEnum(Off, On)] _SSS_FRESNEL ("", Float) = 0
		[HideInInspector] _SSS_FresnelColor("", color) = (1, 1, 1, 1)
		[HideInInspector] _SSS_FresnelPower("", Range(0.5, 8.0)) = 2.0
	}

	SubShader 
	{
		Tags { "RenderType"="Opaque" "SSSType"="Legacy/PixelLit"}
		LOD 300
		
		CGPROGRAM
		#pragma surface surf TransBlinnPhong vertex:vert addshadow
		#pragma target 3.0

		
//#define CURVEDWORLD_BEND_TYPE_CLASSICRUNNER_X_POSITIVE
//#define CURVEDWORLD_BEND_ID_1
//#pragma shader_feature_local CURVEDWORLD_DISABLED_ON
//#pragma shader_feature_local CURVEDWORLD_NORMAL_TRANSFORMATION_ON
//#include "Assets/Amazing Assets/Curved World/Shaders/Core/CurvedWorldTransform.cginc"


		#pragma shader_feature_local _SSS_ADVANCED_TRANSLUCENCY_ON
		#pragma shader_feature_local _SSS_FRESNEL_ON

		#define _SSS_SPECULAR
		#define _SSS_REFLECTIVE

		#include "cginc/SSS.cginc"

		ENDCG


//PassName "ScenePickingPass"
		Pass
        {
            Name "ScenePickingPass"
            Tags { "LightMode" = "Picking" }

            BlendOp Add
            Blend One Zero
            ZWrite On
            Cull Off

            CGPROGRAM
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"


            #pragma target 3.0
            #pragma multi_compile_instancing

            #pragma vertex vertEditorPass
            #pragma fragment fragScenePickingPass


//#define CURVEDWORLD_BEND_TYPE_CLASSICRUNNER_X_POSITIVE
//#define CURVEDWORLD_BEND_ID_1
//#pragma shader_feature_local CURVEDWORLD_DISABLED_ON
//#pragma shader_feature_local CURVEDWORLD_NORMAL_TRANSFORMATION_ON
//#include "Assets/Amazing Assets/Curved World/Shaders/Core/CurvedWorldTransform.cginc"


            #include "cginc/SceneSelection.cginc" 
            ENDCG
        }	//Pass "ScenePickingPass"		

		//PassName "SceneSelectionPass"
		Pass
        {
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }

            BlendOp Add
            Blend One Zero
            ZWrite On
            Cull Off

            CGPROGRAM
			#include "HLSLSupport.cginc"
			#include "UnityShaderVariables.cginc"
			#include "UnityShaderUtilities.cginc"


            #pragma target 3.0
            #pragma multi_compile_instancing

            #pragma vertex vertEditorPass
            #pragma fragment fragSceneHighlightPass


//#define CURVEDWORLD_BEND_TYPE_CLASSICRUNNER_X_POSITIVE
//#define CURVEDWORLD_BEND_ID_1
//#pragma shader_feature_local CURVEDWORLD_DISABLED_ON
//#pragma shader_feature_local CURVEDWORLD_NORMAL_TRANSFORMATION_ON
//#include "Assets/Amazing Assets/Curved World/Shaders/Core/CurvedWorldTransform.cginc"


            #include "cginc/SceneSelection.cginc" 
            ENDCG
        }	//Pass "SceneSelectionPass"		

	}


	//SM2.0
	SubShader 
	{
		Tags { "RenderType"="Opaque" "SSSType"="Legacy/PixelLit"}
		LOD 300
		
		CGPROGRAM
		#pragma surface surf TransBlinnPhong vertex:vert addshadow

		
//#define CURVEDWORLD_BEND_TYPE_CLASSICRUNNER_X_POSITIVE
//#define CURVEDWORLD_BEND_ID_1
//#pragma shader_feature_local CURVEDWORLD_DISABLED_ON
//#pragma shader_feature_local CURVEDWORLD_NORMAL_TRANSFORMATION_ON
//#include "Assets/Amazing Assets/Curved World/Shaders/Core/CurvedWorldTransform.cginc"


		#pragma shader_feature_local _SSS_ADVANCED_TRANSLUCENCY_ON
		#pragma shader_feature_local _SSS_FRESNEL_ON

		#define _SSS_REFLECTIVE

		#include "cginc/SSS.cginc"

		ENDCG
	}

	FallBack "Legacy Shaders/Diffuse"
	CustomEditor "AmazingAssets.SubsurfaceScatteringShader.DefaultShaderGUI"
}
