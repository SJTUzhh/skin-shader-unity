using UnityEngine;
using System.Collections;
using UnityEngine.UI;
public class FPS_Translucency : MonoBehaviour {

    Text TextC;
	// Use this for initialization
	void Start ()
    {
        TextC = this.gameObject.GetComponent<Text>();
        Application.targetFrameRate = 0;
	}
    int Frames = 0;
    float TimePassed = 0;
	// Update is called once per frame
	void Update () {
        TimePassed += Time.deltaTime;
        if (TimePassed > 1.0f)
        {
            TextC.text = "FPS " + Frames;

            TimePassed = 0;
            Frames = 0;            
        }
        Frames++;	
	}
}
