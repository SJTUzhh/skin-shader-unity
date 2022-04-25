using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class RenderHelper : MonoBehaviour
{
    public Material multiTsmMaterial;
    public Material depthMaterial;
    public Material errorRateMaterial;

    public Camera virtualCamera;
    public int textureSize = 512;
    
    public Light tsmLight;
    private TsmLight tsmLightScript;

    private RenderTexture tsmTexture;
    private RenderTexture tsmIrradianceTexture;
    private RenderTexture virtualViewDepthTexture;
    private RenderTexture errorRateTexture;

    public float errorTestCountPerFrag = 16;
    public float objectGrowFactor = 0.1f;
    void Start()
    {
        tsmTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        tsmIrradianceTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        virtualViewDepthTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.Depth);
        errorRateTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        errorRateTexture.autoGenerateMips = true;
        errorRateTexture.useMipMap = true;
        
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
        Shader.SetGlobalTexture("_TsmTex", tsmTexture);
        Shader.SetGlobalTexture("_TsmIrradianceTex", tsmIrradianceTexture);
        Shader.SetGlobalTexture("_ErrorRateTex", errorRateTexture);
        Shader.SetGlobalFloat("_ErrorTestCountPerFrag", errorTestCountPerFrag);
        Shader.SetGlobalMatrix("_WorldToLight_VP", tsmLightScript.GetWorldToLightViewProjMatrix());

        Matrix4x4 worldToVirtCamViewMatrix = virtualCamera.worldToCameraMatrix;
        Matrix4x4 virtCamProj = GL.GetGPUProjectionMatrix(virtualCamera.projectionMatrix, true);
        Matrix4x4 worldToVirtCamViewProjMatrix = virtCamProj * worldToVirtCamViewMatrix;
        Shader.SetGlobalMatrix("_WorldToVirtualCam_VP", worldToVirtCamViewProjMatrix);
        
        Shader.SetGlobalVector("_TsmLightPosWorld", tsmLight.transform.position);
        Shader.SetGlobalFloat("_ObjectGrowFactor", objectGrowFactor);
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
        virtualCamera.targetTexture = virtualViewDepthTexture;
        virtualCamera.RenderWithShader(depthMaterial.shader, "");
    }

    void ComputeErrorRate()
    {
        virtualCamera.targetTexture = errorRateTexture;
        virtualCamera.RenderWithShader(errorRateMaterial.shader, "");
    }
}
