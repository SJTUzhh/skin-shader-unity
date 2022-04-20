Shader "MultiTSM/ComputeDepth"
{
    SubShader
    {
        Pass
        {
            Tags { "RenderType" = "ForwardBase" }
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct a2v
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float depth : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.depth = length(mul(UNITY_MATRIX_MV, v.vertex));
                return o;
            }

            float frag(v2f i) : SV_Target
            {
                return i.depth;
            }
            
            ENDCG
        }
    }
    Fallback "Diffuse"
}
