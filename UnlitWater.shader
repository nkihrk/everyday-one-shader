Shader "Custom/UnlitWater"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "white" { }
        _DispTex ("Displacement Texture", 2D) = "white" { }
        _ColorTop ("Color Top", Color) = (1, 1, 1, 1)
        _ColorBottom ("Color Bottom", Color) = (0, 0, 0, 1)
        _Scale ("Scale", Float) = 1.0
        _Speed ("Speed", Float) = 1.0
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

            uniform sampler2D _NoiseTex; uniform float4 _NoiseTex_ST;
            uniform sampler2D _DispTex; uniform float4 _DispTex_ST;
            uniform fixed4 _ColorTop;
            uniform fixed4 _ColorBottom;
            uniform float _Scale;
            uniform float _Speed;
            
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
                float4 dispTex = tex2D(_DispTex, float2(i.uv.x, i.uv.y + _Time.y / 5.0 * _Speed));
                float4 noise = tex2D(_NoiseTex, float2(i.uv.x * 4, i.uv.y - dispTex.g));
                float a = round(noise.r * 3.0) / 3.0;

                fixed4 col = pow(lerp(lerp(_ColorBottom, _ColorTop, i.uv.y), fixed4(1, 1, 1, 1), a), max(0, _Scale));
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
