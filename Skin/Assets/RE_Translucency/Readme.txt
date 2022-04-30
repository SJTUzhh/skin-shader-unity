

Jade ( Subsurface scattering / Translucency ) shader


HOW TO INTEGRATE :
1)Create a new camera for each ansamble of objects that will receive the Jade effect ( depending on scene positioning it can be 1 camera per object, or 1 camera for all objects )
2)Attach RE_Translucency.cs script to the camera from 1)
3)Create new materials for the objects that will receive the translucency effect
4)For those new materials, select the RE/Jade shader
5)Choose according MinDist/MaxDist values for your object. Check for shader parameter significance bellow

PARAMETERS:
MinDist - The minimum scatter distance. From 0 to MinDist the pixels will mostly be lit by ambient lighting. Light Scattering happens between MinDist and MaxDist, so in order to get the best results you'll need to fine tune this value
MaxDist - The maximum scatter distance. From MinDist to MaxDist the pixels will blend between ambient lighting and MainColor. From MaxDist onwards the pixels will equal MainColor.
AmbientMin - minmum ambient light. In order to get the best results, fine tune this value to be near average ambient lighting
AmbientFactor - how much ambient light. In order to get the best results, fine tune this value so the object does not appear too dark or too bright compared to the environment.
Reverse - Right now the effect looks best when the TranslucencyCamera is behind the object, however, a bright light behind a jade object will actually make it bright around edges, not dark.
In order to have the expected behavior or being brighter near edges, turn this to 1.

KNOWN ISSUES:
- no shadows yet, stay tuned, an update will fix that

GOT A QUESTION ?
Just let me know at relativegames7@gmail.com and we'll work it out.
