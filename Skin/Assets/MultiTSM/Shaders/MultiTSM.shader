Shader "MultiTSM/MultiTSM"
{
    Properties
    {
        _MainTex ("Diffuse Texture", 2D) = "white" {}	
        _Specular ("Specular Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
        _ScatteringRate ("Scattering Rate", Range(0.0, 10.0)) = 0.3
        _ErrorRateMipLevel ("Error Rate Mip Level", Range(1.0, 10.0)) = 1
        _UseErrorRateCorrection ("Use Error Rate Correction", Range(-1.0, 1.0)) = 1.0
    }
        SubShader
    {
        Tags { "LightMode" = "ForwardBase" }

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            sampler2D _TsmTex;
            sampler2D _TsmIrradianceTex;
            sampler2D _ErrorRateTex;
            float4x4 _WorldToLight_VP;
            float4x4 _WorldToVirtualCam_VP;
            float4 _TsmLightPosWorld;
            float4 _Specular;
            float _Gloss;
            float _ScatteringRate;
            float _ErrorRateMipLevel;
            float _UseErrorRateCorrection;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 tex : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 posWorld : TEXCOORD0;
                float2 tex : TEXCOORD1;
                float3 worldNormal : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                
                o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = UnityWorldToClipPos(float4(o.posWorld, 1.0));
                o.tex = v.tex;
                o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                
                return  o;
            }
            
            float2 getCameraSpaceUv(float4 pos, float4x4 toCamera_VP)
            {
                float4 posCilp = mul(toCamera_VP, pos);
                float2 posNdc_xy = (posCilp / posCilp.w).xy;
                posNdc_xy = posNdc_xy * 0.5 + 0.5;
                return posNdc_xy;
            }

            float4 frag(v2f i) : SV_Target
            {
                // Direct color
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.posWorld));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.posWorld));
                float3 halfDir = normalize(lightDir + viewDir);
                float3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(i.worldNormal, halfDir)), _Gloss);
                float nDotL = dot(i.worldNormal, lightDir);
				float3 albedo = tex2D(_MainTex, i.tex).rgb;
				float3 diffuse = max(0.0, nDotL) * _LightColor0.rgb * albedo;
				float3 directColor = diffuse + specular;

                // Get the TSM tap uv
                float2 tsmTapUv = getCameraSpaceUv(float4(i.posWorld, 1.0), _WorldToLight_VP);
                // For DX11 renderTexture
                #if UNITY_UV_STARTS_AT_TOP
                    tsmTapUv.y = 1.0 - tsmTapUv.y;
                #endif
                
                // Thickness
                float tsmTapDepthToLight = tex2D(_TsmTex, tsmTapUv).w;
                float depthToLight = length(_TsmLightPosWorld - i.posWorld);
                float thickness = depthToLight - tsmTapDepthToLight;

                // Error rate
                float2 errorRateTapUv = getCameraSpaceUv(float4(i.posWorld, 1.0), _WorldToVirtualCam_VP);
                #if UNITY_UV_STARTS_AT_TOP
                    errorRateTapUv.y = 1.0 - errorRateTapUv.y;
                #endif
                float errorRate = tex2Dlod(_ErrorRateTex, float4(errorRateTapUv, 0.0, _ErrorRateMipLevel));

                // Corrected thickness
                if(_UseErrorRateCorrection > 0.0)
                {
                    thickness *= (1 - errorRate);
                }
                // thickness *= 0.01;
                // Set a large distance for surface points facing the light
                thickness = nDotL > 0.0 ? 500.0 : thickness;

                // Translucent color
                float3 translucentColor = tex2D(_TsmIrradianceTex, tsmTapUv).xyz;
                translucentColor *= exp(-1.0 * _ScatteringRate * thickness);

                float3 final = translucentColor + directColor;
                
                return float4(final, 1.0);
                return float4(errorRate, 0.0, 0.0, 1.0);
                // return float4(tsmTapDepthToLight, 0.0, 0.0, 1.0);
                // return float4(_LightColor0);
                return float4(_WorldSpaceLightPos0);
                return float4(errorRateTapUv, 0.0, 1.0);
                return float4(tsmTapUv, 0.0, 1.0);  
                return float4(thickness, 0.0, 0.0, 1.0);
                return float4(translucentColor, 1.0);
                return float4(errorRate, 0.0, 0.0, 1.0);
            }
            
            ENDCG
        }
    }
}
