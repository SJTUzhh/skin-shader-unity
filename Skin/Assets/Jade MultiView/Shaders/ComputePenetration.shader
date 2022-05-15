Shader "Jade MultiView/ComputePenetration"
{
	
	
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Autolight.cginc"

		uniform float _TextureSize;
		uniform sampler2D _MainTex;
		uniform sampler2D _TsmTex;
		uniform sampler2D _TopdownDepthTex;
	
		uniform float4 _MainColor;
		uniform float _DiffuseIntensity;
	
		uniform float _MinPenetration;
		uniform float _MaxPenetration;
		uniform int _Reverse;
	
        uniform float4x4 _WorldToLight_VP;
        uniform float4x4 _WorldToTopdownCamera_VP;
        uniform float4 _TsmLightPosWorld;

        uniform float _PenetrationTestCount;
        uniform float _OpenErrorCorrection;
        uniform float _AirFalloff;
		uniform float _PenetrationMipLevel;

		/* #define _TSM_SAMPLE_COUNT 5
        static const half weight[5][5] = {{0.0030,0.0133,0.0219,0.0133,0.0030},
									  {0.0133,0.0596,0.0983,0.0596,0.0133},
									  {0.0219,0.0983,0.1621,0.0983,0.0219},
									  {0.0133,0.0596,0.0983,0.0596,0.0133},
									  {0.0030,0.0133,0.0219,0.0133,0.0030}};
		*/
	
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
        
        float4 frag(v2f In) : SV_Target
        {
            // 采样 TSM 获取 lightEnterPos（世界坐标）
            float4 projectedPosLight = mul(_WorldToLight_VP, float4(In.posWorld, 1.0));
            projectedPosLight.xyz /= projectedPosLight.w;
            float2 ndcPosLight = projectedPosLight.xy * 0.5 + 0.5;
            #if UNITY_UV_STARTS_AT_TOP
            	ndcPosLight.y = 1.0 - ndcPosLight.y;
            #endif
        	float4 tsmTap = tex2D(_TsmTex, ndcPosLight);
            float4 lightEnterPos = float4(tsmTap.xyz, 1.0);
        	float tsmNDotL = tsmTap.w;
            
			// 过滤获得平均 travelDist
            float travelDist = 0.0;
            /*for(int i = 0; i < _TSM_SAMPLE_COUNT; i++)
            {
            	for(int j = 0; j < _TSM_SAMPLE_COUNT; j++)
            	{
            		float2 offset = float2(i - _TSM_SAMPLE_COUNT / 2, j - _TSM_SAMPLE_COUNT / 2);
            		float2 sampleUv = ndcPosLight + offset * 1.0 / _TextureSize * 2;
            		float4 tap = tex2D(_TsmTex, sampleUv);
            		float4 neighborLightEnterPos = float4(tap.xyz, 1.0);
            		float tapTravelDist = length(neighborLightEnterPos.xyz - In.posWorld);
            		travelDist += tapTravelDist * tap.w * weight[i][j];
            	}
            }*/

            // 计算 travelDist
            travelDist = length(lightEnterPos.xyz - In.posWorld);

            // 将 lightEnterPos（世界坐标）转换到 Top-down Camera 空间
			lightEnterPos = mul(_WorldToTopdownCamera_VP, lightEnterPos);
            lightEnterPos.xyz /= lightEnterPos.w;
            lightEnterPos.xy = lightEnterPos.xy * 0.5 + 0.5;
            #if UNITY_UV_STARTS_AT_TOP
            	lightEnterPos.y = 1.0 - lightEnterPos.y;
            #endif
            
            // 将 posWorld 转换到 Topdown Camera 空间
            float4 pos = mul(_WorldToTopdownCamera_VP, float4(In.posWorld, 1.0));
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

            return float4(travelDist, errorRate, tsmNDotL, 1.0);

            // 矫正 travelDist
            if(_OpenErrorCorrection > 0.0)
            {
            	travelDist *= 1 - errorRate * (1.0 - _AirFalloff);
            }
            
            // 计算穿透辐照度
			float PenetrationWeight;
            travelDist = clamp(travelDist, _MinPenetration, _MaxPenetration);
            PenetrationWeight = (travelDist - _MinPenetration) / (_MaxPenetration - _MinPenetration);
            return float4(PenetrationWeight, 0.0, 0.0, 1.0);
        }

		

			
	
	ENDCG
	
    SubShader
	{
		Pass 
		{
			Cull Off
			Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            ENDCG
        }

	}
	FallBack Off
}