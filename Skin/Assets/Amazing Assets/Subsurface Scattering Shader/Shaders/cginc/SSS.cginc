#ifndef SUBSURFACE_SCATTERING_SHADER_CGINC
#define SUBSURFACE_SCATTERING_SHADER_CGINC

//////////////////////////////////////////////////////////////////////////////
//                                                                          // 
//Variables                                                                 //                
//                                                                          //               
//////////////////////////////////////////////////////////////////////////////
fixed4 _Color;
sampler2D _MainTex;

#ifdef _SSS_VERTEXLIT
	float4 _MainTex_ST;
#endif

#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON
	sampler2D _SSS_TranslucencyMap;
	fixed4 _SSS_TranslucencyColor;
	half _SSS_TranslucencyBackfaceIntensity;
#endif


#ifdef _SSS_BUMPED
	half _BumpSize;
	sampler2D _BumpMap;
#endif

#ifdef _SSS_SPECULAR
	half _Shininess;
#endif

#ifdef _SSS_REFLECTIVE
	fixed4 _ReflectColor;
	samplerCUBE _Cube;
#endif

half _SSS_TranslucencyDistortion;
half _SSS_TranslucencyPower;
half _SSS_TranslucencyScale;

half _SSS_DirectionalLightStrength;
half _SSS_NonDirectionalLightStrength;
half _SSS_LightAttenuation;
half _SSS_NormalizeLightVector;
half _SSS_Emission;

#ifdef _SSS_FRESNEL_ON
	fixed4 _SSS_FresnelColor;
	fixed _SSS_FresnelPower;
#endif

#ifdef _SSS_TESSELLATION	
	float _SSS_DisplacementStrength;
	sampler2D _SSS_DisplacementMap;
	float4 _SSS_DisplacementMap_ST;

	#ifdef _SSS_TESSELLATION_DISTANCE_BASED
		float _SSS_Tessellation;
		float _SSS_Tessellation_MinDistance;
		float _SSS_Tessellation_MaxDistance;
	#endif

	#ifdef _SSS_TESSELLATION_LENGTH_BASED
		float _SSS_Tessellation_EdgeLength;
	#endif
#endif

//////////////////////////////////////////////////////////////////////////////
//                                                                          // 
//Structs                                                                   //                
//                                                                          //               
//////////////////////////////////////////////////////////////////////////////
#ifdef _SSS_VERTEXLIT
	struct v2f_surf 
	{
		half4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;				

		#ifndef LIGHTMAP_OFF
			float2 lmap : TEXCOORD1;
		#else
			fixed3 vlight : TEXCOORD1;
		#endif
		
		#ifdef _SSS_FRESNEL_ON
			fixed3 rim : TEXCOORD2;
		#endif

		UNITY_FOG_COORDS(3)
	};
#endif

#ifdef _SSS_TESSELLATION
	struct appdata 
	{
		float4 vertex : POSITION;
        float4 tangent : TANGENT;
        float3 normal : NORMAL;
        float2 texcoord : TEXCOORD0;
	};
#endif

struct TransSurfaceOutput
{
	fixed3 Albedo;
	fixed3 Normal;
	fixed3 Emission;
	half Specular;
	fixed Gloss;
	fixed Alpha;
	fixed3 TransCol;
};

struct Input
{
	float2 uv_MainTex;

	#ifdef _SSS_FRESNEL_ON
		 float3 viewDir;
	#endif

	#ifdef _SSS_REFLECTIVE
		float3 worldRefl;
	#endif

	#if defined(_SSS_BUMPED) && defined(_SSS_REFLECTIVE)
		INTERNAL_DATA
	#endif
};

