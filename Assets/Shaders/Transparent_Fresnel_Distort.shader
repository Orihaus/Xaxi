Shader "Transparent_Fresnel_Distort" 
{
	Properties 
	{
		_Color( "Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
		_BumpAmt( "Distortion", range( 0, 128 ) ) = 10
		_TexAmt( "Texture Amount", range( 0.0, 1.0 ) ) = 0.25
		_MainTex( "Tint Color (RGB)", 2D ) = "white" {}
		_BumpMap( "Normalmap", 2D) = "bump" {}
	}

Category 
{
	Tags { "Queue"="Transparent" "RenderType"="Opaque" }

	SubShader 
	{
		// This pass grabs the screen behind the object into a texture.
		// We can access the result in the next pass as _GrabTexture
		GrabPass {							
			Name "BASE"
			Tags { "LightMode" = "Always" }
 		}
 		
 		// Main pass: Take the texture grabbed above and use the bumpmap to perturb it
 		// on to the screen
		Pass {
			Name "BASE"
			Tags { "LightMode" = "Always" }
			
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest
#include "UnityCG.cginc"

struct appdata_t {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
	float2 texcoord: TEXCOORD0;
};

struct v2f {
	float4 vertex : POSITION;
	float4 uvgrab : TEXCOORD0;
	float2 uvbump : TEXCOORD1;
	float2 uvmain : TEXCOORD2;
	float3 viewDir : TEXCOORD3;
	float3 normal : TEXCOORD4;
};

float _BumpAmt;
float4 _BumpMap_ST;
float4 _MainTex_ST;

v2f vert (appdata_t v)
{
	v2f o;
	o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
	#if UNITY_UV_STARTS_AT_TOP
	float scale = -1.0;
	#else
	float scale = 1.0;
	#endif
	o.uvgrab.xy = (float2(o.vertex.x, o.vertex.y*scale) + o.vertex.w) * 0.5;
	o.uvgrab.zw = o.vertex.zw;
	o.uvbump = TRANSFORM_TEX( v.texcoord, _BumpMap );
	o.uvmain = TRANSFORM_TEX( v.texcoord, _MainTex );
	o.viewDir = ObjSpaceViewDir( v.vertex ); 
	o.normal = v.normal;
	return o;
}

float4 _Color;
sampler2D _GrabTexture;
float4 _GrabTexture_TexelSize;
sampler2D _BumpMap;
sampler2D _MainTex;
float _TexAmt;

half4 frag( v2f i ) : COLOR
{
	float3 norm = UnpackNormal( tex2D( _BumpMap, i.uvbump ) );
	half2 bump = norm.rg; // we could optimize this by just reading the x & y without reconstructing the Z
	float2 offset = bump * _BumpAmt * _GrabTexture_TexelSize.xy;
	i.uvgrab.xy = offset * i.uvgrab.z + i.uvgrab.xy;
	
	half4 col = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(i.uvgrab));
	half4 tint = lerp( tex2D( _MainTex, i.uvmain ), 1.0, _TexAmt );
	half rim = 1.0 - saturate( dot( normalize( i.viewDir ), i.normal ) );
	rim *= 1.0 - saturate( dot( normalize( i.viewDir ), bump ) );
	rim = ( pow( rim, 2.0 ) * 0.05 ) + ( pow( rim, 4.0 ) * 0.175 );
	rim *= 0.25;
	
	return col + _Color * ( rim + tint * 0.1 );
}
ENDCG
		}
	}

	// ------------------------------------------------------------------
	// Fallback for older cards and Unity non-Pro
	
	SubShader {
		Blend DstColor Zero
		Pass {
			Name "BASE"
			SetTexture [_MainTex] {	combine texture }
		}
	}
}

}
