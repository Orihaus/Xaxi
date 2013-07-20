Shader "Base_Artifact" 
{
	Properties  
	{
		_DiffuseAmount ( "Diffuse Amount", Range( 0.0, 0.075 ) ) = 0.25
		_TexAmount ( "Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		
		_SpecAmount ( "Specular Amount", Range( 0.0, 32.0 ) ) = 1.0
		_SpecTexAmount ( "Spec Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		_Specmap ( "Specmap", 2D ) = "spec" {}
		
		_Normalmap ( "Normalmap", 2D ) = "normal" {}
		
		_DataTex ( "Data Artifact", 2D ) = "black" {}
		_Rate ( "Artifact Rate", float ) = 2.0
		_Screeny_rate ( "Screen Rate", float ) = 6.0
		_WarpScale ( "Warp Scale", range( 0, 4 ) ) = 0.5
		_WarpOffset ( "Warp Offset", range( 0, 0.5 ) ) = 0.5
		
		_FresnelPower ( "Fresnel Power", Range( 0.0, 4.0 ) ) = 8.0
		_FresnelPrimarySecondary ( "Primary/Secondary Fresnel Degree", Range( 0.0, 1.0 ) ) = 1.0
		_FresnelBalance ( "Fresnel Balance", Range( 0.0, 0.25 ) ) = 0.25
		
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
          "Queue"="Geometry+100" 
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
			
			return fresnel * normalisation_term * tripleSpec * n_dot_l;
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
		sampler2D _DataTex;
		float4 _DataTex_ST;
		
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
			o.dataUV.xy = TRANSFORM_TEX( o.dataUV.xy, _DataTex );
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
		
		fixed _DiffuseAmount;
		fixed _SpecTexAmount; 
		
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
		}
	
		ENDCG
	} 
	    
	Fallback "Diffuse"
}