Shader "Rimlight_Transparent_Base"
{  
        Properties
        {
				_DiffuseAmount ( "Diffuse Amount", Range( 0.0, 1.0 ) ) = 0.25
                _RimColor( "Rim Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
                _RimPower( "Rim Power", Range( 0.0,1.0 ) ) = 3.0
				_SpecAmount ( "Specular Amount", Range( 0.0, 8.0 ) ) = 1.0
                
                _Alpha( "Alpha", Range( 1.0, 0.00 ) ) = 1.0
                _AlphaOffset( "Alpha Offset", Range ( 0.0313725490196078, 0.00 ) ) = 0.01
                
				_FresnelPower ( "Fresnel Power", Range( 0.0, 8.0 ) ) = 8.0
				_FresnelMult ( "Fresnel Multiplier", Range( 0.0, 1.0 ) ) = 0.75
				_PrimarySecondary ( "Primary/Secondary Degree", Range( 0.0, 1.0 ) ) = 1.0
				_Gloss ( "Gloss", Range( 0.0, 2.0 ) ) = 1.0
        }      
   
        SubShader
        {
                Tags { "Queue" = "Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
 
                CGPROGRAM
       
				#pragma target 3.0 
                #pragma surface surf SimpleSpecular alpha noambient nolightmap
				
                float _Alpha;
                float _AlphaOffset;
     
                float4 _RimColor;
 
				float _Gloss;
				float _FresnelPower;
				float _FresnelMult;
				float _PrimarySecondary;
				fixed _SpecAmount;
				
				fixed CalculateSpecular( fixed3 lDir, fixed3 vDir, fixed3 norm, float gloss )
				{	
					float3 halfVector = normalize( lDir + vDir );
					float specDot = saturate( dot( halfVector, norm ) );
					
					float primaryBlob = pow( specDot, _Gloss * 128.0 );
					float secondaryBlob = pow( specDot, _Gloss * 16.0 );
					float tripleSpec = lerp( primaryBlob, secondaryBlob, _PrimarySecondary );
		
					return tripleSpec * gloss;
				}
				
				fixed4 LightingSimpleSpecular( SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten ) 
				{
					fixed diff = saturate( dot( s.Normal, lightDir ) );
					fixed spec = CalculateSpecular( lightDir, viewDir, s.Normal, s.Gloss ) * _SpecAmount;
					
					fixed4 c;
					c.rgb = ( s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec ) * atten;
					c.a = s.Alpha;
					
					return c;
				}
       
                struct Input
                {
                        float3 viewDir;
                };

                float _RimPower;
				fixed _DiffuseAmount;
       
                void surf (Input IN, inout SurfaceOutput o)
                {
                        o.Albedo = _DiffuseAmount;
                        float rim = 1.0 - saturate( dot( normalize( IN.viewDir ), o.Normal ) );
						o.Gloss = 0.125 + rim;
                        o.Alpha = _Alpha * pow ( rim, _RimPower ) + _AlphaOffset;
                }
                ENDCG
        }
        Fallback "Diffuse"
}