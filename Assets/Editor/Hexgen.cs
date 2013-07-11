using UnityEditor;
using UnityEngine;
using System.Collections.Generic;

[ExecuteInEditMode]
public class Hexgen : MonoBehaviour
{
	public float offsetScale = 0.0f;
	public float heightScale = 0.0f;
	public float heightStep = 2.0f;
	public float scale = 10.0f;
	public int tiers = 3;
	public int seed = 451;
	public int sizeX = 20;
	public int sizeZ = 20;
	public GameObject Hexfab;
	
	public void Build()
	{
		print( "Deleting Old..." );
		
		var children = new List<GameObject>();
		foreach( Transform child in transform ) children.Add( child.gameObject );
		children.ForEach( child => DestroyImmediate( child ) );
		
		print( "Building..." );
		int x = (int)( Random.value * offsetScale ), z = (int)( Random.value * offsetScale );
		while( x < sizeX - (int)( Random.value * offsetScale ) )
		{
			while( z < sizeZ - (int)( Random.value * offsetScale ) )
			{
				Random.seed = seed * x * z;
				float sx = ( 0.875f * z + x * 1.75f ) * scale, sy = Random.value * heightScale, sz = z * 0.5f * scale;
				
				Random.seed = (int)( Random.value * seed );
				for( int i = 0; i < tiers; i++ ) 
					SpawnHex( sx, sy + i * heightStep, sz );
				
				z++;
			}
			z = z = (int)( Random.value * offsetScale );
			x++;
		}
	}
	
	void SpawnHex( float xoff, float yoff, float zoff )
	{
		Vector3 pos = transform.position;
		pos.x += xoff;
		pos.y += yoff;
		pos.z += zoff;
		GameObject hex = (GameObject)Instantiate( Hexfab, pos, transform.rotation );
		hex.transform.parent = transform;	
	}
	
	void Update()
	{
		if( Application.isEditor ) Build();
	}
}