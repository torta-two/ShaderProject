Shader "MyShaderTest/6_Laser"
{
	Properties
	{
		_BumpTex("Bump Tex",2D) = "bump" {}

		_RampTex("Ramp Texture", 2D) = "white" {}
		_RampSize("Ramp Size", float) = 1
		_AlphaScale("Alpha Size",float) = 1

		_Color ("Color",Color) = (1,1,1,1)
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" 
			   "IgnoreProjector"="True"
			   "Queue"="Transparent"}

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				
				half4 Ttw0 : TEXCOORD1;
				half4 Ttw1 : TEXCOORD2;
				half4 Ttw2 : TEXCOORD3;
			};

			sampler2D _BumpTex;
			float4 _BumpTex_ST;
			sampler2D _RampTex;
			half _RampSize;
			half _AlphaScale;

			fixed4 _Color;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				half3 worldPos = mul(unity_ObjectToWorld, v.vertex);
				half3 worldNormal = UnityObjectToWorldNormal(v.normal);
				half3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				half3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w;

				o.Ttw0 = half4(worldBitangent.x, worldTangent.x, worldNormal.x, worldPos.x);
				o.Ttw1 = half4(worldBitangent.y, worldTangent.y, worldNormal.y, worldPos.y);
				o.Ttw2 = half4(worldBitangent.z, worldTangent.z, worldNormal.z, worldPos.z);

				o.uv = TRANSFORM_TEX(v.uv,_BumpTex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 worldPos = float3(i.Ttw0.w,i.Ttw1.w,i.Ttw2.w);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

				fixed3 bump = normalize(UnpackNormal(tex2D(_BumpTex, i.uv)));

				fixed3 worldNormal = float3(i.Ttw0.z, i.Ttw1.z, i.Ttw2.z);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyx;

				fixed NdotL = dot(worldNormal, worldLightDir);
				
				fixed alpha = _AlphaScale * (0.7 - NdotL * 0.7);

				fixed diff = 0.5 + NdotL * 0.5;

				fixed3 diffuse1 = _LightColor0 * tex2D(_RampTex,fixed2(diff,diff)).rgb; 
				fixed3 diffuse2 = _LightColor0 * diff;

				fixed3 diffColor = _Color * tex2D(_RampTex, fixed2(diff, diff)).rgb;

				return fixed4(ambient + lerp(diffuse2,diffuse1,_RampSize) + diffColor,alpha);
			}
			ENDCG
		}
	}
}
