Shader "Base_Texture" 
{
	Properties  
	{
		_DiffuseAmount ( "Diffuse Amount", Range( 0.0, 0.075 ) ) = 0.25
		_TexAmount ( "Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		_SpecAmount ( "Specular Amount", Range( 0.0, 32.0 ) ) = 1.0
		_SpecTexAmount ( "Spec Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		//_MainMap ( "Main Texture", 2D ) = "main" {}
		_Normalmap ( "Normalmap", 2D ) = "normal" {}
		_Specmap ( "Specmap", 2D ) = "spec" {}
		
		_FresnelPower ( "Fresnel Power", Range( 0.0, 4.0 ) ) = 1.0
		_FresnelPrimarySecondary ( "Primary/Secondary Fresnel Degree", Range( 0.0, 1.0 ) ) = 1.0
		//_FresnelTertiary ( "Fresnel Tertiary Infusion", Range( 0.0, 0.25 ) ) = 0.25
		_FresnelBalance ( "Fresnel Balance", Range( 0.0, 0.25 ) ) = 0.25
		
		_FresnelEmitColor ( "Fresnel Emit Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
		_FresnelEmitPrimarySecondary ( "Primary/Secondary Emit Fresnel Degree", Range( 0.0, 1.0 ) ) = 1.0
		_FresnelEmitPower ( "Fresnel Emit Power", Range( 0.0, 16.0 ) ) = 8.0
		
		_PrimarySecondary ( "Primary/Secondary Degree", Range( 0.0, 1.0 ) ) = 1.0
		//_Tertiary ( "Tertiary Infusion", Range( 0.0, 0.25 ) ) = 0.25
		_Gloss ( "Gloss", Range( 0.0, 2.0 ) ) = 1.0
	}
	    
	SubShader 
	{
        Tags
        {
          "Queue"="Geometry+0" 
          "IgnoreProjector"="False"
          "RenderType"="Opaque"
        }

        Cull Back
        ZWrite On
        ZTest LEqual

		CGPROGRAM
		#pragma target 3.0 
		#pragma surface surf SimpleSpecular novertexlights fullforwardshadows
		//fullforwardshadows approxview dualforward
		
		float _Gloss;
		float _PrimarySecondary;
		fixed _SpecAmount;
		
 		float CalculateGuass( float angleNormalHalf, float blob )
 		{
			float exponent = angleNormalHalf / blob;
			exponent = -( exponent * exponent );
			return exp( exponent );
 		}
		
		float CalculateSpecular( fixed3 lDir, fixed3 vDir, fixed3 norm, float lightSize )
		{	 
			fixed n_dot_l = saturate( dot( norm, lDir ) );
			float3 halfVector = normalize( lDir + vDir );
			float specDot = saturate( dot( halfVector, norm ) );
			float angleNormalHalf = acos( dot( halfVector, norm ) );
			
			float fresnel = pow( 1.0 - dot( halfVector, vDir ), 5.0 );
			fresnel = 0.75 + ( 1.0 - fresnel ) * fresnel;
			
			// Guassian Microfacets
			float modGloss = _Gloss - ( 1.0 - lightSize ) * _WorldSpaceLightPos0.w;
			modGloss = saturate( modGloss + 0.25 );
			float normalisation_term = ( modGloss + 2.0f ) / 8.0f;
			
			float primaryBlob = CalculateGuass( angleNormalHalf, 1.0 / ( modGloss * 8.0 ) );
			float secondaryBlob = CalculateGuass( angleNormalHalf, 1.0 / ( modGloss * 4.0 ) ); 
			
			float tripleSpec = lerp( primaryBlob, secondaryBlob, _PrimarySecondary );
			
			return fresnel * normalisation_term * tripleSpec;
		}
		
		fixed4 LightingSimpleSpecular( SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten ) 
		{
			float lightDistance = atten * 8.0; //length( _WorldSpaceLightPos0.rgb - s.Albedo ) * _WorldSpaceLightPos0.w;
		
			fixed spec = CalculateSpecular( lightDir, viewDir, s.Normal, lightDistance ) * s.Specular * _SpecAmount; //* ( 1.0f - _LightColor0.w )
			fixed diff = saturate( dot( s.Normal, lightDir ) ) * s.Gloss;
			
			diff = lerp( diff, 0.0, spec );
			
			fixed4 c;
			c.rgb = diff * _LightColor0.rgb;
			c.rgb += _LightColor0.rgb * spec;
			c.rgb *= atten;
			c.a = s.Alpha;
			
			return c;
		}

		struct Input 
		{
			//float2 uv_MainMap;
			float2 uv_Normalmap;
			float2 uv_Specmap;
            float3 viewDir;
		};
	
 		//sampler2D _MainMap;
	 	sampler2D _Normalmap;
	 	sampler2D _Specmap; 

		fixed _SpecTexAmount; 
		//fixed _TexAmount;
		fixed _DiffuseAmount;
		
		float _FresnelPower;
		float _FresnelPrimarySecondary;
        float4 _FresnelEmitColor;
		float _FresnelBalance;
		float _FresnelEmitPower;
		float _FresnelEmitPrimarySecondary;

		void surf( Input IN, inout SurfaceOutput o ) 
		{
			o.Normal = UnpackNormal( tex2D( _Normalmap, IN.uv_Normalmap ) );
		
			float fresnelDot = 1.0 - saturate( dot( normalize( IN.viewDir ), o.Normal ) );
			float fresnelPrimaryBlob = pow( fresnelDot, _FresnelPower * 2.0 );
			float fresnelSecondaryBlob = pow( fresnelDot, _FresnelPower );
			float fresnel = lerp( fresnelPrimaryBlob, fresnelSecondaryBlob, _FresnelPrimarySecondary );
			fresnel = lerp( fresnel, 1.0, _FresnelBalance );
			fresnel *= ( _FresnelPower + 2.0f ) / 4.0f;
			
			float emitPrimaryBlob = pow( fresnelDot, _FresnelEmitPower * 2.0 );
			float emitSecondaryBlob = pow( fresnelDot, _FresnelEmitPower );
			float emitFresnel = lerp( emitPrimaryBlob, emitSecondaryBlob, _FresnelEmitPrimarySecondary );
			o.Emission = emitFresnel * _FresnelEmitColor.rgb * ( _FresnelEmitColor.a * 16.0f );
			
			float spec = lerp( tex2D( _Specmap, IN.uv_Specmap ).r, 1.0, _SpecTexAmount );
			o.Specular = spec * fresnel;
			o.Gloss = _DiffuseAmount; // Albedo in gloss
			//o.Albedo = IN.worldPos; // World position in Albedo
		}
	
		ENDCG
	} 
	    
	Fallback "Diffuse"
}