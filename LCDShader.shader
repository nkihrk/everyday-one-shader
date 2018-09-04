// https://www.alanzucconi.com/2016/05/04/lcd-shader/
Shader "Custom/LCDShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _LCDTex ("LCD Texture", 2D) = "white" { }
        _Pixels ("Pixels", Vector) = (10, 10, 0, 0)
        _LCDPixels ("LCD Pixels", Vector) = (3, 3, 0, 0)
        //_DistanceOne ("Distance of full effect", Float) = 0.5
        //_DistanceZero ("Distance of zero effect", Float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100

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
                float4 wpos: TEXCOORD2;
            };

            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _LCDTex; uniform float4 _LCDTex_ST;
            uniform float4 _Pixels;
            uniform float4 _LCDPixels;
            //uniform float _DistanceOne;
            //uniform float _DistanceZero;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                float2 uv = round(i.uv * _Pixels.xy + 0.5) / _Pixels.xy;
                float2 uv_lcd = i.uv * _Pixels.xy / _LCDPixels;
                fixed4 a = tex2D(_MainTex, uv);
                fixed4 d = tex2D(_LCDTex, uv_lcd);
                //float dist = distance(_WorldSpaceCameraPos, i.wpos);
                //float alpha = saturate
                //(
                //    (dist - _DistanceOne) / (_DistanceZero - _DistanceOne)
                //);
                //fixed4 col = lerp(a * d, a, alpha);
                fixed4 col = a * d;
                col.a = 1;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
