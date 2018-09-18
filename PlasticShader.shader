Shader "Custom/PlasticShader"
{
    Properties
    {
        _RampTex ("Ramp Texture", 2D) = "white" { }
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Density ("Density", Float) = 1.0
        _Thickness ("Thickness", Float) = 1.0
        _SpecSize ("Spec Size", Float) = 1.0
        _Shininess ("Shininess", Float) = 1.0
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _CullMode ("Cull Mode", int) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull[_CullMode]

        Pass
        {
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
                float4 wpos: TEXCOORD2;
                float3 normal: TEXCOORD3;
            };

            uniform sampler2D _RampTex; uniform float4 _RampTex_ST;
            uniform float _Density;
            uniform float _Thickness;
            uniform fixed4 _Color;
            uniform float _SpecSize;
            uniform float4 _LightColor0;
            uniform float _Shininess;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _RampTex);
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.wpos).xyz;
                float NdotV = saturate(dot(i.normal, viewDir));
                float NNdotV = 1 - NdotV;
                NNdotV = (NNdotV * 0.5) + 0.5;
                float opacity = smoothstep(0, 1, NNdotV);
                opacity = pow(NNdotV, max(0, _Density)) * _Thickness;
                fixed4 ramp = tex2D(_RampTex, float2(NNdotV, 0.5)) * _Color;

                float3 half = normalize(_WorldSpaceLightPos0 + viewDir);
                float NdotH = dot(half, i.normal);
                float3 spec;
                if (NdotH > 0.89 + 0.01 * (10.0 - _SpecSize)) spec = fixed3(1, 1, 1) * _LightColor0.rgb / 0.05 * _Shininess;
                else spec = fixed3(0, 0, 0);

                fixed4 col = lerp(fixed4(0, 0, 0, 0), ramp, opacity) + fixed4(spec, 0);

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