//////////////////////////////////////////////////////////////////////////////
//                                                                          // 
//Functions                                                                  //                
//                                                                          //               
//////////////////////////////////////////////////////////////////////////////
#ifdef _SSS_VERTEXLIT
inline half3 V_Shade4PointLights ( half4 lightPosX, half4 lightPosY, half4 lightPosZ,
								   half3 lightColor0, half3 lightColor1, half3 lightColor2, half3 lightColor3,
								   half4 lightAttenSq,
								   half3 pos, half3 normal, half3 viewDir)
{
	// to light vectors
	half4 toLightX = lightPosX - pos.x;
	half4 toLightY = lightPosY - pos.y;
	half4 toLightZ = lightPosZ - pos.z;
	// squared lengths
	half4 lengthSq = 0;
	lengthSq += toLightX * toLightX;
	lengthSq += toLightY * toLightY;
	lengthSq += toLightZ * toLightZ;
	// NdotL
	half4 ndotl = 0;
	ndotl += toLightX * normal.x;
	ndotl += toLightY * normal.y;
	ndotl += toLightZ * normal.z;
	// correct NdotL
	half4 corr = rsqrt(lengthSq);
	ndotl = ndotl * corr;
	ndotl = lerp(ndotl, max(half4(0,0,0,0), ndotl), _SSS_NormalizeLightVector);

	// attenuation
	half4 atten = 1.0 / (1.0 + lengthSq * lightAttenSq);
		
	half3 diffCol = 0;
	half3 distortionNormal = normal * _SSS_TranslucencyDistortion;

	
	#ifdef _SSS_VERTEX_LIGHT_COUNT_ONE
		half3 transLight0 = normalize(half3(toLightX[0], toLightY[0], toLightZ[0])) + distortionNormal;
		
		half transDot0 = saturate(dot(viewDir, -transLight0));
		transDot0 = pow(transDot0, _SSS_TranslucencyPower);

		lightColor0 *= 2;
		#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON
			half3 lightAtten = lightColor0 * atten[0] * _SSS_NonDirectionalLightStrength;
			half3 transComponent = lerp(transDot0 + _Color.rgb, _SSS_TranslucencyColor * _SSS_TranslucencyScale, transDot0);	
			transComponent += (1 - ndotl[0]) * _SSS_TranslucencyColor * lightColor0 * _SSS_TranslucencyBackfaceIntensity * 0.5;

			diffCol += lightColor0 * atten[0] * ndotl[0] + lightAtten * transComponent;
		#else
			diffCol += lightColor0 * atten[0] * ((transDot0 * _SSS_TranslucencyScale + _Color.rgb) * _SSS_NonDirectionalLightStrength + ndotl[0]);
		#endif
	#endif

	#ifdef _SSS_VERTEX_LIGHT_COUNT_TWO
		half3 transLight1 = normalize(half3(toLightX[1], toLightY[1], toLightZ[1])) + distortionNormal;
		
		half transDot1 = saturate(dot(viewDir, -transLight1));
		transDot1 = pow(transDot1, _SSS_TranslucencyPower);

		lightColor1 *= 2;
		#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON			 
			lightAtten = lightColor1 * atten[1] * _SSS_NonDirectionalLightStrength;
			transComponent = lerp(transDot1 + _Color.rgb, _SSS_TranslucencyColor * _SSS_TranslucencyScale, transDot1);	
			transComponent += (1 - ndotl[1]) * _SSS_TranslucencyColor * lightColor1 * _SSS_TranslucencyBackfaceIntensity * 0.5;

			diffCol += lightColor1 * atten[1] * ndotl[1] + lightAtten * transComponent;
		#else
			diffCol += lightColor1 * atten[1] * ((transDot1 * _SSS_TranslucencyScale + _Color.rgb) * _SSS_NonDirectionalLightStrength + ndotl[1]);
		#endif
	#endif

	#ifdef _SSS_VERTEX_LIGHT_COUNT_THREE
		half3 transLight2 = normalize(half3(toLightX[2], toLightY[2], toLightZ[2])) + distortionNormal;
		
		half transDot2 = saturate(dot(viewDir, -transLight2));
		transDot2 = pow(transDot2, _SSS_TranslucencyPower);

		lightColor2 *= 2;
		#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON			 
			lightAtten = lightColor2 * atten[2] * _SSS_NonDirectionalLightStrength;
			transComponent = lerp(transDot2 + _Color.rgb, _SSS_TranslucencyColor * _SSS_TranslucencyScale, transDot2);	
			transComponent += (1 - ndotl[2]) * _SSS_TranslucencyColor * lightColor2 * _SSS_TranslucencyBackfaceIntensity * 0.5;

			diffCol += lightColor2 * atten[2] * ndotl[2] + lightAtten * transComponent;
		#else
			diffCol += lightColor2 * atten[2] * ((transDot2 * _SSS_TranslucencyScale+ _Color.rgb) * _SSS_NonDirectionalLightStrength + ndotl[2]);
		#endif
	#endif

	#ifdef _SSS_VERTEX_LIGHT_COUNT_FOUR
		half3 transLight3 = normalize(half3(toLightX[3], toLightY[3], toLightZ[3])) + distortionNormal;
		
		half transDot3 = saturate(dot(viewDir, -transLight3));
		transDot3 = pow(transDot3, _SSS_TranslucencyPower);

		lightColor3 *= 2;
		#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON			 
			lightAtten = lightColor3 * atten[3] * _SSS_NonDirectionalLightStrength;
			transComponent = lerp(transDot3 + _Color.rgb, _SSS_TranslucencyColor * _SSS_TranslucencyScale, transDot3);	
			transComponent += (1 - ndotl[3]) * _SSS_TranslucencyColor * lightColor3 * _SSS_TranslucencyBackfaceIntensity * 0.5;

			diffCol += lightColor3 * atten[3] * ndotl[3] + lightAtten * transComponent;
		#else
			diffCol += lightColor3 * atten[3] * ((transDot3 * _SSS_TranslucencyScale + _Color.rgb) * _SSS_NonDirectionalLightStrength + ndotl[3]);
		#endif
	#endif

	return diffCol;
}
#endif

