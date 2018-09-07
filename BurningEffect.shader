Shader "Custom/BurningEffect"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" { }
        _NoiseTex ("Noise Texture", 2D) = "white" { }
        _FireTex ("Fire Texture", 2D) = "black" { }
        _Color ("Dissolve Color(only available when no Fire Texture)", Color) = (1, 1, 1, 1)
        _DissolveSpeed ("Dissolve Speed", Float) = 1.0
        [MaterialToggle] _Hoge ("Toggle Automatic Dissolve", int) = 0
        _BurnThreshold ("Dissolve Threshold", Range(0.0, 1.0)) = 0.0
        _Shininess ("Shininess", Float) = 10
        [Enum(OFF, 0, FRONT, 1, BACK, 2)] _CullMode ("Cull Mode", int) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100
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

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _NoiseTex; uniform float4 _NoiseTex_ST;
            uniform sampler2D _FireTex; uniform float4 _FireTex_ST;
            uniform fixed4 _Color;
            uniform int _Hoge;
            uniform float _DissolveSpeed;
            uniform float _ColorThreshold1;
            uniform float _ColorThreshold2;
            uniform float _BurnThreshold;
            uniform float _Shininess;
            
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
                fixed4 mainTex = tex2D(_MainTex, i.uv);
                float4 noiseTex = tex2D(_NoiseTex, i.uv);
                fixed4 fireTex = tex2D(_FireTex, i.uv);
                fireTex = lerp(_Color, fireTex, saturate(length(fireTex) * 100));

                float t = lerp(_BurnThreshold, _Time.x, _Hoge);

                float a = t * (_DissolveSpeed + 0.9);
                float dissolve1 = noiseTex.r - a > 0;
                fixed4 col = (1 - dissolve1) * fixed4(0, 0, 0, 1) + dissolve1 * fireTex * _Shininess;

                float b = t * (_DissolveSpeed + 1.3);
                float dissolve2 = noiseTex.r - b > 0;
                col = (1 - dissolve2) * col + dissolve2 * mainTex;

                float c = t * _DissolveSpeed;
                if(noiseTex.r - c < 0) discard;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
