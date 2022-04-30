Shader "Jade MultiView/JadeMultiView"
{
	Properties {
		_MainTex ("Diffuse", 2D) = "white" {}
		_DiffuseIntensity( "DiffuseIntensity", Range( 0,1 ) ) = 0
		//_DiffuseLOD( "DiffuseLOD", Range( 0,16 ) ) = 0
		_MainColor( "MainColor", Color ) = ( 1,1,1,1 )
		
		_AmbientCube( "AmbientCube", Cube ) = "white" {}
		
		_MinDist("MinDist", float ) = 0.01
		_MaxDist( "MaxDist", float ) = 0.9
		
		_AmbientMin( "AmbientMin", Range( -1,1) ) = 0.4
		_AmbientFactor( "AmbientFactor", Range( 0,1 ) ) = 0.5
		_AmbientLOD( "AmbientLOD", Range( 0,16 ) ) = 4
		_Reverse( "Reverse", int ) = 0
		
		_PenetrationTestCount ("Penetration Test Count", float) = 16
		
		_OpenErrorCorrection ("Open Penetration Error Correction", Range(-1, 1)) = 1
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

			struct VS_IN
			{
                float4 vertex : POSITION;
                float4 color : COLOR;
                float4 texcoord0 : TEXCOORD0;
                float3 normal : NORMAL;
            };
			struct VS_OUT
			{
                float4 pos:SV_POSITION;
                float4 Color : COLOR;
                float2 Texcoord : TEXCOORD0;
                float3 WorldNormal : NORMAL;
                float3 WorldPosition : TEXCOORD1;				
				SHADOW_COORDS( 2 )
				float3 EyeDir : TEXCOORD3;
            };
            					
			uniform sampler2D _NormalTex;
			uniform samplerCUBE _AmbientCube;
			uniform sampler2D _MainTex;
			
			// uniform float4x4 _LightView;
			// uniform float4x4 _LightViewProj;
			// uniform float4x4 _LightViewProjINV;
			// uniform float4x4 _LightProjINV;

			uniform float _DiffuseIntensity;
			uniform float _DiffuseLOD;
			uniform float _MinDist;
			uniform float _MaxDist;

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
            
			
            VS_OUT vert(VS_IN In)
            {
            	VS_OUT Out;
            	float3 LocalPos = In.vertex.xyz;
            	float2 Texcoord = float2( In.texcoord0.x, In.texcoord0.y );
            	float3 WorldPosition = mul( unity_ObjectToWorld, float4(LocalPos,1) );
            	float3 WorldNormal = UnityObjectToWorldNormal( In.normal );
            	
            	Out.EyeDir = -normalize(UnityWorldSpaceViewDir( WorldPosition ));
            	
            	Out.pos = mul (UNITY_MATRIX_VP, float4( WorldPosition, 1) );
            	Out.Texcoord = In.texcoord0;
            	Out.Color = In.color;
            	Out.WorldNormal = WorldNormal;
            	Out.WorldPosition = WorldPosition;

				TRANSFER_SHADOW( Out );

                return Out;
            }

			// uniform sampler2D _CameraDepthTexture;
			// uniform sampler2D _LastCameraDepthTexture;
						
			// float Blend( float A, float B, float Weight )
			// {
			// 	return A * ( 1 - Weight ) + B * Weight;
			// }
            
            fixed4 frag(VS_OUT In) : SV_Target
            {
            	//float4 DiffuseTexel = tex2D( _MainTex, In.Texcoord );
				
				float Shadow = 1.0;
				float3 FinalColor;// = DiffuseTexel.rgb;

            	// 采样 TSM 获取 LightEnterPos（世界坐标）
            	float4 ProjectedLightPos = mul(_WorldToLight_VP, float4(In.WorldPosition, 1.0));
            	ProjectedLightPos.xyz /= ProjectedLightPos.w;
            	float2 LightNdcPos = ProjectedLightPos.xy * 0.5 + 0.5;
            	#if UNITY_UV_STARTS_AT_TOP
            		LightNdcPos.y = 1.0 - LightNdcPos.y;
            	#endif
            	float4 LightEnterPos = float4(tex2D(_TsmTex, LightNdcPos).xyz, 1.0);

            	float TravelDist = length(LightEnterPos.xyz - In.WorldPosition);

            	// 将 LightEnterPos 转换到 Top-down Camera 空间
				LightEnterPos = mul(WorldToTopdownCamera_VP, LightEnterPos);
            	LightEnterPos.xyz /= LightEnterPos.w;
            	LightEnterPos.xy = LightEnterPos.xy * 0.5 + 0.5;
            	#if UNITY_UV_STARTS_AT_TOP
            		LightEnterPos.y = 1.0 - LightEnterPos.y;
            	#endif
            	
            	// 将 WorldPos 转换到 Topdown Camera 空间
            	float4 EyeEnterPos = mul(WorldToTopdownCamera_VP, float4(In.WorldPosition, 1.0));
            	EyeEnterPos.xyz /= EyeEnterPos.w;
            	EyeEnterPos.xy = EyeEnterPos.xy * 0.5 + 0.5;
            	#if UNITY_UV_STARTS_AT_TOP
            		EyeEnterPos.y = 1.0 - EyeEnterPos.y;
            	#endif

            	// 采点测试，计算错误率
            	int ErrorCount = 0;
            	float DepthCompareBias = 0.01;
            	float3 TestStep = (LightEnterPos - EyeEnterPos) / _PenetrationTestCount;
				float3 TestPos = EyeEnterPos;
            	for(int i = 0; i < _PenetrationTestCount; i++)
            	{
            		float Depth = tex2D(_TopdownDepthTex, TestPos.xy).r;
            		if(Depth + DepthCompareBias < TestPos.z)
            		{
            			ErrorCount++;
            		}
            		TestPos += TestStep;
            	}
            	float ErrorRate = float(ErrorCount) / _PenetrationTestCount;

            	if(_OpenErrorCorrection > 0.0)
            		TravelDist *= 1 - ErrorRate;
				
				// float4 ProjectedLightPos = mul( _LightViewProj, float4( In.WorldPosition, 1.0 ) );				
				// ProjectedLightPos.xyz /= ProjectedLightPos.w;
				// float4 ProjectedLightPos2 = ProjectedLightPos;
				// ProjectedLightPos.xy = ProjectedLightPos.xy * float2(0.5,0.5) + float2( 0.5, 0.5 );
				//
				// float2 SampleDepthPos = ProjectedLightPos.xy;
				// #if defined (SHADER_API_D3D11)
				// 	SampleDepthPos.y = 1.0 - SampleDepthPos.y;
				// #endif
				//
				// float LightDepth = tex2D( _CameraDepthTexture, SampleDepthPos.xy ).x;
				//
				// #if defined (SHADER_API_GLES) || defined (SHADER_API_GLES3) || defined (SHADER_API_GLCORE)					
				// 	LightDepth = 1.0 - LightDepth;
				// #endif
				//
				// float4 LightEnterPos = mul( _LightViewProjINV, float4( ProjectedLightPos2.xy, LightDepth, 1.0 ) );
				// LightEnterPos.xyz /= LightEnterPos.w;
											
				// float3 PenetrationVector = LightEnterPos.xyz - In.WorldPosition;
				// float TravelDist = length( PenetrationVector );

				// FinalColor = TravelDist;

				float PenetrationWeight = 0.0;
				if ( TravelDist > _MaxDist )
					PenetrationWeight = 1.0;
				if ( TravelDist < _MinDist || TravelDist > _MaxDist )
				{

				}
				else
				{
					PenetrationWeight = (TravelDist - _MinDist) / ( _MaxDist - _MinDist );
				}

				if ( _Reverse )
					PenetrationWeight = 1.0 - PenetrationWeight;

				float3 ReflectRay = reflect( normalize( In.WorldNormal ), In.EyeDir );
				float4 AmbientColor = texCUBElod( _AmbientCube, float4( ReflectRay, _AmbientLOD ) );
				
				float PenetrationExp = PenetrationWeight;

				float4 DiffuseTex = tex2D( _MainTex, In.Texcoord );

				float3 UsedColor = _MainColor;// *( 1.0 - _DiffuseIntensity ) + DiffuseTex * _DiffuseIntensity;// Blend( _MainColor, _MainColor * DiffuseTex, _DiffuseIntensity );// *_MainColor;
				
				float3 DiffuseContrib = PenetrationExp * UsedColor;// DiffuseTexel;
				
				FinalColor = DiffuseContrib;
				
				AmbientColor = max( AmbientColor, _AmbientMin );
				//if ( _Reverse == 0)
					FinalColor += AmbientColor * _AmbientFactor;

					FinalColor.rgb += DiffuseTex * _DiffuseIntensity;

            	// return float4(ErrorRate, 0.0, 0.0, 1.0);
				return fixed4( FinalColor.rgb, _MainColor.a );// DiffuseTexel.a );
            }

            ENDCG
        }
	} 
	FallBack "Diffuse"
}