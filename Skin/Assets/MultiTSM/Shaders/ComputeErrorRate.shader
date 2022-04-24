Shader "MultiTSM/ComputeErrorRate"
{
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            sampler2D _VirtualViewDepthTex;
            sampler2D _TsmTex;
            float _ErrorTestCountPerFrag;
            float4x4 _WorldToLight_VP;
            
            struct a2v
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 posWorld : TEXCOORD0;
                float3 posScreen : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.pos = UnityWorldToClipPos(o.posWorld);
                float4 posScreen = ComputeScreenPos(o.pos);
                o.posScreen = (posScreen / posScreen.w).xyz;
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                // 求 TSM 的 uv
                float4 posLightClip = mul(_WorldToLight_VP, float4(i.posWorld, 1.0));
                float2 posLightNdc_xy = posLightClip.xy / posLightClip.w;
                posLightNdc_xy = posLightNdc_xy * 0.5 + 0.5;
                #if UNITY_UV_STARTS_AT_TOP
					posLightNdc_xy.y = 1.0 - posLightNdc_xy.y;
				#endif

                // 采样 TSM，并将 tsmTap 转换至屏幕坐标系
                float4 tsmTap = tex2D(_TsmTex, posLightNdc_xy);
                float4 tsmTapPosClip = UnityWorldToClipPos(float4(tsmTap.x, tsmTap.y, tsmTap.z, 1.0));
                float4 tsmTapPosScreen = ComputeScreenPos(tsmTapPosClip);
                tsmTapPosScreen = tsmTapPosScreen / tsmTapPosScreen.w;
                
                int errorCount = 0;
                half bias = 0.001;
                float3 toTapStep = (tsmTapPosScreen.xyz - i.posScreen.xyz) / _ErrorTestCountPerFrag;
                float3 testPos = i.posScreen.xyz;
                
                for(int idx = 0; idx < _ErrorTestCountPerFrag; idx++)
                {
                    float2 testUv = testPos.xy;
                    #if UNITY_UV_STARTS_AT_TOP
					    testUv.y = 1.0 - testUv.y;
				    #endif 
                    float testDepth = tex2D(_VirtualViewDepthTex, testUv.xy);
                    if(testDepth == 0.0)
                    {
                        errorCount++;
                    }
                    testPos += toTapStep;
                }

                return float4(float(errorCount) / _ErrorTestCountPerFrag, 0.0, 0.0, 1.0);
                // return float4(i.posScreen.xyz, 1.0);
                // return float4(tsmTapPosScreen.xyz, 1.0);
                // return float4(tsmTap.x, tsmTap.y, tsmTap.z, 1.0);
                // return float4(posLightNdc_xy, 0.0, 1.0);
                // return float4(i.posWorld, 1.0);
                // return float4(posLightClip);
                // return float4(posLight);
            }
            
            ENDCG
        }
    }
}
