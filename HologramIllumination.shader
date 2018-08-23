Shader "Custom/HologramIllumination"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Saturation ("Saturation", Range(0.0, 1.0)) = 0.8
        _Luminosity ("Luminosity", Range(0.0, 1.0)) = 0.57
        _Spread ("Spread", Range(0.5, 10.0)) = 2.36
        _SpeedRainbow ("Rainbow Speed", Range(-10.0, 10.0)) = 0.2
        _Speed ("Scanline Speed", Range(1.0, 30)) = 1.0
        _Frequency ("Scanline Frequency", Range(1.0, 30)) = 1.0
        [Enum(OFF, 0, ON, 1)] _Hoge("Toggle fBm Noise", int) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100
        Blend SrcColor One
        ZWrite Off
        Cull Off

        CGINCLUDE
        inline fixed hueToRGB(float v1, float v2, float vH)
        {
            if (vH < 0.0) vH += 1.0;
            if(vH > 1.0) vH -= 1.0;
            if((6.0 * vH) < 1.0) return(v1 + (v2 - v1) * 6.0 * vH);
            if((2.0 * vH) < 1.0) return(v2);
            if((3.0 * vH) < 2.0) return(v1 + (v2 - v1) * ((2.0 / 3.0) - vH) * 6.0);
            return v1;
        }
        
        inline fixed4 HSLtoRGB(fixed4 hsl)
        {
            fixed4 rgb = fixed4(0.0, 0.0, 0.0, hsl.w);
            
            if(hsl.y == 0)
            {
                rgb.xyz = hsl.zzz;
            }
            else
            {
                float v1;
                float v2;
                if(hsl.z < 0.5) v2 = hsl.z * (1 + hsl.y);
                else v2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
                v1 = 2.0 * hsl.z - v2;
                rgb.x = hueToRGB(v1, v2, hsl.x + (1.0 / 3.0));
                rgb.y = hueToRGB(v1, v2, hsl.x);
                rgb.z = hueToRGB(v1, v2, hsl.x - (1.0 / 3.0));
            }
            return rgb;
        }
        
        fixed2 rand(fixed2 st)
        {
            st = fixed2(dot(st, fixed2(127.1, 311.7)), dot(st, fixed2(269.5, 183.3)));
            return - 1.0 + 2.0 * frac(sin(st) * 43758.5453123);
        }
        
        float perlinNoise(fixed2 st)
        {
            fixed2 p = floor(st);
            fixed2 f = frac(st);
            fixed2 u = f * f * (3.0 - 2.0 * f);
            float v00 = rand(p + fixed2(0, 0));
            float v10 = rand(p + fixed2(1, 0));
            float v01 = rand(p + fixed2(0, 1));
            float v11 = rand(p + fixed2(1, 1));
            return lerp(lerp(dot(v00, f - fixed2(0, 0)), dot(v10, f - fixed2(1, 0)), u.x), lerp(dot(v01, f - fixed2(0, 1)), dot(v11, f - fixed2(1, 1)), u.x), u.y) + 0.5f;
        }
        
        float fBm(fixed2 st)
        {
            float f = 0;
            fixed2 q = st;
            f += 0.5000 * perlinNoise(q); q = q * 2.01;
            f += 0.2500 * perlinNoise(q); q = q * 2.02;
            f += 0.1250 * perlinNoise(q); q = q * 2.03;
            f += 0.0625 * perlinNoise(q); q = q * 2.01;
            return f;
        }
        ENDCG
        
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
            };

            struct v2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex: SV_POSITION;
                float4 wpos: TEXCOORD2;
                float4 localvertex: TEXCOORD3;
            };

            uniform sampler2D _MainTex;
            uniform float4 _MainTex_ST;
            uniform fixed4 _Color;
            uniform fixed _Saturation;
            uniform fixed _Luminosity;
            uniform half _Spread;
            uniform half _SpeedRainbow;
            uniform float _Speed;
            uniform float _Frequency;
            uniform int _Hoge;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.localvertex = v.vertex;
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed4 lPos = i.localvertex / _Spread;
                half time = _Time.y * _SpeedRainbow / _Spread;
                fixed hue = ((-lPos.x - lPos.y - lPos.z) / 3.) / 2.;
                hue += time;
                while(hue < 0.0) hue += 1.0;
                while(hue > 1.0) hue -= 1.0;
                fixed4 hsl = fixed4(hue, _Saturation, _Luminosity, 1.0);

                fixed4 col = tex2D(_MainTex, i.uv) * _Color * HSLtoRGB(hsl) * max(0, sin(i.wpos.y * 100 * _Frequency + _Time.x * 100 * _Speed) * 10) * 1.0;
                col *= max(0, sin(i.wpos.x * 100 * _Frequency + _Time.x * 100 * _Speed)) * 0.9;
                col *= max(0, sin(i.wpos.z * 100 * _Frequency + _Time.x * 100 * _Speed)) * 0.8;
                col *= lerp(fixed4(1, 1, 1, 1), fBm(float2(dot(col.rg, col.gb), dot(col.gb, col.br))) * 2, _Hoge);

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
