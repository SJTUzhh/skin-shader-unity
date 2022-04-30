// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'


Shader "RE/Jade" {
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
			
			uniform float4x4 _LightView;
			uniform float4x4 _LightViewProj;
			uniform float4x4 _LightViewProjINV;
			uniform float4x4 _LightProjINV;

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

			uniform sampler2D _CameraDepthTexture;
			uniform sampler2D _LastCameraDepthTexture;
						
			float Blend( float A, float B, float Weight )
			{
				return A * ( 1 - Weight ) + B * Weight;
			}
            fixed4 frag(VS_OUT In) : SV_Target
            {
            	//float4 DiffuseTexel = tex2D( _MainTex, In.Texcoord );
				
				float Shadow = 1.0;
				float3 FinalColor;// = DiffuseTexel.rgb;
				
				float4 ProjectedLightPos = mul( _LightViewProj, float4( In.WorldPosition, 1.0 ) );				
				ProjectedLightPos.xyz /= ProjectedLightPos.w;
				float4 ProjectedLightPos2 = ProjectedLightPos;
				ProjectedLightPos.xy = ProjectedLightPos.xy * float2(0.5,0.5) + float2( 0.5, 0.5 );

				float2 SampleDepthPos = ProjectedLightPos.xy;
				#if defined (SHADER_API_D3D11)
					SampleDepthPos.y = 1.0 - SampleDepthPos.y;
				#endif
				
				float LightDepth = tex2D( _CameraDepthTexture, SampleDepthPos.xy ).x;

				#if defined (SHADER_API_GLES) || defined (SHADER_API_GLES3) || defined (SHADER_API_GLCORE)					
					LightDepth = 1.0 - LightDepth;
				#endif
				
				float4 LightEnterPos = mul( _LightViewProjINV, float4( ProjectedLightPos2.xy, LightDepth, 1.0 ) );
				LightEnterPos.xyz /= LightEnterPos.w;
											
				float3 PenetrationVector = LightEnterPos.xyz - In.WorldPosition;
				float TravelDist = length( PenetrationVector );

				FinalColor = TravelDist;

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

				return fixed4( FinalColor.rgb, _MainColor.a );// DiffuseTexel.a );
            }

            ENDCG
        }
	} 
	FallBack "Diffuse"
}
