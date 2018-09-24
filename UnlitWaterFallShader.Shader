Shader "Custom/UnlitWaterFallShader"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "white" { }
        _DispTex ("Displacement Texture", 2D) = "white" { }
        _ColorTop ("Color Top", Color) = (1, 1, 1, 1)
        _ColorBottom ("Color Bottom", Color) = (0, 0, 0, 1)
        _Speed ("Speed", Float) = 1.0
        _Scale ("Scale", Float) = 1.0
        _DispAmount ("Disp Amount", Float) = 1.0
        _HeightThreshold ("Height Threshold", Float) = 0.0
        _SpeedFoam ("Foam Speed", Float) = 1.0
        _DispAmountFoam ("Foam Disp Amount", Float) = 1.0
        _Cutoff ("Cutoff", Range(0.0, 1.0)) = 0.0
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _CullMode ("Cull Mode", int) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100
        Blend SrcAlpha OneMinusSrcAlpha
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
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
            };

            uniform sampler2D _NoiseTex; uniform float4 _NoiseTex_ST;
            uniform sampler2D _DispTex; uniform float4 _DispTex_ST;
            uniform float _Speed;
            uniform fixed4 _ColorTop;
            uniform fixed4 _ColorBottom;
            uniform float _Scale;
            uniform float _HeightThreshold;
            uniform float _Cutoff;
            uniform float _DispAmount;
            uniform float _SpeedFoam;
            uniform float _DispAmountFoam;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _NoiseTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                float2 dispTex = tex2D(_DispTex, float2(i.uv.x, i.uv.y * 0.1 + _Time.x * _Speed)).xy;
                dispTex = ((dispTex * 2) - 1) * _DispAmount;
                float2 dispFoam = tex2D(_DispTex, float2(i.uv.x, i.uv.y + _Time.x * _SpeedFoam)).xy;
                dispFoam = ((dispFoam * 2) - 1) * _DispAmountFoam;
                float4 noise = tex2D(_NoiseTex, float2(i.uv.x * 1.5, i.uv.y * 0.3 + _Time.y / 3.0) - dispTex);
                float a = round(noise.r * 3.0) / 3.0;

                fixed4 col = lerp(fixed4(1, 1, 1, 1), pow(lerp(lerp(_ColorBottom, _ColorTop, i.uv.y), fixed4(1, 1, 1, 1), a), max(0, _Scale)), step(_HeightThreshold * 0.1, pow(dispFoam.r + i.uv.y, 2)));
                col.a = 1 - _Cutoff;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
