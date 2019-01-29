Shader "MyShaderTest/5_SimpleWater"
{
	Properties
	{
		_MainTex("Main Tex",2D) = "white"{}		

		_Bump("Bump",2D) = "bump" {}
		_BumpSize("Bump Size",float) = 1
		_BumpSpeed("Bump Speed",Range(0,2)) = 1
		
		_ReflectionColor("Reflection Color",Color) = (1,1,1,1)

		_RefractionScale("Refraction Scale",float) = 1	

		_DistanceFactor("Distance Factor",float) = 0

			_w("_w",float) = 0
			_waveWidth("_waveWidth",float) = 0
			_timeFactor("_timeFactor",float) = 0

			//_wavePos("wavePos",vector) = (0,0,0,0)
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque" }

		Pass
		{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "Lighting.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord : TEXCOORD0;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;
				float4 Ttw0 : TEXCOORD2;
				float4 Ttw1 : TEXCOORD3;
				float4 Ttw2 : TEXCOORD4;
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;
			half4 _MainTex_TexelSize;

			sampler2D _Bump;
			half4 _Bump_ST;
			half _BumpSize;
			half _BumpSpeed;

			fixed4 _ReflectionColor;
			half _RefractionScale;
		
			float _DistanceFactor;
			float _totalFactor;
			float _waveWidth;
			float _timeFactor;
			float _w;
			float4 _wavePos;

			v2f vert(a2v v)
			{
				v2f o;
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);

				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w;

				o.pos = mul(UNITY_MATRIX_VP, float4(worldPos, 1));
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _Bump);


				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y <= 0.0)
						o.uv.y = 1.0 - o.uv.y;
				#endif

				o.Ttw0 = float4(worldTangent.x, worldBitangent.x, worldNormal.x, worldPos.x);
				o.Ttw1 = float4(worldTangent.y, worldBitangent.y, worldNormal.y, worldPos.y);
				o.Ttw2 = float4(worldTangent.z, worldBitangent.z, worldNormal.z, worldPos.z);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 worldPos = float3(i.Ttw0.w,i.Ttw1.w,i.Ttw2.w);
				fixed3 worldNormal = fixed3(i.Ttw0.z, i.Ttw1.z, i.Ttw2.z);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				float2 speed = half2(_BumpSpeed, _BumpSpeed) * _Time.y;

				float2 dv = i.uv.xy - float2(_wavePos.x,_wavePos.y);

				dv = dv * float2(_wavePos.z / _wavePos.w, 1);

				float dis = sqrt(dv.x * dv.x + dv.y * dv.y);

				float sinFactor = sin(dis * _DistanceFactor + _Time.y * _timeFactor) * 0.1;

				sinFactor = sin(_w * (_timeFactor * _Time.y + dis * _DistanceFactor));

				float discardFactor = clamp(_waveWidth - dis , 0, 1);

				float2 dv1 = normalize(dv);

				float2 off = normalize(dv) * sinFactor * discardFactor;

				fixed3 bump1 = UnpackNormal(tex2D(_Bump, i.uv.zw + speed + off)).rgb;
				fixed3 bump2 = UnpackNormal(tex2D(_Bump, i.uv.zw + speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2);

				bump = bump1;

				bump.xy *= _BumpSize;
				bump.z = sqrt(1 - saturate(dot(bump.xy, bump.xy)));

				bump = normalize(half3(dot(bump, i.Ttw0.xyz), dot(bump, i.Ttw1.xyz), dot(bump, i.Ttw2.xyz)));

				float3 reflDir = normalize(reflect(-worldViewDir, bump));

				reflDir = normalize(worldViewDir);

				half3 reflColor = dot(reflDir, bump) * _ReflectionColor;

				float2 offset = bump.xy * _MainTex_TexelSize.xy * _RefractionScale;

				fixed3 refrColor = tex2D(_MainTex, i.uv.xy + offset).rgb;

				return fixed4(reflColor + refrColor, 1);
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
