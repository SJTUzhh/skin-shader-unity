Shader "MultiTSM/ComputeTsmIrradiance"
{
    SubShader
    {
	    Pass
		{
			Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float _ObjectGrowFactor;

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 tex : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 tex : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 lightDir : TEXCOORD2;
			};

			v2f vert(a2v v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex + v.normal * _ObjectGrowFactor);
				o.tex = v.tex;
				o.worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
				float3 posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.lightDir = normalize(UnityWorldSpaceLightDir(posWorld));

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float nDotL = dot(i.worldNormal, i.lightDir);
				float3 albedo = tex2D(_MainTex, i.tex).rgb;
				float3 diffuse = max(0.0, nDotL) * _LightColor0.rgb;
				// float3 diffuse = (nDotL * 0.5 + 0.5) * _LightColor0.rgb;
				float3 final = diffuse * albedo;
				return float4(final.x, final.y, final.z, 1.0);
			}
			ENDCG
		}
	}
}
