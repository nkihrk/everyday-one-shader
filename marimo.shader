Shader "Custom/MARIMO"
{

    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" { }
        _NormalMap ("Normalmap", 2D) = "bump" { }
        _Color ("Color", color) = (1, 1, 1, 0)
        _SpecColor ("Specular color", color) = (0.5, 0.5, 0.5, 0.5)
        _MinDist ("Min Distance", Range(0.1, 50)) = 10
        _MaxDist ("Max Distance", Range(0.1, 50)) = 25
        _TessFactor ("Tessellation", Range(1, 50)) = 10
        _NoiseTex ("Noise Texture", 2D) = "black" {}
        _NoiseSpeed ("Noise Speed", Range(0.0, 10)) = 1.0
        _NoisePower ("Noise Power", Range(0.0, 3.0)) = 1.0
        _NoiseFactor ("Noise Factor", Range(0.0, 10)) = 1.0
    }

    CGINCLUDE
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
        Tags { "RenderType" = "Opaque" }
        Cull Off
        
        CGPROGRAM
        
        #pragma surface surf BlinnPhong addshadow fullforwardshadows vertex:disp tessellate:tessDistance nolightmap
        #pragma target 5.0
        #include "Tessellation.cginc"

        uniform sampler2D _MainTex;
        uniform sampler2D _NormalMap;
        uniform sampler2D _NoiseTex;
        uniform fixed4 _Color;
        uniform float _TessFactor;
        uniform float _MinDist;
        uniform float _MaxDist;
        uniform float _NoiseSpeed;
        uniform float _NoisePower;
        uniform float _NoiseFactor;

        struct appdata
        {
            float4 vertex: POSITION;
            float4 tangent: TANGENT;
            float3 normal: NORMAL;
            float2 texcoord: TEXCOORD0;
        };

        struct Input
        {
            float2 uv_MainTex;
        };

        float4 tessDistance(appdata v0, appdata v1, appdata v2)
        {
            return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, _MinDist, _MaxDist, _TessFactor);
        }

        void disp(inout appdata v)
        {
            float2 uv = v.texcoord;
            float angle = 180 * UNITY_PI * (_Time.x / 100 * _NoiseSpeed);
            float pivot = 0.5;
            float x = (uv.x - pivot) * cos(angle) - (uv.y - pivot) * sin(angle) + pivot;
            float y = (uv.x - pivot) * sin(angle) + (uv.y - pivot) * cos(angle) + pivot;
            uv = float2(x, y);
            fixed4 noiseTex = tex2Dlod(_NoiseTex, float4(uv, 0, 0));
            float c2f = pow(pow(_NoisePower, _NoisePower), C2F(noiseTex.rgb));
            float c = fBm(v.texcoord.xy * _Time.x * _NoiseSpeed);
            fixed4 prlNoise = lerp(fixed4(c, c, c, 1), fixed4(c2f, c2f, c2f, 1), saturate(noiseTex * 100));

            v.vertex.xyz += v.normal * prlNoise.xyz * _NoiseFactor;
        }

        void surf(Input IN, inout SurfaceOutput o)
        {
            half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            o.Specular = 0.2;
            o.Gloss = 1.0;
            o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));
        }
        
        ENDCG
        
    }

    FallBack "Diffuse"
}