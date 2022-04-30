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

            float _ObjectGrowFactor;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 normal : NORMAL;
            };
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float depth : TEXCOORD1;
            };
            
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex + _ObjectGrowFactor * v.normal);
                o.depth = length(mul(UNITY_MATRIX_MV, v.vertex));
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                return float4(i.depth, 0, 0, 1);
            }
            
            ENDCG
        }
    }
     Fallback "Diffuse"
}
