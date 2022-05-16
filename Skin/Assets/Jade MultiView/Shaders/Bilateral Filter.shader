Shader "Jade MultiView/Bilateral Filter"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // #pragma target 5.0

            #include "UnityCG.cginc"

            // SamplerState sampler_MainTex;
            // Texture2D<float4> _MainTex;
            sampler2D _MainTex;
            float4 _BackgroundColor;
            float _TextureSize;

            struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				// half2 uv[9] : TEXCOORD0;
			};

            #define SIGMA 10.0
			#define BSIGMA 0.1
			#define MSIZE 3

			float normpdf(float x, float sigma)
			{
				return 0.39894 * exp(-0.5 * x * x / (sigma*sigma)) / sigma;
			}

			float normpdf3(float3 v, float sigma)
			{
				return 0.39894 * exp(-0.5 * dot(v,v) / (sigma*sigma)) / sigma;
			}

			v2f vert(a2v v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				// half2 uv = v.tex;

				// float _TexelSize = 1.0 / _TextureSize * 1;
				// o.uv[0] = uv + _TexelSize * half2(-1, -1);
				// o.uv[1] = uv + _TexelSize * half2(0, -1);
				// o.uv[2] = uv + _TexelSize * half2(1, -1);
				// o.uv[3] = uv + _TexelSize * half2(-1, 0);
				// o.uv[4] = uv + _TexelSize * half2(0, 0);
				// o.uv[5] = uv + _TexelSize * half2(1, 0);
				// o.uv[6] = uv + _TexelSize * half2(-1, 1);
				// o.uv[7] = uv + _TexelSize * half2(0, 1);
				// o.uv[8] = uv + _TexelSize * half2(1, 1);
				
				return o;
			}

            float4 frag(v2f vs_in) : SV_Target
            {
				// _MainTex.Gather(sampler_MainTex, i.uv);
            	float4 color = tex2D(_MainTex, vs_in.uv);
            	const int kSize = (MSIZE-1)/2;
				float kernel[MSIZE];
				float3 final = 0.0;
				
				// create the 1-D kernel
				float totalWeight = 0.0;
				for (int j = 0; j <= kSize; ++j)
				{
					kernel[kSize+j] = kernel[kSize-j] = normpdf(float(j / _TextureSize), SIGMA);
				}
            	
				float bZ = 1.0 / normpdf(0.0, BSIGMA);
				// read out the texels
            	if(color.w < 0.5) color.xyz = float3(0.9, 0.9, 0.9);
            	bool background = true;
				for (int i = -kSize; i <= kSize; ++i)
				{
					for (int j = -kSize; j <= kSize; ++j)
					{
						float2 neighbourUv = vs_in.uv + float2(i, j) / _TextureSize;
						float4 neighbourColor = tex2D(_MainTex, neighbourUv);
						if(neighbourColor.w < 0.5f) continue;
						background = false;
						float weight = normpdf3(neighbourColor.xyz - color.xyz, BSIGMA)*bZ*kernel[kSize+j]*kernel[kSize+i];
						totalWeight += weight;
						final += weight * neighbourColor.xyz;
					}
				}
            	if(background) return float4(0.95, 0.95, 0.95, 1.0);
            	return float4(final / totalWeight, 1.0);
            }
            
            ENDCG
        }
    }
}
