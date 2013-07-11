
using UnityEngine;
using System.Collections;

public class DetectTarget : MonoBehaviour 
{
	public float MaxDetectDistance = 4.0f;
	public float FieldOfView = 45.0f;
	public float SearchCooldownRate = 5.0f;
	public float SearchRate = 0.1f;
	public Vector3 ForwardDirection = Vector3.forward;
	public float IntrestDistance = 1.0f;
	public float IntrestCooldownRate = 5.0f;
	
	public Transform Home;
	public float LostDistance = 5.0f;
	
	private bool Targeted = false;
	private float SearchCooldown = 0.0f;
	private int CurrentTargetIntrest = 0;
	private Transform CurrentTarget;

	AIMove move;
	  
	void Start() 
	{
		move = GetComponent<AIMove>();
	    StartCoroutine( SearchForTarget() );
	}
	
	public void Targetify( Transform Target, int Intrest )
	{
		print ( "DetectTarget: Found Target" );
		
		Targeted = true;
		CurrentTargetIntrest = Intrest;
		
		move.Target = Target;
		CurrentTarget = Target;
		
		SearchCooldown = SearchCooldownRate * Intrest;
	}
	
	private void LostTarget( )
	{
		print ( "DetectTarget: Lost Target" );
		
		Targeted = false;
		CurrentTargetIntrest = 0;

		CurrentTarget = null;
		move.Target = null;
		
	    StartCoroutine( SearchForTarget() );
	}
	
	private int CanSeeIntrestingThing( Transform Target )
	{
	    RaycastHit hit;
		
		float distance = Vector3.Distance( Target.transform.position, transform.position );
		if( distance > MaxDetectDistance ) return 0;
		
	    Vector3 rayDirection = Target.transform.position - transform.position;
	    if( ( Vector3.Angle( rayDirection, ForwardDirection ) ) > FieldOfView ) return 0;
		
	    if( Physics.Raycast( transform.position, rayDirection, out hit ) ) 
		{
	    	if( hit.transform != Target.transform ) return 0;
		} else return 0;
		
		int intrest = 1;
		if( distance < IntrestDistance ) intrest++;
		if( Target.tag == "Player" ) intrest+=4;
		
	    return intrest;
	}
	
	IEnumerator SearchForTarget()
	{
		while( !Targeted ) 
		{ 
			//GameObject[] p = GameObject.FindGameObjectsWithTag( "Player" );
			//GameObject[] rits = new GameObject[ p.GetLength( 0 )];
			//p.CopyTo( rits, 0 );
	
			//int intrest = 0;
			//Transform mostIntresting = GameObject.FindGameObjectsWithTag( "Player" )[0].transform;
			
			//foreach( GameObject rit in rits ) 
			//{
				//int currentIntrest = CanSeeIntrestingThing( mostIntresting.transform );
				//if( currentIntrest > intrest ) { mostIntresting = rit.transform; intrest = currentIntrest; }
			//}
			
			GameObject Player = GameObject.FindGameObjectsWithTag( "Player" )[0];
			if( CanSeeIntrestingThing( Player.transform ) > 0 ) Targetify( Player.transform, 5 );
			
			yield return new WaitForSeconds( SearchRate );
		}
	}
	
	void FixedUpdate( ) 
	{
		if( Home != CurrentTarget )
			if( Vector3.Distance( Home.position, transform.position ) > LostDistance && CurrentTargetIntrest < 2 )
				Targetify( Home, 1 ); 
	
		if( Targeted )
		{
			SearchCooldown -= Time.deltaTime;
			if( SearchCooldown < 0.0f ) LostTarget();
		} 
	}
}
