using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class TsmLight : MonoBehaviour
{
	// (向光点(world).x, 向光点(world).y, 向光点(world).z, 向光点(light).length)
	private RenderTexture tsmTexture;
	public Material tsmMaterial;

	// 向光点颜色
	private RenderTexture tsmIrradianceTexture;
	public Material tsmIrradianceMaterial;

	// TODO: Create camera during runtime
	private Camera lightCamera;

	public void InitializeLightCamera()
	{
		lightCamera = GetComponentInChildren<Camera>();
		if (lightCamera == null)
		{
			Debug.LogError("TSM light must have a camera attached.");
		}
		lightCamera.enabled = false;
	}

	public void RenderTsm ()
	{
		lightCamera.targetTexture = tsmTexture;
		lightCamera.RenderWithShader(tsmMaterial.shader, "");
	}

	public void RenderTsmIrradiance()
	{
		lightCamera.targetTexture = tsmIrradianceTexture;
		lightCamera.RenderWithShader(tsmIrradianceMaterial.shader, "");
	}

	public Matrix4x4 GetWorldToLightViewMatrix()
	{
		return lightCamera.worldToCameraMatrix;
	}

	Matrix4x4 GetLightProjectionMatrix()
	{
		Matrix4x4 projection = lightCamera.projectionMatrix;
		projection = GL.GetGPUProjectionMatrix(projection, true);

		return projection;
	}
	
	public Matrix4x4 GetWorldToLightViewProjMatrix()
	{
		Matrix4x4 view = GetWorldToLightViewMatrix();
		Matrix4x4 projection = GetLightProjectionMatrix();
		Matrix4x4 light_VP = projection * view;
		return light_VP;
	}

	public void SetTsmTexture(RenderTexture tsmTex)
	{
		tsmTexture = tsmTex;
	}
	
	public void SetTsmIrradianceTexture(RenderTexture tsmIrradianceTex)
	{
		tsmIrradianceTexture = tsmIrradianceTex;
	}
}
