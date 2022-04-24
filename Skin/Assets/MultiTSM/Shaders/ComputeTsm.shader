Shader "MultiTSM/ComputeTsm"
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

			struct a2v
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 posWorld : TEXCOORD0;
				float depth : TEXCOORD1;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = UnityWorldToClipPos(float4(o.posWorld, 1.0));
				o.depth = length(UnityObjectToViewPos(v.vertex));

				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				return float4(i.posWorld, i.depth);
			}
			ENDCG
		}
	}
}
