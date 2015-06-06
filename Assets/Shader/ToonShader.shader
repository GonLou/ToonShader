/*
Summary:
The purpose of this shader is to create a toon shader.

This is a early release that is still to be improved with more levels of customization and performance.

*/

Shader "Custom/ToonShader" {
	Properties {
		_Color ("Color", Color) = (1, 1, 1, 1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_NormalMap ("Normal Map", 2D) = "white" {}
		
		_SpecMap("Specular Map", 2D) = "white" {}
		_Glossiness ("Gloss", range(1, 4)) = 2
		
		_Shading ("Shading", range(0, 1)) = 0.5
		_Lightning("Lightning", range(0, 1)) = 0.5
		
		_Outline("Outline", range(0, 1)) = 0.1
		_OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
		
		_ShadingSoftness ("Shading Softness", range(0, 1)) = 0
		_OutlineSoftness ("Outline Softness", range(0, 1)) = 0
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		CGPROGRAM
		#pragma surface surf SpecMap
		#pragma target 3.0

		// SurfaceOutput extended
 		struct MySurfaceOutput {
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Specular;
			half3 GlossColor;
			half Alpha;
		};
		
		half4 _Color;
		sampler2D _MainTex;
		sampler2D _NormalMap;
		
		sampler2D _SpecMap;
		half _Glossiness;
		
		half _Shading;
		half _Lightning;
		
		half _Outline;
		half _OutlineColor;
		
		half _ShadingSoftness;
		half _OutlineSoftness;

		// same as diffuseTerm but scalable
		half halfDiffuseTerm(half3 a, half3 b) {
			return dot(normalize(a), normalize(b)) * 0.5f + 0.5f;
		}
		
		// helper function that calculates values between zero and one taking the direction of the light source
		half diffuseTerm(half3 a, half3 b) {
			return max(0, dot(normalize(a), normalize(b)));
		}

		// improved Perlin smooth
		half softStep(half a, half b, half softness) {
			// Scale, and clamp x to 0..1 range
			float x = step(a, b) * clamp((b - a)/(softness - a), 0.0, 1.0);
			// Evaluate polynomial
			return x*x*x*(x*(x*6 - 15) + 10);
		}
		
		half4 LightingSpecMap(MySurfaceOutput o, half3 lightDir, half3 viewDir, half att) {
			half calculatedDiffuse = halfDiffuseTerm(o.Normal, lightDir);
			half shading = softStep(_Shading, calculatedDiffuse, _ShadingSoftness);
			half3 diffuseColor = _LightColor0 * o.Albedo * shading;
			
			half calculatedSpecular = pow(diffuseTerm(o.Normal, lightDir + viewDir), _Glossiness);
			half lighting = softStep(_Lightning, calculatedSpecular, _OutlineSoftness);
			half3 specularColor = _LightColor0 * o.GlossColor * lighting;
			
			half3 returnColor = (diffuseColor + specularColor) * att * 2;
			return half4(returnColor, o.Alpha);
		}

		struct Input {
			float2 uv_MainTex;
			float3 viewDir; //to know where the camera is facing to
		};

		void surf (Input IN, inout MySurfaceOutput o) {
			half4 c = tex2D (_MainTex, IN.uv_MainTex);

			// gets texture information and calculate the vector normal from it
			half3 myNormal = UnpackNormal( tex2D(_NormalMap, IN.uv_MainTex));	
			o.Normal = myNormal;

			half d = dot(normalize(IN.viewDir), o.Normal);
			half finalLine = softStep(_Outline, d, _OutlineSoftness); 
			
			// to aqcuire the color selected we have multiply buy the input value
			o.Albedo = (c.rgb * _Color * finalLine) + ((1-finalLine) * _OutlineColor);
			//o.Albedo = c.rgb * _Color ;
			o.Alpha = c.a;
			
			half4 mySpecular = tex2D(_SpecMap, IN.uv_MainTex);
			o.GlossColor = mySpecular.rgb;
		}
		ENDCG
	} 
	FallBack "Diffuse"
}
