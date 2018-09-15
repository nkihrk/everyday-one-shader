Shader "Custom/BurningOutlineShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white"
        _NoiseTex ("Noise Texture", 2D) = "white" { }
        _DistortTex ("Distortion Texture", 2D) = "white" { }
        _Color ("Main Flame Color", Color) = (0.7647059, 0.1843136, 0.2380698, 1)
        _Color2 ("Flame Rim Color", Color) = (1, 0.4667664, 0.235294, 1)
        _OutlineWidth ("Outline Width",Float) = 0.375
        _Strength ("Strength", Float) = 0.125
        _GradientPow ("Gradient Power", Float) = 1.41
        _GradientThickness ("Gradient Thickness", Float) = 5.8
        _EdgePow ("Edge Power", Float) = 20
        _Hight ("Flame Hight", Float) = 1.0
        _Edge ("Rim Strength", Float) = 0.46
        _Shininess ("Rim Shininess", Float) = 2.34
        _Distort ("Distortion", Float) = 1.75
        _SpeedX ("Speed X", Float) = 3.64
        _SpeedY ("Speed Y", Float) = 5.56
        _PushX ("Push X", Float) = 0.0
        _PushY ("Push Y", Float) = 0.0
        _PushZ ("Push Z", Float) = 0.0
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _CullMode ("Cull Mode", int) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
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
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                float3 viewDir: TEXCOORD2;
                float3 normal: TEXCOORD3;
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _NoiseTex; uniform float4 _NoiseTex_ST;
            uniform sampler2D _DistortTex; uniform float4 _DistortTex_ST;
            uniform float _OutlineWidth;
            uniform float _GradientPow;
            uniform float _GradientThickness;
            uniform float _EdgePow;
            uniform fixed4 _Color;
            uniform float _Hight;
            uniform fixed4 _Color2;
            uniform float _Edge;
            uniform float _Shininess;
            uniform float _Distort;
            uniform float _SpeedX;
            uniform float _SpeedY;
            uniform float _Strength;
            uniform float _PushX;
            uniform float _PushY;
            uniform float _PushZ;
            
            v2f vert(appdata v)
            {
                v2f o;
                //v.vertex.xyz += v.normal * _OutlineWidth;
                o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.viewDir = normalize(_WorldSpaceCameraPos - mul(unity_ObjectToWorld, v.vertex)).xyz;
                float4 normalP = mul(UNITY_MATRIX_MVP, float4(v.normal, 0));
                normalP = normalize(normalP);
                o.vertex.xy += normalP.xy * _OutlineWidth;
                o.vertex.x += 0.01 * _PushX;
                o.vertex.y += 0.1 * _PushY;
                o.vertex.z += 0.01 * normalP.z * _PushZ;
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                float2 uv = i.vertex.xy / _ScreenParams.xy;

                float NdotV = 1 - max(0, dot(i.normal, i.viewDir));

                NdotV = pow(NdotV, max(0, _Strength));

                float4 gradient = lerp(fixed4(1, 1, 1, 1), fixed4(0, 0, 0, 0), NdotV);

                float2 uvD = float2(uv.x, uv.y) * _Distort;
                fixed4 distort = tex2D(_DistortTex, uvD);

                float2 uvN = float2(uv.x * _SpeedX - distort.r, uv.y - distort.g - _Time.x * _SpeedY);
                fixed4 noise = tex2D(_NoiseTex, uvN);
                
                float a = saturate(pow(gradient.x, _GradientPow) * _GradientThickness);
                gradient = float4(a, a, a, a);
                noise += gradient;
                noise.a = (noise.r + noise.g + noise.b) / 3.0;
                float b = max(0, _EdgePow * 20);
                float edgePow = saturate(pow(noise.a, b));
                float edgePow2 = saturate(pow(noise.a + lerp(_Edge, 0, NdotV), b)) - edgePow;

                fixed4 col = edgePow * _Color + edgePow2 * _Color2 * _Shininess;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
        Pass
        {
            Cull[_CullMode]
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float2 uv: TEXCOORD0;
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
