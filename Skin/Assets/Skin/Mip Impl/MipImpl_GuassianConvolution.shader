Shader "Skin/MipImpl_GuassianConvolution"
{
    Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
	}
	SubShader 
	{
		Pass
		{
			CGPROGRAM

			#include "UnityCG.cginc"

			#pragma vertex vert
			#pragma fragment frag
			#define MAX_MIP_COUNT 12
			
			sampler2D _MainTex;
			float _MipBlendWeights[MAX_MIP_COUNT];
			// int _MipCount;
			
			struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			  
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			v2f vert(a2v v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv.xy;
				return o;
			}

			float4 frag(v2f i) : SV_Target 
			{
				// return tex2Dlod(_MainTex, float4(i.uv, 0., 0));
				float4 upperSample = tex2Dlod(_MainTex, float4(i.uv, 0., MAX_MIP_COUNT - 1));
				
				for(int mipLevelIdx = MAX_MIP_COUNT - 2; mipLevelIdx >= 0; mipLevelIdx--)
				{
					upperSample = (1 - _MipBlendWeights[mipLevelIdx]) * upperSample +
						_MipBlendWeights[mipLevelIdx] * tex2Dlod(_MainTex, float4(i.uv, 0., mipLevelIdx));
				}
				return upperSample;
			}

			ENDCG
		}
		
	} 
	FallBack "Diffuse"
}
