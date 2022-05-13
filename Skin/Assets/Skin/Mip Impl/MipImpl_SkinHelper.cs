using UnityEngine;
using System.Collections;


[ExecuteInEditMode]
public class MipImpl_SkinHelper : MonoBehaviour
{
	public Material skinMaterial;
	public Material beckmannMaterial;
	public Material attenuationMaterial;
	// public Material stretchMaterial;
	public Material irradianceMaterial;
	public Material gaussianMaterial;
	// public Material gaussianUMaterial;
	// public Material gaussianVMaterial;
	// public Material alphaMaskMaterial;
	public Material shadowMaterial;
	public Material applyShadowsMaterial;

	public Light tsmLight;
	private TsmLight lightCameraScript;

	private Camera dummyCamera;
	private int textureSize;

	private RenderTexture beckmannTexture;
	private RenderTexture attenuationTexture;
	private RenderTexture tsmTexture;
	// private RenderTexture alphaTexture;
	private RenderTexture tempRenderTexture;

	private RenderTexture irradianceTexture;
	private RenderTexture blur2Texture;
	private RenderTexture blur3Texture;
	private RenderTexture blur4Texture;
	private RenderTexture blur5Texture;
	private RenderTexture blur6Texture;

	// private RenderTexture stretchTexture;
	// private RenderTexture blur2StretchTexture;
	// private RenderTexture blur3StretchTexture;
	// private RenderTexture blur4StretchTexture;
	// private RenderTexture blur5StretchTexture;
	// private RenderTexture blur6StretchTexture;

	private RenderTexture shadowTexture;
	private RenderTexture irradiance2Texture;

	public bool applyShadows = true;

	private string[] gaussionWvNames = new string[] { "_Blur1WV", "_Blur2WV", "_Blur3WV", "_Blur4WV", "_Blur5WV", "_Blur6WV"};
	private int mipLevelCount;
	private float[][] gaussiansMipBlendWeights;
	private float[] mipBlendWeightsForShadows;
	
	void Start()
	{
		InitializeTextures();

		if (!tsmLight)
		{
			Debug.LogError("No light set for translucent shadow map.");
		}

		lightCameraScript = tsmLight.GetComponent<TsmLight>();
		if (!lightCameraScript)
		{
			Debug.LogError("No TSM_Light script attached to TSM light.");
		}
		lightCameraScript.InitializeLightCamera();
		lightCameraScript.SetTsmTexture(tsmTexture);

		// Create a dummy camera. This will be used for calling RenderWithShader with a 
		// specific clear color, without having to change the main camera
		dummyCamera = GetComponent<Camera>();
		if (!dummyCamera)
		{
			dummyCamera = gameObject.AddComponent<Camera>();
		}

		Graphics.Blit(beckmannTexture, beckmannTexture, beckmannMaterial);
		Graphics.Blit(attenuationTexture, attenuationTexture, attenuationMaterial);

		// 计算各个高斯核的 Mip 混合权重
		float blurStepScale = skinMaterial.GetFloat("_BlurStepScale");
		blurStepScale /= 0.4f; // stretch-correction map 对采样步长的影响是：平均乘以0.4
		blurStepScale *= blurStepScale;
		mipLevelCount = applyShadows ? irradiance2Texture.mipmapCount : irradianceTexture.mipmapCount;
		gaussiansMipBlendWeights = new float[gaussionWvNames.Length][];
		for(int currGaussionIdx = 0; currGaussionIdx < gaussionWvNames.Length; currGaussionIdx++)
		{
			float variance = skinMaterial.GetVector(gaussionWvNames[currGaussionIdx]).w;
			gaussiansMipBlendWeights[currGaussionIdx] = GaussianMipBlendWeights(variance / blurStepScale, mipLevelCount);
		}
		mipBlendWeightsForShadows = GaussianMipBlendWeights(1 / blurStepScale, mipLevelCount);
		
		SetUniforms();
	}

