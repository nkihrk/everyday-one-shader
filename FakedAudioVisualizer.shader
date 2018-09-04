Shader "Custom/FakedAudioVisualizer"
{
    Properties
    {
        [Header(Noise)]
        _MainTex ("Noise Texture", 2D) = "white" { }
        [MaterialToggle] _Hoge ("Use Perlin Noise", Float) = 0
        _ColorTop ("Color Top", Color) = (0.226, 0.000, 0.615, 1.)
        _ColorBot ("Color Bottom", Color) = (1.9, 0.55, 0., 1.)
        _Factor ("Factor", Float) = 0.
        _NoiseSpeed ("Noise Speed", Float) = 1.
        _NoisePower ("Noise Power", Float) = 5.
        _ClipRange ("Clipping Range", Range(0., 4.)) = 0.
        [Header(Compression)]
        _Xcomp ("X-axis direction", Range(0., 1.)) = 0.
        _Ycomp ("Y-axis direction", Range(0., 1.)) = 0.
        _Zcomp ("Z-axis direction", Range(0., 1.)) = 0.
        [Header(Rainbow Shading)]
        _Switch ("Switch", Range(0., 1.)) = 0.
        [MaterialToggle] _Hoge2 ("X-axis direction", Float) = 0
        [MaterialToggle] _Hoge3 ("Y-axis direction", Float) = 0
        _Saturation ("Saturation", Range(0.0, 1.0)) = 0.8
        _Luminosity ("Luminosity", Range(0.0, 1.0)) = 0.57
        _Spread ("Spread", Range(0.5, 10.0)) = 2.36
        _SpeedRainbow ("Speed", Range(-10.0, 10.0)) = 0.2
    }
    
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
    
    float C2F(float3 Color)
    {
        int c1 = 255;
        int c2 = 255 * 255;
        int c3 = 255 * 255 * 255;
        return(Color.x * 255 + Color.y * 255 * c1 + Color.z * 255 * c2) / c3;
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
    
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        Cull Off
        LOD 100
        
        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #pragma shader_feature TOGGLE_SHADOW_CASTING
            
            #include "UnityCG.cginc"
            
            struct v2f
            {
                V2F_SHADOW_CASTER;
            };
            
            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }
            
            float4 frag(v2f i): SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
            
        }
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geom
            
            #include "UnityCG.cginc"
            
            struct v2g
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
                float4 localvertex: TEXCOORD1;
            };
            
            struct g2f
            {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                fixed4 col: COLOR;
                float4 localvertex: TEXCOORD1;
                UNITY_FOG_COORDS(2)
            };
            
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform fixed4 _ColorTop;
            uniform fixed4 _ColorBot;
            uniform float _NoiseSpeed;
            uniform float _NoisePower;
            uniform float _Factor;
            uniform float _ClipRange;
            uniform float _Xcomp;
            uniform float _Ycomp;
            uniform float _Zcomp;
            uniform float _Switch;
            uniform fixed _Saturation;
            uniform fixed _Luminosity;
            uniform half _Spread;
            uniform half _SpeedRainbow;
            uniform float _Hoge;
            uniform float _Hoge2;
            uniform float _Hoge3;
            
            v2g vert(appdata_base v)
            {
                v2g o;
                v.vertex.xyz = v.vertex.xyz - v.vertex.xyz * float3(_Xcomp, _Ycomp, _Zcomp);
                o.vertex = v.vertex;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.normal = v.normal;
                o.localvertex = v.vertex;
                return o;
            }
            
            [maxvertexcount(24)]
            void geom(triangle v2g v[3], inout TriangleStream < g2f > tristream)
            {
                g2f o;
                o.localvertex = v[0].localvertex;
                
                float3 a = v[1].vertex - v[0].vertex;
                float3 b = v[2].vertex - v[0].vertex;
                float3 normalFace = normalize(cross(a, b));
                float2 uv = v[0].uv;
                float angle = 180 * UNITY_PI * (_Time.x / 100 * _NoiseSpeed);
                float pivot = 0.5;
                float x = (uv.x - pivot) * cos(angle) - (uv.y - pivot) * sin(angle) + pivot;
                float y = (uv.x - pivot) * sin(angle) + (uv.y - pivot) * cos(angle) + pivot;
                uv = float2(x, y);
                fixed4 noiseTex = tex2Dlod(_MainTex, float4(uv, 0, 0));
                float c2f = pow(pow(_NoisePower, _NoisePower), C2F(noiseTex.rgb));
                float c = fBm(v[0].uv * _Time.x * _NoiseSpeed);
                fixed4 prlNoise = fixed4(c, c, c, 1);
                float prln = pow(pow(_NoisePower, _NoisePower), C2F(prlNoise.rgb));
                float4 normalNoise = lerp(float4(c2f, c2f, c2f, 1), float4(prln, prln, prln, 1), _Hoge);
                _Factor /= 50;
                
                for (int i = 0; i < 3; i ++)
                {
                    int inext = (i + 1) % 3;
                    
                    o.pos = UnityObjectToClipPos(v[i].vertex);
                    o.uv = v[i].uv;
                    o.col = _ColorBot;
                    UNITY_TRANSFER_FOG(o, o.pos);
                    tristream.Append(o);
                    
                    o.pos = UnityObjectToClipPos(v[i].vertex + float4(normalFace, 0) * _Factor * normalNoise);
                    o.uv = v[i].uv;
                    o.col = _ColorTop;
                    UNITY_TRANSFER_FOG(o, o.pos);
                    tristream.Append(o);
                    
                    o.pos = UnityObjectToClipPos(v[inext].vertex);
                    o.uv = v[inext].uv;
                    o.col = _ColorBot;
                    UNITY_TRANSFER_FOG(o, o.pos);
                    tristream.Append(o);
                    
                    tristream.RestartStrip();
                    
                    o.pos = UnityObjectToClipPos(v[i].vertex + float4(normalFace, 0) * _Factor * normalNoise);
                    o.uv = v[i].uv;
                    o.col = _ColorTop;
                    UNITY_TRANSFER_FOG(o, o.pos);
                    tristream.Append(o);
                    
                    o.pos = UnityObjectToClipPos(v[inext].vertex);
                    o.uv = v[inext].uv;
                    o.col = _ColorBot;
                    UNITY_TRANSFER_FOG(o, o.pos);
                    tristream.Append(o);
                    
                    o.pos = UnityObjectToClipPos(v[inext].vertex + float4(normalFace, 0) * _Factor * normalNoise);
                    o.uv = v[inext].uv;
                    o.col = _ColorTop;
                    UNITY_TRANSFER_FOG(o, o.pos);
                    tristream.Append(o);
                    
                    tristream.RestartStrip();
                }
                
                for (int j = 0; j < 3; j ++)
                {
                    o.pos = UnityObjectToClipPos(v[j].vertex + float4(normalFace, 0) * _Factor * normalNoise);
                    o.uv = v[j].uv;
                    o.col = _ColorTop;
                    UNITY_TRANSFER_FOG(o, o.pos);
                    tristream.Append(o);
                }
                
                tristream.RestartStrip();
                
                for (int k = 0; k < 3; k ++)
                {
                    o.pos = UnityObjectToClipPos(v[k].vertex);
                    o.uv = v[k].uv;
                    o.col = _ColorBot;
                    UNITY_TRANSFER_FOG(o, o.pos);
                    tristream.Append(o);
                }
                
                tristream.RestartStrip();
            }
            
            fixed4 frag(g2f i): SV_Target
            {
                fixed4 lPos = i.localvertex / _Spread;
                half time = _Time.y * _SpeedRainbow / _Spread;
                fixed hue = 0;
                hue += lerp(0, (-lPos.x) / 2., _Hoge2);
                hue += lerp(0, (-lPos.y) / 2., _Hoge3);
                hue += lerp(((-lPos.x - lPos.y - lPos.z) / 3.) / 2., 0, hue);
                hue += time;
                while(hue < 0.0) hue += 1.0;
                while(hue > 1.0) hue -= 1.0;
                fixed4 hsl = fixed4(hue, _Saturation, _Luminosity, 1.0);
                fixed4 col = lerp(i.col, HSLtoRGB(hsl), _Switch);
                UNITY_APPLY_FOG(i.fogCoord, col);
                clip((5 - _ClipRange) - i.col);
                return col;
            }
            ENDCG
            
        }
    }
}