#ifdef _SSS_TESSELLATION
float4 tessCalc (appdata v0, appdata v1, appdata v2) 
{
	#if defined(_SSS_TESSELLATION_DISTANCE_BASED)
		return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, _SSS_Tessellation_MinDistance, _SSS_Tessellation_MaxDistance, _SSS_Tessellation);
	#elif defined(_SSS_TESSELLATION_LENGTH_BASED)
		return UnityEdgeLengthBasedTessCull (v0.vertex, v1.vertex, v2.vertex, _SSS_Tessellation_EdgeLength, 1);
	#else
		return float4(0, 0, 0, 0);
	#endif
}

void disp (inout appdata v)
{
//Curved World
#if defined(CURVEDWORLD_IS_INSTALLED) && !defined(CURVEDWORLD_DISABLED_ON)
   #ifdef CURVEDWORLD_NORMAL_TRANSFORMATION_ON
      CURVEDWORLD_TRANSFORM_VERTEX_AND_NORMAL(v.vertex, v.normal, v.tangent)
   #else
      CURVEDWORLD_TRANSFORM_VERTEX(v.vertex)
   #endif
#endif

	float d = tex2Dlod(_SSS_DisplacementMap, float4(v.texcoord.xy * _SSS_DisplacementMap_ST.xy + _SSS_DisplacementMap_ST.zw, 0, 0)).r * _SSS_DisplacementStrength;
	v.vertex.xyz += v.normal * d;
}
#endif


