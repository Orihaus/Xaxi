using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class DisableEmissive : MonoBehaviour 
{
	public Material[] Disable;
	
	void Update()
	{
		object[] obj = GameObject.FindObjectsOfType( typeof( GameObject ) );
		foreach( object o in obj )
		{
			GameObject g = (GameObject) o;
			
			if( g.renderer ) 
			{
				foreach( Material m in g.renderer.sharedMaterials )
				{
					foreach( Material d in Disable )
					{
						if( m == d )
						{
		 					g.renderer.castShadows = false;
							g.renderer.receiveShadows = false;
							g.isStatic = false;
						}
					}
				}
			}
		}
	}
}