	void InitializeTextures()
	{
		textureSize = skinMaterial.GetTexture("_MainTex").width;

		beckmannTexture = new RenderTexture(512, 512, 24, RenderTextureFormat.R8);
		attenuationTexture = new RenderTexture(512, 512, 24, RenderTextureFormat.R8);
		tsmTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
		// alphaTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.R8);
		tempRenderTexture = new RenderTexture(textureSize, textureSize, 24);
		irradianceTexture = new RenderTexture(textureSize, textureSize, 24);
		
		irradianceTexture.useMipMap = true;
		irradianceTexture.autoGenerateMips = true;
		
		if (applyShadows)
		{
			shadowTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.R8);
			irradiance2Texture = new RenderTexture(textureSize, textureSize, 24);
			shadowTexture.useMipMap = true;
			shadowTexture.autoGenerateMips = true;
			irradiance2Texture.useMipMap = true;
			irradiance2Texture.autoGenerateMips = true;
		}

		blur2Texture = new RenderTexture(textureSize, textureSize, 24);
		blur3Texture = new RenderTexture(textureSize, textureSize, 24);
		blur4Texture = new RenderTexture(textureSize, textureSize, 24);
		blur5Texture = new RenderTexture(textureSize, textureSize, 24);
		blur6Texture = new RenderTexture(textureSize, textureSize, 24);

