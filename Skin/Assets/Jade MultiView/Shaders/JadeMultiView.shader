Shader "Jade MultiView/JadeMultiView"
{
	Properties {
		_MainTex ("Diffuse", 2D) = "white" {}
		_DiffuseIntensity( "DiffuseIntensity", Range( 0,1 ) ) = 0
		//_DiffuseLOD( "DiffuseLOD", Range( 0,16 ) ) = 0
		_MainColor( "MainColor", Color ) = ( 1,1,1,1 )
		
		_AmbientCube( "AmbientCube", Cube ) = "white" {}
		
		_MinPenetration("Minimum Penetration", float) = 0.01
		_MaxPenetration( "Maxmum Penetration", float) = 0.9
		
		_AmbientMin( "AmbientMin", Range( -1,1) ) = 0.4
		_AmbientFactor( "AmbientFactor", Range( 0,1 ) ) = 0.5
		_AmbientLOD( "AmbientLOD", Range( 0,16 ) ) = 4
		_Reverse( "Reverse", int ) = 0
		
		_PenetrationTestCount ("Penetration Test Count", float) = 16
		_OpenErrorCorrection ("Open Penetration Error Correction", Range(-1, 1)) = 1
	
		// _BlurStepScale ("Gaussian Sample Distance Scale", Range(0.01, 1.0)) = 0.01
		
		_PointLightColor("Point Light Color", Color) = ( 1,1,1,1 )
		_PointLightIntensity("Point Light Intensity", Range(0.0, 5.0)) = 1.0
		_AirFalloff("Air Falloff Rate Compared to Jade", Range(0.0, 1.0)) = 0.5
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry" "LightMode" = "ForwardBase" }
		//Tags{ "RenderType" = "Transparent" "Queue" = "Transparent" }
		LOD 200
		//Blend [_EnableBlend]
		//Blend SrcAlpha OneMinusSrcAlpha
		//Blend [_SrcBlend] [_DstBlend]
		Blend Off//One One
		//ZTest Off
		//ZWrite Off
		
		Pass 
		{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

			#pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
			#include "Autolight.cginc"
			#include "UnityShadowLibrary.cginc"
            
			uniform sampler2D _NormalTex;
			uniform samplerCUBE _AmbientCube;
			uniform sampler2D _MainTex;
			
			// uniform float4x4 _LightView;
			// uniform float4x4 _LightViewProj;
			// uniform float4x4 _LightViewProjINV;
			// uniform float4x4 _LightProjINV;

			uniform float _DiffuseIntensity;
			uniform float _DiffuseLOD;
			uniform float _MinPenetration;
			uniform float _MaxPenetration;

			uniform float _MaskIntensity;
			uniform float _Pivot;
			uniform float _FresnelIntensity;
			uniform float4 _MainColor;
			
			uniform float _AmbientMin;
			uniform float _AmbientFactor;
			uniform float _AmbientLOD;

			uniform int _Reverse;

            uniform sampler2D _TsmTex;
            uniform sampler2D _TopdownDepthTex;
            
            uniform float4x4 _WorldToLight_VP;
            uniform float4x4 WorldToTopdownCamera_VP;
            uniform float4 _TsmLightPosWorld;

            uniform float _PenetrationTestCount;
            uniform float _OpenErrorCorrection;
            uniform float _BlurStepScale;

            uniform sampler2D _PenetrationTexture;
            uniform float _TextureSize;

            uniform float4 _PointLightColor;
            uniform float _PointLightIntensity;
            uniform float _AirFalloff;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float4 normal : NORMAL;
			};

            struct v2f
            {
	            float4 pos : SV_POSITION;
            	float2 uv : TEXCOORD0;
            	float3 normalWorld : TEXCOORD1;
            	float3 eyeDirWorld : TEXCOORD2;
            	// float3 posWorld : TEXCOORD3;
            };
            
            v2f vert(a2v v)
            {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
            	o.uv = v.uv;
            	o.normalWorld = UnityObjectToWorldNormal(v.normal); // normalized
            	o.eyeDirWorld = normalize(UnityWorldSpaceViewDir(mul(unity_ObjectToWorld, v.vertex).xyz));
            	// o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;

            	return o;
            	
            }

            float4 frag(v2f i) : SV_Target
            {
            	// float travelDist = tex2D(_PenetrationTexture, i.uv).r;
            	float penetrationWeight = tex2D(_PenetrationTexture, i.uv).r;
            	
            	// 计算穿透辐照度
				// float penetrationWeight;
				// if (travelDist >= _MinDist && travelDist <= _MaxDist)
				// {
				// 	penetrationWeight = saturate((travelDist - _MinDist) / (_MaxDist - _MinDist));
				// }
				if (_Reverse)
				{
					penetrationWeight = 1.0 - penetrationWeight;
				}
            	float penetrationExp = penetrationWeight;
            	// float4 L = normalize(_TsmLightPosWorld - float4(i.posWorld, 1.0));
            	// float vDotL = max(0, dot(float4(i.eyeDirWorld, 1.0), -L));
            	// float nDotL = dot(float4(i.normalWorld, 1.0), L);
            	// float outAttenuation = nDotL + vDotL;
            	// return float4(nDotL, 0.0, 0.0, 1.0);
            	float3 penetrateIrradiance = /* vDotL * penetrationExp * */_PointLightColor  * _PointLightIntensity * 1.0  * (penetrationExp * penetrationExp);

            	float4 DiffuseTex = tex2D(_MainTex, i.uv);
				// float3 UsedColor = _MainColor;// *( 1.0 - _DiffuseIntensity ) + DiffuseTex * _DiffuseIntensity;// Blend( _MainColor, _MainColor * DiffuseTex, _DiffuseIntensity );// *_MainColor;
				float3 DiffuseContrib = _MainColor * penetrateIrradiance;// DiffuseTexel;
				DiffuseContrib += DiffuseTex * _DiffuseIntensity;
	            
				float3 reflectRay = normalize(reflect(i.normalWorld, -i.eyeDirWorld));
				float4 ambientColor = texCUBElod(_AmbientCube, float4(reflectRay, _AmbientLOD));
				float3 finalColor = DiffuseContrib;
				ambientColor = max(ambientColor, _AmbientMin);
				// if ( _Reverse == 0)
				finalColor += ambientColor * _AmbientFactor;
				return float4(finalColor, _MainColor.a); // DiffuseTexel.a );
            }
            
            ENDCG
        }
	} 
	FallBack "Diffuse"
}