#ifndef _SSS_VERTEXLIT
void vert(inout appdata_full v, out Input o)
{
	UNITY_INITIALIZE_OUTPUT(Input, o);


//Curved World
#if defined(CURVEDWORLD_IS_INSTALLED) && !defined(CURVEDWORLD_DISABLED_ON)
   #ifdef CURVEDWORLD_NORMAL_TRANSFORMATION_ON
      CURVEDWORLD_TRANSFORM_VERTEX_AND_NORMAL(v.vertex, v.normal, v.tangent)
   #else
      CURVEDWORLD_TRANSFORM_VERTEX(v.vertex)
   #endif
#endif


}
#endif
//////////////////////////////////////////////////////////////////////////////
//                                                                          // 
//Lighting                                                                  //                
//                                                                          //               
//////////////////////////////////////////////////////////////////////////////
#ifndef _SSS_VERTEXLIT
	inline fixed4 LightingTransBlinnPhong (TransSurfaceOutput s, fixed3 lightDir, half3 viewDir, fixed atten)
	{	
		half atten2 = atten * _SSS_LightAttenuation;

		fixed3 diffCol;
		fixed3 specCol;
		float spec;	
	
		half NL = dot (s.Normal, lightDir);
		NL = lerp(NL, max(0.0, NL), _SSS_NormalizeLightVector);

		half3 h = normalize (lightDir + viewDir);
	
		float nh = max (0, dot (s.Normal, h));
		spec = pow (nh, s.Specular*128.0) * s.Gloss;
	
		diffCol = (s.Albedo * _LightColor0.rgb * NL) * atten2;
		specCol = (_LightColor0.rgb * _SpecColor.rgb * spec) * atten2;

		half3 transLight = lightDir + s.Normal * _SSS_TranslucencyDistortion;
		float VinvL = saturate(dot(viewDir, -transLight));
	
		float transDot = pow(VinvL,_SSS_TranslucencyPower);
		#ifndef _SSS_ADVANCED_TRANSLUCENCY_ON
			transDot *= _SSS_TranslucencyScale;
		#endif 

		half3 lightAtten = _LightColor0.rgb * atten2;
		#ifdef UNITY_PASS_FORWARDBASE
			lightAtten *= _SSS_DirectionalLightStrength;
		#else
			lightAtten *= _SSS_NonDirectionalLightStrength;
		#endif

		half3 transComponent = (transDot + _Color.rgb);
		#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON	
			half3 subSurfaceComponent = s.TransCol * _SSS_TranslucencyScale;	
			transComponent = lerp(transComponent, subSurfaceComponent, transDot);		

			transComponent += (1 - NL) * s.TransCol * _LightColor0.rgb * _SSS_TranslucencyBackfaceIntensity;
		#endif

		diffCol = s.Albedo * (_LightColor0.rgb * atten2 * NL + lightAtten * transComponent);

	
		fixed4 c;
		c.rgb = diffCol + specCol * 2;
		c.a = s.Alpha;// +_LightColor0.a * _SpecColor.a * spec * atten;
		return c;
	}

	inline fixed4 LightingTransPhong (TransSurfaceOutput s, fixed3 lightDir, half3 viewDir, fixed atten)
	{	
		half atten2 = atten * _SSS_LightAttenuation;

		fixed3 diffCol = fixed3(0, 0, 0);
	
		half NL = dot(s.Normal, lightDir);
		NL = lerp(NL, max(0.0, NL), _SSS_NormalizeLightVector);
	
		half3 transLight = lightDir + s.Normal * _SSS_TranslucencyDistortion;
		float VinvL = saturate(dot(viewDir, -transLight));

		float transDot = pow(VinvL,_SSS_TranslucencyPower);
		#ifndef _SSS_ADVANCED_TRANSLUCENCY_ON
			transDot *= _SSS_TranslucencyScale;
		#endif 
	
		half3 lightAtten = _LightColor0.rgb * atten2;
		#ifdef UNITY_PASS_FORWARDBASE
			lightAtten *= _SSS_DirectionalLightStrength;
		#else
			lightAtten *= _SSS_NonDirectionalLightStrength;
		#endif

		half3 transComponent = (transDot + _Color.rgb);
		#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON	
			half3 subSurfaceComponent = s.TransCol * _SSS_TranslucencyScale;	
			transComponent = lerp(transComponent, subSurfaceComponent, transDot);		

			transComponent += (1 - NL) * s.TransCol * _LightColor0.rgb * _SSS_TranslucencyBackfaceIntensity;
		#endif	

		diffCol = s.Albedo * (_LightColor0.rgb * atten2 * NL + lightAtten * transComponent);
	
		fixed4 c; 
		c.rgb = diffCol;
		c.a = s.Alpha;// +_LightColor0.a * atten;
		return c;
	}

	void surf (Input IN, inout TransSurfaceOutput o)
	{
		half4 tex = tex2D(_MainTex, IN.uv_MainTex);
		o.Albedo = tex.rgb * _Color.rgb;
		o.Alpha = tex.a * _Color.a;

		#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON
			o.TransCol = tex2D(_SSS_TranslucencyMap,IN.uv_MainTex).rgb * _SSS_TranslucencyColor.rgb;
		#endif

		#ifdef _SSS_SPECULAR
			o.Gloss = tex.a;
			o.Specular = _Shininess;
		#endif

		#ifdef _SSS_BUMPED
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			o.Normal.x *= _BumpSize;
			o.Normal.y *= _BumpSize;
			o.Normal = normalize(o.Normal);
		#endif

		#ifdef _SSS_REFLECTIVE
			#ifdef _SSS_BUMPED
				float3 worldRefl = WorldReflectionVector (IN, o.Normal);
				fixed4 reflcol = texCUBE (_Cube, worldRefl);
			#else
				fixed4 reflcol = texCUBE (_Cube, IN.worldRefl);
			#endif

			reflcol *= tex.a;
			o.Emission = reflcol.rgb * _ReflectColor.rgb;
		#endif

	
		o.Emission += o.Albedo * _SSS_Emission * o.Alpha;


		#ifdef _SSS_FRESNEL_ON
			half rim = 1.0 - saturate(dot (Unity_SafeNormalize(IN.viewDir), o.Normal));
			o.Emission += _SSS_FresnelColor.rgb * pow (rim, _SSS_FresnelPower);
		#endif


	}
