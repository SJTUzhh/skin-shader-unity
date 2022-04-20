using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderHelper : MonoBehaviour
{
    public Material multiTsmMaterial;
    public Material depthMaterial;
    public Material errorRateMaterial;
    public Material lightTsmMaterial;

    public Camera virtualViewCamera;
    private int textureSize = 512;

    private RenderTexture lightTsmTexture; 
    private RenderTexture virtualViewDepthTexture;
    private RenderTexture depthCorrectionTexture;
    void Start()
    {
        InitializeTextures();
        SetUniforms();
        
    }

    void InitializeTextures()
    {
        lightTsmTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.ARGBFloat);
        virtualViewDepthTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.Depth);
        depthCorrectionTexture = new RenderTexture(textureSize, textureSize, 24, RenderTextureFormat.RHalf);
    }

    void SetUniforms()
    {
        
    }

    void ComputeVirtualViewDepth()
    {
        virtualViewCamera.targetTexture = virtualViewDepthTexture;
        virtualViewCamera.RenderWithShader(depthMaterial.shader, "");
    }

    void ComputeLightTsm()
    {
        
    }

    void Update()
    {
        ComputeVirtualViewDepth();
    }
}
