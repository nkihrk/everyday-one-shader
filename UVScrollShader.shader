Shader "Custom/UVScrollShader"
{
    Properties
    {
        _EmissionColor ("Emission Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _MainTex ("Base (RGB) Trans (A)", 2D) = "white" { }
        _Color ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Cutoff ("Alpha cutoff", Range(0.0, 1.0)) = 0.5
        _ScrollSpeeds ("Scroll Speeds", vector) = (-0.01, 0, 0, 0)
        _EmissionTex ("Emission", 2D) = "white" { }
        [Toggle(TURNING_LIGHT)] _Hoge ("Turning Light", Float) = 0
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
        LOD 200

        Cull Off
        ZWrite on
        
        CGPROGRAM
        
        #pragma surface surf Lambert alphatest:_Cutoff
        #pragma shader_feature TURNING_LIGHT

        fixed4 _Color;
        float4 _ScrollSpeeds;
        half4 _EmissionColor;
        sampler2D _MainTex;
        sampler2D _EmissionTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        void surf(Input IN, inout SurfaceOutput o)
        {
            float4 d = _ScrollSpeeds * _Time.z;
            half4 c = tex2D(_MainTex, IN.uv_MainTex + d) * _Color;
            float t = ((2 * _SinTime.w * _CosTime.w) + 1.0) * 0.5;
            float e = tex2D(_EmissionTex, IN.uv_MainTex + d).a * t;
            o.Albedo = c.rgb;
            o.Alpha = c.a;
            #ifdef TURNING_LIGHT
                o.Emission = _EmissionColor * e;
            #endif
        }
        ENDCG
        
    }
    fallback "Diffuse"
}
