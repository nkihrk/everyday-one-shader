// https://lindseyreidblog.wordpress.com/2017/12/30/ice-shader-in-unity/
Shader "Custom/IceShader"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" { }
        _RampTex ("Ramp Texture", 2D) = "white" { }
        _BumpTex ("Bump Texture", 2D) = "white" { }
        _Color ("Color", Color) = (1, 1, 1, 1)
        _DistortStrength ("Distort Strength", Float) = 1.0
        _EdgeThickness ("Edge Thickness", Float) = 1.0
        _SpecSize ("Specular Circle Size", Range(0.0, 10.0)) = 3.50
        _Shininess ("Shininess", Range(0.1, 1.00)) = 0.50
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100
        
        GrabPass
        {
            "_BackgroundTexture"
        }

        Pass
        {
            Cull Off
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
                float3 normal: NORMAL;
            };

            struct v2f
            {
                float4 grabPos: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                float3 normal: TEXCOORD2;
                float3 viewDir: TEXCOORD3;
                float3 spec: COLOR;
            };

            uniform sampler2D _RampTex;
            uniform sampler2D _BumpTex;
            uniform sampler2D _BackgroundTexture;
            uniform float _DistortStrength;
            uniform float _EdgeThickness;
            uniform fixed4 _Color;
            uniform float4 _LightColor0;
            uniform float _SpecSize;
            uniform float _Shininess;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.normal = normalize(mul(unity_ObjectToWorld, float4(v.normal, 0))).xyz;
                o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.vertex)).xyz;
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                float2 bump = tex2Dlod(_BumpTex, float4(v.uv, 0, 0)).rg;
                o.grabPos.xy += bump * _DistortStrength;
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 frag(v2f i): SV_TARGET
            {
                float edgeFactor = abs(dot(i.viewDir, i.normal));
                float oneMinusEdgeFactor = 1 - abs(dot(i.viewDir, i.normal));
                float opacity = smoothstep(0, 1, oneMinusEdgeFactor);
                opacity = pow(opacity, _EdgeThickness);
                fixed4 ramp = tex2D(_RampTex, float2(oneMinusEdgeFactor, 0.5)) * _Color;

                float3 half = normalize(_WorldSpaceLightPos0 + i.viewDir);
                float NdotH = dot(half, i.normal);
                float3 spec;
                if (NdotH > 0.89 + 0.01 * (10.0 - _SpecSize)) spec = fixed3(1, 1, 1) * _LightColor0.rgb / 0.05 * _Shininess;
                else spec = fixed3(0, 0, 0);

                fixed4 col = lerp(tex2Dproj(_BackgroundTexture, i.grabPos) + fixed4(spec, 0), ramp, opacity);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
