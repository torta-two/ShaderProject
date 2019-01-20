Shader "MyShaderTest/5_SimpleWater"
{
	Properties
	{
		_MainTex("Main Tex",2D) = "white"{}		

		_Bump("Bump",2D) = "bump" {}
		_BumpSize("Bump Size",float) = 1
		_BumpSpeed("Bump Speed",Range(0,2)) = 1


		_Q("Q",float) = 1
		_D("波12方向",vector) = (1,1,1,1)

		_Ax("波1振幅",float) = 1
		_Ay("波2振幅",float) = 1

		_Lx("波1波长",float) = 1
		_Ly("波2波长",float) = 1

		_Sx("波1波速",float) = 1
		_Sy("波2波速",float) = 1
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
				float2 uv : TEXCOORD0;
				float4 Ttw0 : TEXCOORD2;
				float4 Ttw1 : TEXCOORD3;
				float4 Ttw2 : TEXCOORD4;
			};

			sampler2D _MainTex;
			half4 _MainTex_ST;
			half4 _MainTex_TexelSize;

			sampler2D _Bump;
			half _BumpSize;
			half _BumpSpeed;

			float _Q;
			float4 _D;

			float _Ax;
			float _Ay;
			float _Lx;
			float _Ly;
			float _Sx;
			float _Sy;

			float3 ComputeWavePos(float3 vert)
			{
				float PI = 3.14159f;
				float2 L = float2(max(_Lx, 0.0001), max(_Ly, 0.0001));

				float2 w = float2(2 * PI / L.x, 2 * PI / L.y);
				float2 phi = float2(_Sx, _Sy) * w;

				float3 pos1 = float3(0, 0, 0);
				float3 pos2 = float3(0, 0, 0);

				pos1.x = _Q * _Ax * _D.x * cos(w.x * dot(float2(_D.x, _D.y), float2(vert.x, vert.z)) + phi.x * _Time.y);
				pos2.x = _Q * _Ay * _D.z * cos(w.y * dot(float2(_D.z, _D.w), float2(vert.x, vert.z)) + phi.y * _Time.y);

				pos1.z = _Q * _Ax * _D.y * cos(w.x * dot(float2(_D.x, _D.y), float2(vert.x, vert.z)) + phi.x * _Time.y);
				pos2.z = _Q * _Ay * _D.w * cos(w.y * dot(float2(_D.z, _D.w), float2(vert.x, vert.z)) + phi.y * _Time.y);

				pos1.y = _Ax * sin(w.x * dot(float2(_D.x, _D.z), float2(vert.x, vert.z)) + phi.x * _Time.y);
				pos2.y = _Ay * sin(w.y * dot(float2(_D.y, _D.w), float2(vert.x, vert.z)) + phi.y * _Time.y);

				float3 pos = float3(vert.x + pos1.x + pos2.x, vert.y + pos1.y + pos2.y, vert.z + pos1.z + pos2.z);

				return pos;
			}


			v2f vert(a2v v)
			{
				v2f o;
				float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
				float3 wavePos = ComputeWavePos(worldPos);
				worldPos = wavePos;

				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				float3 worldBitangent = cross(worldNormal, worldTangent) * v.tangent.w;

				o.pos = mul(UNITY_MATRIX_VP, float4(wavePos, 1));
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0)
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
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				float2 speed = half2(_BumpSpeed, _BumpSpeed) * _Time.y;

				fixed3 bump1 = UnpackNormal(tex2D(_Bump, i.uv - speed)).rgb;
				fixed3 bump2 = UnpackNormal(tex2D(_Bump, i.uv + speed)).rgb;
				fixed3 bump = normalize(bump1 + bump2);

				bump.xy *= _BumpSize;
				bump.z = sqrt(1 - saturate(dot(bump.xy, bump.xy)));

				bump = normalize(half3(dot(bump, i.Ttw0.xyz), dot(bump, i.Ttw1.xyz), dot(bump, i.Ttw2.xyz)));

				float3 reflDir = normalize(reflect(-worldViewDir, bump));
				half3 reflColor = dot(reflDir, bump) * fixed3(1, 1, 1);

				fixed3 diffuse = _LightColor0 * tex2D(_MainTex, i.uv).rgb * saturate(dot(bump, worldLightDir));

				fixed3 color = reflColor + tex2D(_MainTex, i.uv).rgb;

				return fixed4(diffuse, 1);
			}

			ENDCG
		}
	}
	FallBack "Diffuse"
}
