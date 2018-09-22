Shader "Custom/BRDFTranslucentSSS"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "black" { }
        _BrdfTex ("BRDF Texture", 2D) = "white" { }
        _ThicknessTex ("Thickness Map", 2D) = "white" { }
        _MainCol ("Main Color", Color) = (1, 1, 1, 1)
        _Ambient ("Ambient", Color) = (1, 1, 1, 1)
        _TranslucentColor ("Translucent Color", Color) = (1, 1, 1, 1)
        _Thickness ("Object Thickness", Float) = 1.0
        _Distortion ("Light Distortion", Float) = 1.0
        _BrdfShininess ("BRDF Shininess", Float) = 1.0
        _Power ("Light Power", Float) = 1.0
        _Scale ("Total Light Strength", Float) = 1.0
        _LightShininess ("Light Shininess", Float) = 1.0
        _SpecCol ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecShininess ("Specular Shininess", Float) = 1.0
        _SpecShininessScale ("Total Specular Shininess Strength", Float) = 1.0
        _BackLightSpecShininess ("Back Light Specular Shininess", Float) = 1.0
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _CullMode ("Cull Mode", int) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100
        Cull[_CullMode]
        
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            CGPROGRAM
            
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            #pragma multi_compile _ VERTEXLIGHT_ON

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                float3 normal: TEXCOORD2;
                float4 wpos: TEXCOORD3;
                LIGHTING_COORDS(4, 5)
                #if defined(VERTEXLIGHT_ON)
                    float3 vertexLightColor: TEXCOORD6;
                #endif
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _BrdfTex; uniform float4 _BrdfTex_ST;
            uniform sampler2D _ThicknessTex; uniform float4 _ThicknessTex_ST;
            uniform fixed4 _MainCol;
            uniform fixed4 _Ambient;
            uniform fixed4 _TranslucentColor;
            uniform float _Thickness;
            uniform float _Distortion;
            uniform float _BrdfShininess;
            uniform float _Power;
            uniform float _Scale;
            uniform float _LightShininess;
            uniform fixed4 _SpecCol;
            uniform float _SpecShininess;
            uniform float _SpecShininessScale;
            uniform float _BackLightSpecShininess;

            void ComputeVertexLightColor(inout v2f i)
            {
                #if defined(VERTEXLIGHT_ON)
                    i.vertexLightColor = Shade4PointLights(
                        unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
                        unity_LightColor[0].rgb, unity_LightColor[1].rgb,
                        unity_LightColor[2].rgb, unity_LightColor[3].rgb,
                        unity_4LightAtten0, i.wpos, i.normal
                    );
                #endif
            }
            
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                ComputeVertexLightColor(o);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed4 mainTex = tex2D(_MainTex, i.uv);

                float3 lightDir;
                #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
                    lightDir = normalize(_WorldSpaceLightPos0.xyz - i.wpos.xyz);
                #else
                    lightDir = _WorldSpaceLightPos0.xyz;
                #endif

                fixed4 lightCol;
                #if defined(VERTEXLIGHT_ON)
                    lightCol = i.vertexLightColor;
                #else
                    lightCol = _LightColor0;
                #endif

                lightCol.rgb += max(0, ShadeSH9(float4(i.normal, 1)));

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.wpos).xyz;
                float VdotL = saturate(dot(viewDir, lightDir));
                
                float3 a = lightDir + i.normal * max(0, _Distortion);
                float b = pow(saturate(dot(viewDir, -a)), max(0, _Power)) * max(0, _Scale);
                UNITY_LIGHT_ATTENUATION(atten, i, i.wpos.xyz);
                float thickness = pow(tex2D(_ThicknessTex, i.uv).r, max(0, _Thickness));
                float c = atten * (b + _Ambient) * thickness;

                float NdotL = saturate(dot(i.normal, lightDir));
                //NdotL = length(lightDir) != 0 ? (NdotL * 0.5) + 0.5 : 0;
                NdotL = (NdotL * 0.5) + 0.5;
                fixed4 col = lerp(_MainCol, mainTex, saturate(length(mainTex) * 100));
                col.rgb *= NdotL;

                float NdotV = saturate(dot(i.normal, viewDir));
                float2 brdfUV = float2(NdotV, NdotL);
                float3 brdf = tex2D(_BrdfTex, brdfUV.xy).rgb;

                float3 specRef = atten * _LightColor0.rgb * _SpecCol.rgb * pow(max(0, dot(reflect(-lightDir, i.normal), viewDir)), 10 * max(0, _SpecShininess)) * 10 * max(0, _SpecShininessScale) * VdotL;
                specRef += atten * _LightColor0.rgb * _SpecCol.rgb * pow(max(0, dot(reflect(-lightDir, i.normal), viewDir)), max(0, _SpecShininess)) * max(0, _SpecShininessScale) * b * 0.1 * max(0, _BackLightSpecShininess);

                col.rgb += lerp(fixed3(0, 0, 0), lightCol.rgb * max(0, _LightShininess) * _TranslucentColor, smoothstep(0, 1, thickness)) * lerp(NdotL, c, smoothstep(0, 1, 1 - dot(i.normal, lightDir))) * brdf * max(0, _BrdfShininess) + specRef;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
        Pass
        {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            ZWrite Off
            CGPROGRAM
            
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityPBSLighting.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                float3 normal: TEXCOORD2;
                float4 wpos: TEXCOORD3;
                LIGHTING_COORDS(4, 5)
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _BrdfTex; uniform float4 _BrdfTex_ST;
            uniform sampler2D _ThicknessTex; uniform float4 _ThicknessTex_ST;
            uniform fixed4 _MainCol;
            uniform fixed4 _Ambient;
            uniform fixed4 _TranslucentColor;
            uniform float _Thickness;
            uniform float _Distortion;
            uniform float _BrdfShininess;
            uniform float _Power;
            uniform float _Scale;
            uniform float _LightShininess;
            uniform fixed4 _SpecCol;
            uniform float _SpecShininess;
            uniform float _SpecShininessScale;
            uniform float _BackLightSpecShininess;
            
            v2f vert(appdata v)
            {
                v2f o = (v2f)0;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed4 mainTex = tex2D(_MainTex, i.uv);

                float3 lightDir;
                #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
                    lightDir = normalize(_WorldSpaceLightPos0.xyz - i.wpos.xyz);
                #else
                    lightDir = _WorldSpaceLightPos0.xyz;
                #endif

                fixed4 lightCol = _LightColor0;
                lightCol.rgb += max(0, ShadeSH9(float4(i.normal, 1)));

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.wpos).xyz;
                float VdotL = saturate(dot(viewDir, lightDir));
                
                float3 a = lightDir + i.normal * max(0, _Distortion);
                float b = pow(saturate(dot(viewDir, -a)), max(0, _Power)) * max(0, _Scale);
                UNITY_LIGHT_ATTENUATION(atten, i, i.wpos.xyz);
                float thickness = pow(tex2D(_ThicknessTex, i.uv).r, max(0, _Thickness));
                float c = atten * (b + _Ambient) * thickness;

                float NdotL = saturate(dot(i.normal, lightDir));
                //NdotL = length(lightDir) != 0 ? (NdotL * 0.5) + 0.5 : 0;
                NdotL = (NdotL * 0.5) + 0.5;
                fixed4 col = lerp(_MainCol, mainTex, saturate(length(mainTex) * 100));
                col.rgb *= NdotL;

                float NdotV = saturate(dot(i.normal, viewDir));
                float2 brdfUV = float2(NdotV, NdotL);
                float3 brdf = tex2D(_BrdfTex, brdfUV.xy).rgb;

                float3 specRef = atten * _LightColor0.rgb * _SpecCol.rgb * pow(max(0, dot(reflect(-lightDir, i.normal), viewDir)), 10 * max(0, _SpecShininess)) * 10 * max(0, _SpecShininessScale) * VdotL;
                specRef += atten * _LightColor0.rgb * _SpecCol.rgb * pow(max(0, dot(reflect(-lightDir, i.normal), viewDir)), max(0, _SpecShininess)) * max(0, _SpecShininessScale) * b * 0.1 * max(0, _BackLightSpecShininess);

                col.rgb += lerp(fixed3(0, 0, 0), lightCol.rgb * max(0, _LightShininess) * _TranslucentColor, smoothstep(0, 1, thickness)) * lerp(NdotL, c, smoothstep(0, 1, 1 - dot(i.normal, lightDir))) * brdf * max(0, _BrdfShininess) + specRef;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