#endif

#ifdef _SSS_VERTEXLIT
	v2f_surf vert(appdata_full v) 
	{
		v2f_surf o;


//Curved World
#if defined(CURVEDWORLD_IS_INSTALLED) && !defined(CURVEDWORLD_DISABLED_ON)
   #ifdef CURVEDWORLD_NORMAL_TRANSFORMATION_ON
      CURVEDWORLD_TRANSFORM_VERTEX_AND_NORMAL(v.vertex, v.normal, v.tangent)
   #else
      CURVEDWORLD_TRANSFORM_VERTEX(v.vertex)
   #endif
#endif


		o.pos = UnityObjectToClipPos (v.vertex);
		o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);

		half3 worldN = mul((half3x3)unity_ObjectToWorld, SCALED_NORMAL);
 
		#ifdef LIGHTMAP_OFF
			#ifndef _SSS_AMBIENT_LIGHTS_ON
				o.vlight = 0;
			#else
				o.vlight = UNITY_LIGHTMODEL_AMBIENT.rgb;
			#endif

			half3 viewDir = normalize(WorldSpaceViewDir( v.vertex ));
				

			//Directional Light
			#ifdef USING_DIRECTIONAL_LIGHT

				half NL = dot(worldN, _WorldSpaceLightPos0.xyz);
				NL = lerp(NL, max(0.0, NL), _SSS_NormalizeLightVector);
			
				half3 transLight_Dir = _WorldSpaceLightPos0.xyz + (worldN * _SSS_TranslucencyDistortion);
				half transDot_Dir = saturate(dot(viewDir, -transLight_Dir));
				transDot_Dir = pow(transDot_Dir, _SSS_TranslucencyPower);

				#ifdef _SSS_ADVANCED_TRANSLUCENCY_ON
				
					half3 lightAtten = _LightColor0.rgb * _SSS_DirectionalLightStrength;
					half3 transComponent = lerp(transDot_Dir + _Color.rgb, _SSS_TranslucencyColor * _SSS_TranslucencyScale, transDot_Dir);	
					transComponent += (1 - NL) * _SSS_TranslucencyColor * _LightColor0.rgb * _SSS_TranslucencyBackfaceIntensity;

					o.vlight += _LightColor0.rgb * NL * 2 + lightAtten * transComponent * 2;
				#else
					o.vlight += (_LightColor0.rgb * ((transDot_Dir * _SSS_TranslucencyScale + _Color.rgb) * _SSS_DirectionalLightStrength + max(0, dot(worldN, _WorldSpaceLightPos0.xyz)))) * 2;
				#endif
			#endif
			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


			#ifdef VERTEXLIGHT_ON
				half3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
	 
			
				o.vlight += V_Shade4PointLights (unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
												 unity_LightColor[0].rgb, unity_LightColor[1].rgb, unity_LightColor[2].rgb, unity_LightColor[3].rgb,
												 unity_4LightAtten0, worldPos, worldN, viewDir );			
			#endif
		#endif //LIGHTMAP_OFF

		#ifndef LIGHTMAP_OFF
			o.lmap.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
		#endif

		#ifdef _SSS_FRESNEL_ON
			half3 objSpaceCameraPos = mul(unity_WorldToObject, half4(_WorldSpaceCameraPos.xyz, 1)).xyz;
				
			half rim = 1.0 - saturate(dot (normalize(objSpaceCameraPos - v.vertex.xyz), v.normal));
			o.rim = _SSS_FresnelColor.rgb * rim * rim;
		#endif


		UNITY_TRANSFER_FOG(o,o.pos);

		return o;
	}

	fixed4 frag (v2f_surf IN) : SV_Target 
	{
		half4 albedo = tex2D(_MainTex, IN.uv.xy) * _Color;

		fixed4 retColor = albedo;
		#ifndef LIGHTMAP_OFF		
			retColor.rgb *= DecodeLightmap (UNITY_SAMPLE_TEX2D(unity_Lightmap, IN.lmap.xy));
		#else
			retColor.rgb *= IN.vlight;
		#endif

		retColor.rgb += albedo.rgb * _SSS_Emission * albedo.a; 

		#ifdef _SSS_FRESNEL_ON
			retColor.rgb += IN.rim; 
		#endif

	
		// apply fog
		UNITY_APPLY_FOG(IN.fogCoord, retColor);

		return retColor;
	}
#endif

#endif	//cginc
