Shader "Jade MultiView/ComputeTsm"
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

			float _ObjectGrowFactor = 0.0;
			uniform float4 _TsmLightPosWorld;

			struct a2v
			{
				float4 vertex : POSITION;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 posWorld : TEXCOORD0;
				float nDotL : TEXCOORD1;
			};

			v2f vert(a2v v)
			{
				v2f o;
				o.posWorld = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.pos = UnityObjectToClipPos(v.vertex + _ObjectGrowFactor * v.normal);
				float4 L = normalize(float4(_TsmLightPosWorld.xyz, 1.0) - float4(o.posWorld, 1.0));
				o.nDotL = max(0, dot(v.normal, -L));
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				return float4(i.posWorld, i.nDotL);
			}
			ENDCG
		}
	}
}