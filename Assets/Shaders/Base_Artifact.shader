Shader "Base_Artifact" 
{
	Properties  
	{
		_SpecAmount ( "Specular Amount", Range( 0.0, 16.0 ) ) = 1.0
		_SpecTexAmount ( "Spec Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		_Normalmap ( "Normalmap", 2D ) = "normal" {}
		_Specmap ( "Specmap", 2D ) = "spec" {}
		
		_DataTex ( "Data Artifact", 2D ) = "black" {}
		_Rate ( "Artifact Rate", float ) = 2.0
		_Screeny_rate ( "Screen Rate", float ) = 6.0
		_WarpScale ( "Warp Scale", range( 0, 4 ) ) = 0.5
		_WarpOffset ( "Warp Offset", range( 0, 0.5 ) ) = 0.5
		
		_FresnelPower ( "Fresnel Power", Range( 0.0, 4.0 ) ) = 8.0
		_FresnelPrimarySecondary ( "Primary/Secondary Fresnel Degree", Range( 0.0, 1.0 ) ) = 1.0
		_FresnelTertiary ( "Fresnel Tertiary Infusion", Range( 0.0, 0.25 ) ) = 0.25
		_FresnelBoost ( "Fresnel Boost", Range( 1.0, 8.0 ) ) = 0.0
		_FresnelBalance ( "Fresnel Balance", Range( 0.0, 0.0625 ) ) = 0.25
		
		_FresnelEmitColor ( "Fresnel Emit Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
		_FresnelEmitPrimarySecondary ( "Primary/Secondary Emit Fresnel Degree", Range( 0.0, 1.0 ) ) = 1.0
		_FresnelEmitPower ( "Fresnel Emit Power", Range( 0.0, 16.0 ) ) = 8.0
		
		_PrimarySecondary ( "Primary/Secondary Degree", Range( 0.0, 1.0 ) ) = 1.0
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
		#pragma surface surf SimpleSpecular vertex:vert novertexlights
		#pragma glsl
		//fullforwardshadows approxview dualforward
		
		float _Gloss;
		float _PrimarySecondary;
		
		fixed CalculateSpecular( fixed3 lDir, fixed3 vDir, fixed3 norm, float gloss )
		{	 
			float3 halfVector = normalize( lDir + vDir );
			float specDot = saturate( dot( halfVector, norm ) );
			
			float primaryBlob = pow( specDot, gloss * _Gloss * 128.0 );
			float secondaryBlob = pow( specDot, gloss * _Gloss * 16.0 );
			float tripleSpec = lerp( primaryBlob, secondaryBlob, _PrimarySecondary );

			return tripleSpec;
		}
		
		fixed4 LightingSimpleSpecular( SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten ) 
		{
			fixed diff = saturate( dot( s.Normal, lightDir ) );
			fixed spec = CalculateSpecular( lightDir, viewDir, s.Normal, 1.0f - _LightColor0.w ) * s.Specular;
			
			fixed4 c;
			c.rgb = ( s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec ) * atten;
			c.a = s.Alpha;
			
			return c;
		}
		
		fixed4 LightingSimpleSpecular_DirLightmap( SurfaceOutput s, fixed4 color, fixed4 scale, fixed3 viewDir, bool surfFuncWritesNormal, out fixed3 specColor ) 
		{
			UNITY_DIRBASIS
			half3 scalePerBasisVector;
			
			half3 lm = DirLightmapDiffuse( unity_DirBasis, color, scale, s.Normal, surfFuncWritesNormal, scalePerBasisVector );
			half3 lightDir = normalize( scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2 ]);
			
			specColor = lm * CalculateSpecular( lightDir, viewDir, s.Normal, 1.0f - _LightColor0.w ) * s.Specular;
			
			return half4( lm * 0.5, 1.0 ); 
		}
	
	 	sampler2D _Normalmap;
	 	sampler2D _Specmap; 

		fixed _SpecAmount;
		fixed _SpecTexAmount; 
		
		float _FresnelPower;
		float _FresnelPrimarySecondary;
		float _FresnelTertiary;
		float _FresnelBoost;
		
        float4 _FresnelEmitColor;
		float _FresnelBalance;
		
		sampler2D _DataTex;
		
		float _WarpScale;
		float _WarpOffset;
		float _Rate;
		float _Screeny_rate;
		
		struct Input 
		{
			float2 uv_Normalmap;
			float2 uv_Specmap;
			float2 uv_DataTex;
            
			float4 pos : POSITION;
			float4 dataUV : TEXCOORD1;
			float3 viewDir;
		};
		
		float3 rand3d_3d( float3 co )
		{
		    return float3(
		      frac( sin( dot( co.xyz, float3( 16.1242,34.2153,42.3222 ) ) ) * 34344.2322 ) - 0.5,
		      frac( sin( dot( co.xyz, float3( 27.2344,98.2142,57.2324 ) ) ) * 43758.5453 ) - 0.5,
		      frac( cos( dot( co.xyz, float3( 34.7483,42.8534,12.1234 ) ) ) * 53978.3542 ) - 0.5 );
		}

		void vert ( inout appdata_full v, out Input o )
		{
		    float4 pos = mul( UNITY_MATRIX_MVP, v.vertex );
		    float2 screenuv = pos.xy / pos.w;
		    screenuv.y += _Time.x * _Screeny_rate;
			
			o.dataUV = float4( screenuv.x, screenuv.y, 0, 0 );
			float4 tex = tex2Dlod( _DataTex, o.dataUV );
			
			float3 warp = v.vertex.xyz + float3(
				sin( v.normal.x*tex.r*v.vertex.x ),
				atan( v.normal.y*tex.g*v.vertex.y ),
				cos( v.normal.z*tex.b*v.vertex.z )
			);
			//warp *= 1.0 - ( v.normal * rand3d_3d( v.normal ) * _WarpOffset );// * _WarpOffset * sin( _Time.x * _Rate );
			
			float dist = distance( v.vertex.xyz, warp );
			v.vertex.xyz = lerp( warp * _WarpScale, v.vertex.xyz, dist );
		}

		float _FresnelEmitPower;
		float _FresnelEmitPrimarySecondary;

		void surf( Input IN, inout SurfaceOutput o ) 
		{
			o.Normal = UnpackNormal( tex2D( _Normalmap, IN.uv_Normalmap ) );
		
			float fresnelDot = 1.0 - saturate( dot( normalize( IN.viewDir ), o.Normal ) );
			float fresnelPrimaryBlob = pow( fresnelDot, _FresnelPower * 2.0 );
			float fresnelSecondaryBlob = pow( fresnelDot, _FresnelPower );
			float fresnelTertiaryBlob = pow( fresnelDot, _FresnelPower * 0.5 );
			float fresnel = lerp( fresnelPrimaryBlob, fresnelSecondaryBlob, _FresnelPrimarySecondary ) + fresnelTertiaryBlob * _FresnelTertiary;
			fresnel *= _FresnelBoost;
			
			float spec = lerp( tex2D( _Specmap, IN.uv_Specmap ).r, 1.0, _SpecTexAmount );
			
			float emitPrimaryBlob = pow( fresnelDot, _FresnelEmitPower * 2.0 );
			float emitSecondaryBlob = pow( fresnelDot, _FresnelEmitPower );
			float emitFresnel = lerp( emitPrimaryBlob, emitSecondaryBlob, _FresnelEmitPrimarySecondary );
			
			o.Emission = emitFresnel * _FresnelEmitColor.rgb * spec * ( _FresnelEmitColor.a * 16.0f );
			o.Specular = spec * _SpecAmount * lerp( fresnel, 1.0, _FresnelBalance );
		}
	
		ENDCG
	} 
	    
	Fallback "Diffuse"
}