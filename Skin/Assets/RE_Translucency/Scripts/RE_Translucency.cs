using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class RE_Translucency : MonoBehaviour
{
    public RenderTexture ScreenCopy;
    public RenderTexture DepthCopy;
    private Camera ReferenceCamera;
    
    private int ReferenceScreenWidth = Screen.width;
    private int ReferenceScreenHeight = Screen.height;
    // Update is called once per frame
    void Start()
    {
        //Debug.Log(" Support : " + SystemInfo.c);
    }
    void CreateColorRT(Camera Cam, int SpecificWidth, int SpecificHeight)
    {
        //if (UseGlobalTextures)
            return;

        int Width = Screen.width;
        int Height = Screen.height;
        if (Cam != null && Cam.targetTexture)
        {
            Width = Cam.targetTexture.width;
            Height = Cam.targetTexture.height;
        }
        else if (SpecificWidth != 0 && SpecificHeight != 0)
        {
            Width = SpecificWidth;
            Height = SpecificHeight;
        }

        if (!ScreenCopy || ScreenCopy.width != Width || ScreenCopy.height != Height)
        {
            ScreenCopy = new RenderTexture(Width, Height, 16);
            ReferenceCamera = Cam;
            ReferenceScreenWidth = Screen.width;
            ReferenceScreenHeight = Screen.height;
        }
    }
    void CreateDepthRT(int SpecificWidth, int SpecificHeight)
    {
        //if (UseGlobalTextures)
            return;

        int Width = Screen.width;
        int Height = Screen.height;
        if (SpecificWidth != 0 && SpecificHeight != 0)
        {
            Width = SpecificWidth;
            Height = SpecificHeight;
        }

        if (!DepthCopy || DepthCopy.width != Width || DepthCopy.height != Height)
        {
            //for (TextureFormat TF = TextureFormat.Alpha8; TF <= TextureFormat.RGBAFloat; TF++)
            //{
                //bool Supported = SystemInfo.SupportsTextureFormat(TF);
                //Debug.Log("Format " + TF.ToString() + " Supported=" + Supported);
            //}
            //RFloat works well
            DepthCopy = new RenderTexture(Width, Height, 0, RenderTextureFormat.RHalf);// ARGB32);            
        }
    }
    CameraEvent CE = CameraEvent.AfterEverything;  
    CommandBuffer TheCommandBuffer;
    string CommandBufferName = "RE Translucency";
    void AddCommandBuffer(Camera Cam)
    {
        //Make sure everything is sized correctly when changing orientation !      
        CommandBuffer[] Buffers = Cam.GetCommandBuffers(CE);
        foreach (CommandBuffer B in Buffers)
        {
            if (B.name == CommandBufferName )
                return;
        }
        
        Cam.depthTextureMode |= DepthTextureMode.Depth;

        TheCommandBuffer = new CommandBuffer();
        TheCommandBuffer.name = CommandBufferName;
        
        int ScreenCopyID = Shader.PropertyToID("_ScreenCopyTemp");
        int DepthCopyID = Shader.PropertyToID("_DepthCopyTemp");
        TheCommandBuffer.GetTemporaryRT(ScreenCopyID, -1, -1, 0, FilterMode.Bilinear);
        TheCommandBuffer.GetTemporaryRT(DepthCopyID,  -1, -1, 0, FilterMode.Bilinear);

        
        TheCommandBuffer.Blit(BuiltinRenderTextureType.CurrentActive, ScreenCopyID);

        #if UNITY_5_1_0
            //TheCommandBuffer.Blit(BuiltinRenderTextureType.Depth, DepthCopyID);
        #endif

        TheCommandBuffer.SetGlobalTexture("_ScreenCopy", ScreenCopyID);
        //TheCommandBuffer.SetGlobalTexture("_DepthCopy", DepthCopyID);

        //Graphics.copy();

       ReferenceCamera = Cam;
        Cam.AddCommandBuffer(CE, TheCommandBuffer);
    }
    /*void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        //CreateColorRT( null, (int)( src.width * Size ), (int)( src.height * Size ));
        CreateDepthRT( ScreenCopy.width, ScreenCopy.height );

        Graphics.Blit( src, dest );
        //Graphics.Blit( src, ScreenCopy);
        Graphics.Blit(ScreenCopy, DepthCopy, DownscaleDepthMaterial );

        Shader.SetGlobalTexture("_ScreenCopy", ScreenCopy );
        Shader.SetGlobalTexture("_DownscaledDepth", DepthCopy);
        Camera.current.depthTextureMode |= DepthTextureMode.Depth;
        //Shader.SetGlobalTexture("_ScreenCopy", ScreenCopy.depthBuffer );
    }*/
    // [ImageEffectOpaque]
    public void OnResolutionChange()
    {
        if (ReferenceCamera == null)
            return;

        ReferenceCamera.RemoveCommandBuffer(CE, TheCommandBuffer);
        AddCommandBuffer(ReferenceCamera);        
    }
    public void OnPreRender()
    {
        //Camera C = Camera.main;
        Camera C = this.GetComponent<Camera>();
        if (C != null)
        {
            //AddCommandBuffer(C);
            C.depthTextureMode = DepthTextureMode.Depth;

            Matrix4x4 M = Matrix4x4.identity;// transform.localToWorldMatrix;
            Matrix4x4 V = C.worldToCameraMatrix;
            Matrix4x4 P = C.projectionMatrix;
            Matrix4x4 MVP = P * V * M;
            Matrix4x4 VP = P * V;

            //MVP = Matrix4x4.identity;
            Shader.SetGlobalMatrix("_LightView", V); 
            Shader.SetGlobalMatrix("_LightViewProj", MVP );
            Shader.SetGlobalMatrix("_LightViewProjINV", MVP.inverse);
            Shader.SetGlobalMatrix("_LightProjINV", P.inverse);
        }

        if ( Screen.width != ReferenceScreenWidth || Screen.height != ReferenceScreenHeight)
        {
            OnResolutionChange();
            ReferenceScreenWidth = Screen.width;
            ReferenceScreenHeight = Screen.height;
        }
    }
    public void OnPostRender()
    {
        
    }
}