using UnityEngine;
using System.Collections;

public class AIMove : MonoBehaviour 
{
	public float RotateSpeed = 2.0f;
	public float MoveSpeed = 0.1f;
	public Transform Target;
	public Vector3 Offset;
	public float AvoidFoV = 45.0f;
	public float AvoidDistance = 1.0f;
	public float PreferedHeight = 0.5f;
	public float PlayerVisDistance = 10.0f;
	public bool LockYRotation = true;
	public bool LookAway = false;
	public float ThinkRate = 1.0f;
	public float StopDistance = 0.5f;
	public Vector3 ForwardDirection = Vector3.forward;
	
	private RaycastHit hit;
	
	void Start() 
	{
	    StartCoroutine( Think() );
	}
	
	public void Turn( Vector3 targetDir, bool AllowLockY = false, float speedMult = 1.0f  )
	{
		if( LockYRotation && AllowLockY ) targetDir.y = 0.0f;
		
	    Quaternion targetRotation = Quaternion.LookRotation ( targetDir, Vector3.up );
	    Quaternion offsetRotation = targetRotation;
	    offsetRotation.eulerAngles += Offset;
	   	transform.rotation = Quaternion.Slerp( transform.rotation, offsetRotation, Time.deltaTime * RotateSpeed * speedMult );
	}
	
	bool RayTest( Vector3 rayDirection, float distance )
	{
	    if( Physics.Raycast( transform.position, rayDirection, distance ) ) 
			return false;
		
		return true;
	}
	
	float DistanceTest( Vector3 rayDirection )
	{
		RaycastHit hit;
	    if( Physics.Raycast( transform.position, rayDirection, out hit, 1000.0f ) ) 
			return hit.distance;
		
		return 1000.0f;
	}
	
	IEnumerator Think()
	{
		while( true ) 
		{ 
			yield return new WaitForSeconds( ThinkRate );
			
			//print ( Vector3.Angle( transform.position, startPos ) );
			/*float favorRight = ( Vector3.Distance( startPos, transform.position ) / 20.0f ) * 0.5f;
			if( AngleTest( 60.0f ) < AngleTest( -60.0f ) ) print ( "test");
			
			float ty = 60.0f;
			if( Random.value < 0.5f ) ty = -60.0f;
			Random.seed++;
			
			Turn( new Vector3( 0.0f, ty, 0.0f ) );*/
		}
	}
	
	void FixedUpdate() 
	{
		float forwardMoveScale = 1.0f;
		Vector3 fwd = transform.TransformDirection( ForwardDirection );
		float forwardHitDistance = DistanceTest( fwd );
		if( forwardHitDistance < StopDistance ) 
		{ 
			forwardMoveScale *= forwardHitDistance / StopDistance;
			Vector3 up = transform.TransformDirection( Vector3.left );
			Turn( up, false, 8.0f );
		}
		
		//Vector3 down = transform.TransformDirection( Vector3.down );
		//float downHitDistance = DistanceTest( down );
		//if( downHitDistance > PreferedHeight ) Turn( down, false, 0.25f );
		
		if( Target != null ) 
		{
			Vector3 TurnDir = Target.position - transform.position;
			if( LookAway ) TurnDir = -TurnDir;
			Turn( TurnDir, true, 1.0f );
		}
		
		transform.Translate( ForwardDirection * MoveSpeed * Time.deltaTime * forwardMoveScale );
	}
}