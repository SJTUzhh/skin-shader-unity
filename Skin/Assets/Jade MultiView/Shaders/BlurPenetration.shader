Shader "Jade MultiView/BlurPenetration"
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "Black" {}
		_OpenErrorCorrection ("Open Penetration Error Correction", Range(-1, 1)) = 1
		_AirFalloff("Air Falloff Rate Compared to Jade", Range(0.0, 1.0)) = 0.5
		_PenetrationMipLevel("Penetration Map Mipmap Level", Range(0.0, 11.0)) = 0.0
		_Reverse( "Reverse", int ) = 0
		_MinPenetration("Minimum Penetration", float) = 0.01
		_MaxPenetration( "Maxmum Penetration", float) = 0.9
		_BackgroundColor("BackgroundColor", float) = 0.5
	}
	
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Autolight.cginc"

		sampler2D _MainTex;
        uniform float _OpenErrorCorrection;
        uniform float _AirFalloff;
		uniform float _PenetrationMipLevel;
		uniform float _MinPenetration;
		uniform float _MaxPenetration;
		uniform int _Reverse;
		uniform float _BackgroundColor;
	
		struct v2f
		{
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		v2f vert(appdata_img v)
        {
	        v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv = v.texcoord.xy;
			return o;
        }

		float4 frag(v2f In) : SV_Target
        {
        	float4 tap = tex2D(_MainTex, In.uv);
        	float travelDist = tap.r;
	        float errorRate = tex2Dlod(_MainTex, float4(In.uv, 0.0, _PenetrationMipLevel)).g;
        	float tsmNDotL = tap.b;

        	if(tap.w < 0.5) return float4(_BackgroundColor, _BackgroundColor, _BackgroundColor, 0.0);

        	// travelDist *= travelDist;
        	
        	// 矫正 travelDist
            if(_OpenErrorCorrection > 0.0)
            {
            	travelDist *= 1 - errorRate * (1.0 - _AirFalloff);
            }
            
            // 计算穿透辐照度
			float penetrationWeight;
            travelDist = clamp(travelDist, _MinPenetration, _MaxPenetration);
            penetrationWeight = (travelDist - _MinPenetration) / (_MaxPenetration - _MinPenetration);
            
			if (_Reverse)
			{
				penetrationWeight = 1.0 - penetrationWeight;
			}

        	// penetrationWeight *= tsmNDotL;

        	return float4(penetrationWeight, penetrationWeight, penetrationWeight, 1.0);
        }

	ENDCG
    
	SubShader
	{
		Pass
		{
			CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            
            ENDCG
		}
	}
    FallBack Off
}
