using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class JadeMultiViewHelper : MonoBehaviour
{
    public Material jadeMultiViewMaterial;
    public Material depthMaterial;
    public Material tsmMaterial;
    public Material penetrationMaterial;
    public Material BlurPenetrationMaterial;
    public Material BilateralFilterMaterial;

    public GameObject tsmLight;
    public Camera topdownDepthCamera;
    private Camera tsmLightCamera;

    private RenderTexture tsmTexture;
    private RenderTexture topdownDepthTexture;
    private RenderTexture penetrationTexture;
    private RenderTexture penetrationTexture2;

    public int textureSize = 512;
    public float _ObjectGrowFactor = 0.01f;
    
    void Start()
    {
        tsmTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        topdownDepthTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.Depth);
        penetrationTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        penetrationTexture.autoGenerateMips = true;
        penetrationTexture.useMipMap = true;
        penetrationTexture2 = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);

        InitializeScene();
        
        Shader.SetGlobalTexture("_TsmTex", tsmTexture);
        Shader.SetGlobalTexture("_TopdownDepthTex", topdownDepthTexture);

        Matrix4x4 worldToTopdownCameraMatrix = topdownDepthCamera.worldToCameraMatrix;
        Matrix4x4 topdownCameraProjMatrix = GL.GetGPUProjectionMatrix(topdownDepthCamera.projectionMatrix, true);
        Shader.SetGlobalMatrix("_WorldToTopdownCamera_VP", topdownCameraProjMatrix * worldToTopdownCameraMatrix);
        
        Matrix4x4 worldToLightMatrix = tsmLightCamera.worldToCameraMatrix;
        Matrix4x4 LightCameraProjMatrix = GL.GetGPUProjectionMatrix(tsmLightCamera.projectionMatrix, true);
        Shader.SetGlobalMatrix("_WorldToLight_VP", LightCameraProjMatrix * worldToLightMatrix);
        Shader.SetGlobalVector("_TsmLightPosWorld", tsmLight.transform.position);
        Shader.SetGlobalFloat("_ObjectGrowFactor", _ObjectGrowFactor);
        Shader.SetGlobalFloat("_TextureSize", textureSize);

        jadeMultiViewMaterial.SetTexture("_PenetrationTexture", penetrationTexture);
    }
    
    void InitializeScene()
    {
        if (!tsmLight)
        {
            Debug.LogError("No light set for translucent shadow map.");
        }

        tsmLightCamera = tsmLight.GetComponent<Camera>();
        if (tsmLightCamera == null)
        {
            Debug.LogError("TSM light must have a camera attached.");
        }

        tsmLightCamera.enabled = false;
        
        if (!topdownDepthCamera)
        {
            Debug.LogError("No top-down depth camera set.");
        }
    }
    
    void Update()
    {
        // TSM
        tsmLightCamera.targetTexture = tsmTexture;
        tsmLightCamera.RenderWithShader(tsmMaterial.shader, "");
            
        // Top-down depth
        topdownDepthCamera.targetTexture = topdownDepthTexture;
        topdownDepthCamera.RenderWithShader(depthMaterial.shader, "");
        
        // Penetration
        topdownDepthCamera.targetTexture = penetrationTexture;
        topdownDepthCamera.RenderWithShader(penetrationMaterial.shader, "");
        Graphics.Blit(penetrationTexture, penetrationTexture2, BlurPenetrationMaterial);
        
        // Bilateral filter
        Graphics.Blit(penetrationTexture2, penetrationTexture, BilateralFilterMaterial);
    }
}



