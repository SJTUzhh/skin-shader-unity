Shader "Jade MultiView/ComputePenetration"
{
    SubShader
	{
		
		// LOD 200
		// Cull Off
		
		Pass 
		{
			Cull Off
			Tags { /*"RenderType"="Opaque" "Queue"="Geometry"*/ "LightMode" = "ForwardBase" }
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            // #pragma target 3.0

			// #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
			#include "Autolight.cginc"
			#include "UnityShadowLibrary.cginc"
            					
			// uniform sampler2D _NormalTex;
			// uniform samplerCUBE _AmbientCube;
			uniform sampler2D _MainTex;

			uniform float _DiffuseIntensity;
			// uniform float _DiffuseLOD;
			uniform float _MinPenetration;
			uniform float _MaxPenetration;

			// uniform float _MaskIntensity;
			// uniform float _Pivot;
			// uniform float _FresnelIntensity;
			 uniform float4 _MainColor;
			
			// uniform float _AmbientMin;
			// uniform float _AmbientFactor;
			// uniform float _AmbientLOD;

			uniform int _Reverse;

            uniform sampler2D _TsmTex;
            uniform sampler2D _TopdownDepthTex;
            
            uniform float4x4 _WorldToLight_VP;
            uniform float4x4 _WorldToTopdownCamera_VP;
            uniform float4 _TsmLightPosWorld;

            uniform float _PenetrationTestCount;
            uniform float _OpenErrorCorrection;

            uniform float _AirFalloff;

            struct a2v
			{
                float4 vertex : POSITION;
            	float2 uv : TEXCOORD0;
            };
			struct v2f
			{
                float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
                float3 posWorld : TEXCOORD1;
				float4 posScreen : TEXCOORD2;
				// SHADOW_COORDS( 2 )
            };
            
			
            v2f vert(a2v v)
            {
            	v2f o;
            	o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
            	float2 coords = float2(2.0 * v.uv.x - 1.0, 1.0 - 2.0 * v.uv.y);
            	#if UNITY_UV_STARTS_AT_TOP
            		// coords.y = 1.0 - coords.y;
            	#endif
            	o.pos = float4(coords, 0.0, 1.0);
            	// o.pos = UnityWorldToClipPos(v.vertex);
            	o.posScreen = float4(v.uv, 0.0, 1.0) ;
            	o.uv = v.uv;
				// TRANSFER_SHADOW( Out );
                return o;
            }
            
            float4 frag(v2f i) : SV_Target
            {
            	// 采样 TSM 获取 lightEnterPos（世界坐标）
            	float4 projectedPosLight = mul(_WorldToLight_VP, float4(i.posWorld, 1.0));
            	projectedPosLight.xyz /= projectedPosLight.w;
            	float2 ndcPosLight = projectedPosLight.xy * 0.5 + 0.5;
            	#if UNITY_UV_STARTS_AT_TOP
            		ndcPosLight.y = 1.0 - ndcPosLight.y;
            	#endif
            	float4 lightEnterPos = float4(tex2D(_TsmTex, ndcPosLight).xyz, 1.0);

            	// 计算 travelDist
            	float travelDist = length(lightEnterPos.xyz - i.posWorld);

            	// 将 lightEnterPos（世界坐标）转换到 Top-down Camera 空间
				lightEnterPos = mul(_WorldToTopdownCamera_VP, lightEnterPos);
            	lightEnterPos.xyz /= lightEnterPos.w;
            	lightEnterPos.xy = lightEnterPos.xy * 0.5 + 0.5;
            	#if UNITY_UV_STARTS_AT_TOP
            		lightEnterPos.y = 1.0 - lightEnterPos.y;
            	#endif
            	
            	// 将 posWorld 转换到 Topdown Camera 空间
            	float4 pos = mul(_WorldToTopdownCamera_VP, float4(i.posWorld, 1.0));
            	pos.xyz /= pos.w;
            	pos.xy = pos.xy * 0.5 + 0.5;
            	#if UNITY_UV_STARTS_AT_TOP
            		pos.y = 1.0 - pos.y;
            	#endif

            	// 在光路上采点测试，计算错误率
            	int errorCount = 0;
            	float depthCompareBias = 0.01;
            	float3 testStep = (lightEnterPos - pos) / _PenetrationTestCount;
				float3 testPos = pos;
            	for(int idx = 0; idx < _PenetrationTestCount; idx++)
            	{
            		float depth = tex2D(_TopdownDepthTex, testPos.xy).r;
            		if(depth + depthCompareBias < testPos.z)
            		{
            			errorCount++;
            		}
            		testPos += testStep;
            	}
            	float errorRate = float(errorCount) / _PenetrationTestCount;

            	// 矫正 travelDist
            	if(_OpenErrorCorrection > 0.0)
            	{
            		travelDist *= 1 - errorRate * (1.0 - _AirFalloff);
            	}

            	float4(travelDist, 0.0, 0.0, 1.0);
            	// 计算穿透辐照度
				float PenetrationWeight;
            	travelDist = clamp(travelDist, _MinPenetration, _MaxPenetration);
            	PenetrationWeight = (travelDist - _MinPenetration) / (_MaxPenetration - _MinPenetration);
            	return float4(PenetrationWeight, 0.0, 0.0, 1.0);
				float PenetrationExp = PenetrationWeight;
            	float4 DiffuseTex = tex2D( _MainTex, i.uv);
				// float3 UsedColor = _MainColor;// *( 1.0 - _DiffuseIntensity ) + DiffuseTex * _DiffuseIntensity;// Blend( _MainColor, _MainColor * DiffuseTex, _DiffuseIntensity );// *_MainColor;
				float3 DiffuseContrib = PenetrationExp * _MainColor;// DiffuseTexel;
				DiffuseContrib += DiffuseTex * _DiffuseIntensity;
	   
            	// return float4(PenetrationWeight / 2.0, 0.0, 0.0, 1.0);
            	// return float4(0.3, 0.0, 0.0, 1.0);
            	// return float4(i.posScreen);
            	return float4(DiffuseContrib.rgb, 1.0);// DiffuseTexel.a );
            }

            ENDCG
        }
	} 
	//FallBack "Diffuse"
}