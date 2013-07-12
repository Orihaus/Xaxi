Shader "Base_Cutout" 
{
	Properties  
	{
		_DiffuseAmount ( "Diffuse Amount", Range( 0.0, 1.0 ) ) = 0.0
		_TexAmount ( "Texture Amount", Range( 0.0, 1.0 ) ) = 0.0
		_MainMap ( "Main Texture", 2D ) = "main" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	}
	    
	SubShader 
	{
        Tags
        {
          "Queue"="Transparent" 
          "IgnoreProjector"="False"
          "RenderType"="Transparent"
        }

        Cull Off
        ZWrite On
        ZTest LEqual

		CGPROGRAM
		#pragma target 3.0 
		#pragma surface surf Lambert alpha
		
		struct Input 
		{
			float2 uv_MainMap;
		};
	
 		sampler2D _MainMap;

		fixed _TexAmount;
		fixed _DiffuseAmount;
		
		float _Cutoff;

		void surf( Input IN, inout SurfaceOutput o ) 
		{
			float4 main = lerp( tex2D( _MainMap, IN.uv_MainMap ), 1.0, _TexAmount );
			
			o.Albedo = ( main * _DiffuseAmount );
			//o.Emission = emitFresnel * _FresnelEmitColor.rgb * spec * ( _FresnelEmitColor.a * 16.0f );
			
			if( main.a > _Cutoff )
			  o.Alpha = main.a;
			else
			  o.Alpha = 0;
		}
	
		ENDCG
	} 
	    
	Fallback "Diffuse"
}