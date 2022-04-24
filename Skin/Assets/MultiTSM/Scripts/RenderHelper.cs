using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RenderHelper : MonoBehaviour
{
    public Material multiTsmMaterial;
    public Material depthMaterial;
    public Material errorRateMaterial;

    public Camera virtualViewCamera;
    public int textureSize = 512;
    
    public Light tsmLight;
    private TsmLight tsmLightScript;

    private RenderTexture tsmTexture;
    private RenderTexture tsmIrradianceTexture;
    private RenderTexture virtualViewDepthTexture;
    private RenderTexture errorRateTexture;

    public float errorTestCountPerFrag = 16;
    void Start()
    {
        tsmTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        tsmIrradianceTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        virtualViewDepthTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.Depth);
        errorRateTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        
        InitializeTsmLight();
        
        SetUniforms();
    }

    void InitializeTsmLight()
    {
        if (!tsmLight)
        {
            Debug.LogError("No light set for translucent shadow map.");
        }

        tsmLightScript = tsmLight.GetComponent<TsmLight>();
        if (!tsmLightScript)
        {
            Debug.LogError("No TSM_Light script attached to TSM light.");
        }
        
        tsmLightScript.InitializeLightCamera();
        tsmLightScript.SetTsmTexture(tsmTexture);
        tsmLightScript.SetTsmIrradianceTexture(tsmIrradianceTexture);
    }

    void SetUniforms()
    {
        Shader.SetGlobalTexture("_VirtualViewDepthTex", virtualViewDepthTexture);
        Shader.SetGlobalFloat("_ErrorTestCountPerFrag", errorTestCountPerFrag);
        Shader.SetGlobalTexture("_TsmTex", tsmTexture);
        Shader.SetGlobalTexture("_TsmIrradianceTex", tsmIrradianceTexture);
        Matrix4x4 worldToLightViewProjMatrix = tsmLightScript.GetWorldToLightViewProjMatrix();
        Shader.SetGlobalMatrix("_WorldToLight_VP", worldToLightViewProjMatrix);
    }

    void Update()
    {
        ComputeTsm();
        ComputeVirtualViewDepth();
        ComputeErrorRate();
    }
    
    void ComputeTsm()
    {
       tsmLightScript.RenderTsm();
       tsmLightScript.RenderTsmIrradiance();
    }

    void ComputeVirtualViewDepth()
    {
        virtualViewCamera.targetTexture = virtualViewDepthTexture;
        virtualViewCamera.RenderWithShader(depthMaterial.shader, "");
    }

    void ComputeErrorRate()
    {
        virtualViewCamera.targetTexture = errorRateTexture;
        virtualViewCamera.RenderWithShader(errorRateMaterial.shader, "");
    }
}
