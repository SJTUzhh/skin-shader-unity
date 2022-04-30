#ifndef SUBSURFACE_SCATTERING_COLOR_MASK_CGINC
#define SUBSURFACE_SCATTERING_COLOR_MASK_CGINC


struct appdata 
{
    float4 vertex : POSITION;
    half4 color : COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f 
{
    fixed4 color : COLOR0;
    #if USING_FOG
        fixed fog : TEXCOORD0;
    #endif

    float4 pos : SV_POSITION;
    UNITY_VERTEX_OUTPUT_STEREO
};


v2f vert (appdata IN) 
{
    v2f o;
    UNITY_SETUP_INSTANCE_ID(IN);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


//Curved World
#if defined(CURVEDWORLD_IS_INSTALLED) && !defined(CURVEDWORLD_DISABLED_ON)
      CURVEDWORLD_TRANSFORM_VERTEX(IN.vertex)
#endif


    half4 color = IN.color;
    float3 eyePos = UnityObjectToViewPos(float4(IN.vertex.xyz,1)).xyz;
    half3 viewDir = 0.0;
    o.color = saturate(color);
    // compute texture coordinates
    // fog
    #if USING_FOG
        float fogCoord = length(eyePos.xyz); // radial fog distance
        UNITY_CALC_FOG_FACTOR_RAW(fogCoord);
        o.fog = saturate(unityFogFactor);
    #endif
    
    o.pos = UnityObjectToClipPos(IN.vertex);
    return o;
}

fixed4 frag (v2f IN) : SV_Target 
{
    fixed4 col;
    col = IN.color;
    
    #if USING_FOG
        col.rgb = lerp (unity_FogColor.rgb, col.rgb, IN.fog);
    #endif
    
    return col;   
}

#endif