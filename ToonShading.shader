Shader "Custom/ToonShading"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _FetchTex ("Fetching Texture", 2D) = "white" { }
        _Color ("Color", Color) = (0.0, 0.0, 0.0, 1.0)
        _Ambient ("Ambient Color", Color) = (0.1, 0.1, 0.4, 1)
        _Diffuse ("Diffuse", Color) = (0.3, 0.3, 1, 1)
        _DiffuseH ("Diffuse Half", Color) = (1.0, 1.0, 1.0, 1)
        _DiffuseHH ("Diffuse Half Half", Color) = (1.0, 1.0, 1.0, 1)
        _DiffuseBorder ("Diffuse Border", Range(0.01, 1)) = 0.2
        _DiffuseBorderBlur ("Diffuse Border Blur", Range(0.01, 0.2)) = 0.01
        _Shininess ("shininess", Range(0.01, 1)) = 0.7
        _Specular ("Specular Color", Color) = (1, 1, 1, 1)
        _SpecularBorder ("_SpecularBorder", Range(0.01, 1)) = 0.5
        _SpecularBorderBlur ("Specular Border Blur", Range(0.01, 0.2)) = 0.01
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        //Blend DstColor Zero
        LOD 100

        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
                float2 fuv: TEXCOORD1;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                fixed4 color: COLOR;
                float3 normal: TEXCOORD2;
                float3 lightDir: TEXCOORD3;
                float3 reflectDir: TEXCOORD4;
                float4 wpos: TEXCOORD5;
                float2 fuv: TEXCOORD6;
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _FetchTex; uniform float4 _FetchTex_ST;
            uniform fixed4 _Color;
            uniform fixed4 _Ambient;
            uniform fixed4 _Diffuse;
            uniform fixed4 _DiffuseH;
            uniform fixed4 _DiffuseHH;
            uniform float _DiffuseBorder;
            uniform float _DiffuseBorderBlur;
            uniform float _Shininess;
            uniform fixed4 _Specular;
            uniform float _SpecularBorder;
            uniform float _SpecularBorderBlur;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.fuv = TRANSFORM_TEX(v.fuv, _FetchTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                o.color = _Color;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.lightDir = WorldSpaceLightDir(v.vertex);
                float3 viewDir = ObjSpaceViewDir(v.vertex);
                o.reflectDir = reflect(-viewDir, v.normal);
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                float4 fetchTex = tex2D(_FetchTex, i.fuv);
                float scalar = max(fetchTex.r, max(fetchTex.g, fetchTex.b));

                float3 L = normalize(i.lightDir);
                float3 N = normalize(i.normal);
                float3 R = normalize(i.reflectDir);

                //ノーマルとライトベクトルの内積
                float NdotL = clamp(dot(N, L), 0, 1);
                float I_d = NdotL;

                float hI_d = NdotL / 3.0;
                
                //float hhI_d = hI_d / 2.0;

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.wpos.xyz);
                float NNdotV = 1 - dot(N, viewDir);

                float hhI_d = NNdotV / 3.0;

                //ノーマルと反射ベクトルの内積
                //float NdotR = clamp(dot(N, R), 0, 1);

                //ライトベクトルと反射ベクトルの内積
                float LdotR = clamp(dot(L, R), 0, 1);
                float shininess = pow(500.0, _Shininess);
                float I_s = pow(LdotR, shininess);

                float4 c_a = _Ambient;
                float t_d = smoothstep(_DiffuseBorder, _DiffuseBorder, I_d);
                float4 c_d = lerp(c_a, _Diffuse, t_d);

                float hc_a = _DiffuseH;
                float ht_d = smoothstep(_DiffuseBorder, _DiffuseBorder, hI_d);
                float4 hc_d = lerp(c_d, hc_a, ht_d);

                float hhc_a = _DiffuseHH;
                float hht_d = smoothstep(_DiffuseBorder, _DiffuseBorder, hhI_d);
                float4 hhc_d = lerp(hc_d, hhc_a, hht_d);

                float t_s = smoothstep(_SpecularBorder - _SpecularBorderBlur, _SpecularBorder + _SpecularBorderBlur, I_s);
                float4 c = lerp(hhc_d, _Specular, t_s);

                // sample the texture
                //fixed4 col = lerp(tex2D(_MainTex, i.uv), fetchTex, 0.5) * c;
                fixed4 col = tex2D(_MainTex, i.uv) * c;
                col.rgb = dot(col.rgb, float3(0.3, 0.59, 0.11));
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