		// stretchTexture = new RenderTexture(textureSize, textureSize, 24);
		// blur2StretchTexture = new RenderTexture(textureSize, textureSize, 24);
		// blur3StretchTexture = new RenderTexture(textureSize, textureSize, 24);
		// blur4StretchTexture = new RenderTexture(textureSize, textureSize, 24);
		// blur5StretchTexture = new RenderTexture(textureSize, textureSize, 24);
		// blur6StretchTexture = new RenderTexture(textureSize, textureSize, 24);
	}

	/// <summary>
	/// 为给定的高斯核计算 Mipmap 混合权重
	/// </summary>
	/// <param name="variance"> 高斯核的方差 </param>
	/// <param name="mipLevelCount"> Mipmap 层级数目 </param>
	/// <returns> 所有 Mipmap 层级的混合权重 </returns>
	float[] GaussianMipBlendWeights(float variance, int mipLevelCount)
	{
		float[] mipBlendWeights = new float[mipLevelCount];
		for (int currMipLevel = 0; currMipLevel < mipLevelCount; currMipLevel++)
		{
			// 计算当前 Mip 层级的混合权重
			float c = 2.0f * Mathf.PI * variance;
			float numerator = (1 << (currMipLevel << 2)) * Mathf.Log(4.0f);
			float denominator = c * ((1 << (currMipLevel << 1)) + c);
			mipBlendWeights[currMipLevel] = Mathf.Clamp(numerator / denominator, 0.0f, 1.0f);
		}
		return mipBlendWeights;
	}

	void SetUniforms()
	{
		skinMaterial.SetTexture("_BeckmannTex", beckmannTexture);
		skinMaterial.SetTexture("_IrradianceTex", applyShadows ? irradiance2Texture : irradianceTexture);
		skinMaterial.SetTexture("_AttenuationTex", attenuationTexture);
		skinMaterial.SetTexture("_Blur2Tex", blur2Texture);
		skinMaterial.SetTexture("_Blur3Tex", blur3Texture);
		skinMaterial.SetTexture("_Blur4Tex", blur4Texture);
		skinMaterial.SetTexture("_Blur5Tex", blur5Texture);
		skinMaterial.SetTexture("_Blur6Tex", blur6Texture);
		// skinMaterial.SetTexture("_StretchTex", stretchTexture);
		// skinMaterial.SetTexture("_Blur6StretchTex", blur6StretchTexture);
		// skinMaterial.SetTexture("_AlphaMaskTex", alphaTexture);
		skinMaterial.SetFloat("_TextureSize", textureSize);
		// skinMaterial.SetFloat("_StretchScale", 0.001f);
		skinMaterial.SetMatrix("_LightViewProj", lightCameraScript.GetWorldToLightViewProjMatrix());

		// gaussianUMaterial.SetFloat("_TextureSize", textureSize);
		// gaussianVMaterial.SetFloat("_TextureSize", textureSize);
		
		// alphaMaskMaterial.SetTexture("_StretchTex", stretchTexture);
		// alphaMaskMaterial.SetTexture("_Blur2StretchTex", blur2StretchTexture);
		// alphaMaskMaterial.SetTexture("_Blur3StretchTex", blur3StretchTexture);
		// alphaMaskMaterial.SetTexture("_Blur4StretchTex", blur4StretchTexture);
		// alphaMaskMaterial.SetTexture("_Blur5StretchTex", blur5StretchTexture);
		// alphaMaskMaterial.SetTexture("_Blur6StretchTex", blur6StretchTexture);
	}

	RenderTexture ComputeShadows()
	{		
		if (applyShadows)
		{
			// Compute texture space shadow map from the TSM to apply shadows to the irradiance texture
			dummyCamera.targetTexture = shadowTexture;
			dummyCamera.RenderWithShader(shadowMaterial.shader, "");
			
			GaussianBlur(mipBlendWeightsForShadows, shadowTexture, tempRenderTexture);

			// gaussianMaterial.SetFloatArray("_MipBlendWeights", mipBlendWeightsForShadows);
			// gaussianMaterial.SetInt("_MipCount", mipBlendWeightsForShadows.Length);
			// Graphics.Blit(shadowTexture, tempRenderTexture, gaussianMaterial);
			// Graphics.Blit(tempRenderTexture, shadowTexture);
			//tempRenderTexture.Release();
			
			// gaussianUMaterial.SetFloat("_GaussianWidth", 1.0f);
			// gaussianVMaterial.SetFloat("_GaussianWidth", 1.0f);
			// gaussianUMaterial.SetTexture("_StretchTex", null);
			// Graphics.Blit(shadowTexture, tempGaussianTexture, gaussianUMaterial);
			// gaussianVMaterial.SetTexture("_StretchTex", null);
			// Graphics.Blit(tempGaussianTexture, shadowTexture, gaussianVMaterial);

			// Apply shadows to irradiance texture
			applyShadowsMaterial.SetTexture("_ShadowTex", tempRenderTexture);
			applyShadowsMaterial.SetTexture("_DiffuseTex", skinMaterial.GetTexture("_MainTex"));
			applyShadowsMaterial.SetFloat("_Mix", skinMaterial.GetFloat("_Mix"));
			Graphics.Blit(irradianceTexture, irradiance2Texture, applyShadowsMaterial);

			return irradiance2Texture;
		}

		return irradianceTexture;
	}

	void Update()
	{
		// Setup dummy camera
		dummyCamera.CopyFrom(Camera.main);
		dummyCamera.enabled = false;
		dummyCamera.backgroundColor = new Color(0.0f, 0.0f, 0.0f, 0.0f); 

		// Compute TSM
		lightCameraScript.RenderTsm();
		skinMaterial.SetTexture("_TSMTex", tsmTexture);

		// Compute diffuse irradiance
		Vector3 lightPos = tsmLight.transform.position;
		Vector4 tsmLightWorldPos = new Vector4(lightPos.x, lightPos.y, lightPos.z, 1.0f);
		skinMaterial.SetVector("_TsmLightPosWorld", tsmLightWorldPos);
		dummyCamera.targetTexture = irradianceTexture;
		dummyCamera.RenderWithShader(irradianceMaterial.shader, "");

		//  Set uniforms for the gaussian convolution materials
		// float blurStepScale = skinMaterial.GetFloat("_BlurStepScale");
		// gaussianUMaterial.SetFloat("_BlurStepScale", blurStepScale);
		// gaussianVMaterial.SetFloat("_BlurStepScale", blurStepScale);

		// Apply shadows, if enabled
		RenderTexture finalIrradianceTexture = ComputeShadows();

		// Compute stretch textures
		// dummyCamera.targetTexture = stretchTexture;
		// dummyCamera.RenderWithShader(stretchMaterial.shader, "");

		// Compute convolutions. Since the first convolution kernel is very narrow, 
		// we can use the irradiance texture as the first convolution
		// GaussianBlur(gaussiansMipBlendWeights[0] , finalIrradianceTexture, finalIrradianceTexture);
		GaussianBlur(gaussiansMipBlendWeights[1] , finalIrradianceTexture, blur2Texture);
		GaussianBlur(gaussiansMipBlendWeights[2], finalIrradianceTexture, blur3Texture);
		GaussianBlur(gaussiansMipBlendWeights[3], finalIrradianceTexture, blur4Texture);
		GaussianBlur(gaussiansMipBlendWeights[4], finalIrradianceTexture, blur5Texture);
		GaussianBlur(gaussiansMipBlendWeights[5], finalIrradianceTexture, blur6Texture);
		
		// GaussianBlur(variance2 - variance1, finalIrradianceTexture, blur2Texture, stretchTexture, blur2StretchTexture);
		// float variance3 = skinMaterial.GetVector("_Blur3WV").w;
		// GaussianBlur(variance3 - variance2, blur2Texture, blur3Texture, blur2StretchTexture, blur3StretchTexture);
		// float variance4 = skinMaterial.GetVector("_Blur4WV").w;
		// GaussianBlur(variance4 - variance3, blur3Texture, blur4Texture, blur3StretchTexture, blur4StretchTexture);
		// float variance5 = skinMaterial.GetVector("_Blur5WV").w;
		// GaussianBlur(variance5 - variance4, blur4Texture, blur5Texture, blur4StretchTexture, blur5StretchTexture);
		// float variance6 = skinMaterial.GetVector("_Blur6WV").w;
		// GaussianBlur(variance6 - variance5, blur5Texture, blur6Texture, blur5StretchTexture, blur6StretchTexture);
		//
		// // Compute alpha mask used to remove seams caused by connected areas being disconnected in texture space
		// Graphics.Blit(alphaTexture, alphaTexture, alphaMaskMaterial);
	}
	
	void GaussianBlur(float[] mipBlendweights, RenderTexture source, RenderTexture destination)
	{
		gaussianMaterial.SetFloatArray("_MipBlendWeights", mipBlendweights);
		// gaussianMaterial.SetInt("_MipCount", mipBlendweights.Length);
		Graphics.Blit(source, destination, gaussianMaterial);
		
		// // The gaussian width is the standard deviation (square root of the variance)
		// float width = Mathf.Sqrt(variance);
		// gaussianUMaterial.SetFloat("_GaussianWidth", width);
		// gaussianVMaterial.SetFloat("_GaussianWidth", width);
		//
		// // Blur stretch texture
		// gaussianUMaterial.SetTexture("_StretchTex", null); // No stretch, default = white texture
		// Graphics.Blit(sourceStretch, tempGaussianTexture, gaussianUMaterial);
		// gaussianVMaterial.SetTexture("_StretchTex", null); // No stretch, default = white texture
		// Graphics.Blit(tempGaussianTexture, destinationStretch, gaussianVMaterial);
		//
		// // Blur source texture
		// gaussianUMaterial.SetTexture("_StretchTex", destinationStretch);
		// Graphics.Blit(source, tempGaussianTexture, gaussianUMaterial);
		// gaussianVMaterial.SetTexture("_StretchTex", destinationStretch);
		// Graphics.Blit(tempGaussianTexture, destination, gaussianVMaterial);
	}
}
