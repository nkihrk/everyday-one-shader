Shader "Custom/OutlineShader_Ver3.3"
{
    Properties
    {
        [Header(Main Content)]
        _Switch ("Switch", Range(0.0, 1.0)) = 0
        _MainTex ("Texture", 2D) = "white" { }
        _MainColor ("Main Color", Color) = (0, 0, 0, 0)
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.0
        _Switch3 ("Transparency", Range(0.0, 1.0)) = 0
        [Header(Rim lighting)]
        _Switch4 ("Switch", Range(0.0, 1.0)) = 0
        _RimTint ("Rim Tint", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Float) = 1
        _RimAmplitude ("Rim Amplitude", Float) = 1
        [Header(Outline)]
        _Switch2 ("Switch", Range(0.0, 1.0)) = 0
        _OutlineColor ("Outline Color", Color) = (1, 1, 1, 1)
        _OutlineWidth ("Outline Width", Float) = 0.1
        [MaterialToggle] _Hoge ("Toggle Outline Mask", Float) = 0
        _OutlineMask ("Outline Mask Texture", 2D) = "white" { }
        [Header(Outline Texture)]
        _Switch5 ("Switch", Range(0.0, 1.0)) = 0
        _OutlineTex ("Outline Texture", 2D) = "white" { }
        [Header(Rainbow Shading)]
        [MaterialToggle] _Hoge3 ("X-axis direction", Float) = 0
        [MaterialToggle] _Hoge4 ("Y-axis direction", Float) = 0
        _Saturation ("Saturation", Range(0.0, 1.0)) = 0.8
        _Luminosity ("Luminosity", Range(0.0, 1.0)) = 0.57
        _Spread ("Spread", Range(0.5, 10.0)) = 2.36
        _SpeedRainbow ("Speed", Range(-10.0, 10.0)) = 0.2
        [Header(Glitch)]
        [Toggle(TOGGLE_GLITCH)] _Hoge2 ("Toggle Glitch", Float) = 0
        _GlitchIntensity ("Glitch Intensity", Float) = 0.1
        _GlitchSpeed ("Glitch Speed", Range(0.01, 100)) = 5.0
        [Header(Surface Waving)]
        [Toggle(TOGGLE_YURAYURA_OUTLINE)] _Hoge5 ("Toggle waving movement(Outline)", Float) = 0
        [Toggle(TOGGLE_YURAYURA_MESH)] _Hoge6 ("Toggle waving movement(Mesh)", Float) = 0
        _WaveScale ("Wave Scale", Float) = 1.0
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

    float rand(float3 co)
    {
        return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
    }
    ENDCG
    
    SubShader
    {
        Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
        LOD 100

        GrabPass
        {
            "_BackgroundTexture"
        }

        Pass
        {
            Tags { "LightMode" = "ShadowCaster" }
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag

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
            Tags { "LightMode" = "ForwardBase" }
            Cull Front
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            #pragma shader_feature TOGGLE_GLITCH
            #pragma shader_feature TOGGLE_YURAYURA_OUTLINE
            #pragma shader_feature TOGGLE_YURAYURA_MESH
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
                float2 uvM: TEXCOORD1;
                float4 color: COLOR;
            };

            struct v2f
            {
                float4 vertex: SV_POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
                float2 uvM: TEXCOORD1;
                float4 color: TEXCOORD2;
                float4 localvertex: TEXCOORD3;
                float4 pos: TEXCOORD4;
                UNITY_FOG_COORDS(5)
                SHADOW_COORDS(6)
            };

            uniform float _Cutoff;
            uniform float _OutlineWidth;
            uniform float _Hoge;
            uniform float _Hoge3;
            uniform float _Hoge4;
            uniform float _Switch2;
            uniform float _Switch5;
            uniform fixed4 _OutlineColor;
            uniform fixed _Saturation;
            uniform fixed _Luminosity;
            uniform half _Spread;
            uniform half _SpeedRainbow;
            uniform float _WaveScale;
            uniform float _GlitchIntensity;
            uniform float _GlitchSpeed;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform sampler2D _OutlineTex; uniform float4 _OutlineTex_ST;
            uniform sampler2D _OutlineMask; uniform float4 _OutlineMask_ST;
            
            v2f vert(appdata v)
            {
                v2f o;
                _OutlineWidth /= 1000;
                o.uvM = v.uvM;
                float3 outlineMask = lerp(0, tex2Dlod(_OutlineMask, float4(TRANSFORM_TEX(o.uvM, _OutlineMask), 0.0, 0)).rgb, _Hoge);
                #ifdef TOGGLE_YURAYURA_OUTLINE
                    v.vertex.xyz += v.normal * rand(normalize(v.normal) * (_Time.w / 8000000)) / (1000. * _WaveScale);
                #else
                    v.vertex.xyz += v.normal * (1.0 - outlineMask.rgb) * _OutlineWidth;
                #endif
                #ifdef TOGGLE_GLITCH
                    v.vertex.x += _GlitchIntensity * (step(0.5, sin(_Time.y * 2.0 + v.vertex.y * 1.0)) * step(0.99, sin(_Time.y * _GlitchSpeed * 0.5)));
                #endif
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.color = v.color;
                o.localvertex = v.vertex;
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                TRANSFER_SHADOW(o)
                return o;
            };
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed4 lPos = i.localvertex / _Spread;
                half time = _Time.y * _SpeedRainbow / _Spread;
                fixed hue = 0;
                hue += lerp(0, (-lPos.x) / 2., _Hoge3);
                hue += lerp(0, (-lPos.y) / 2., _Hoge4);
                hue += lerp(((-lPos.x - lPos.y - lPos.z) / 3.) / 2., 0, hue);
                hue += time;
                while(hue < 0.0) hue += 1.0;
                while(hue > 1.0) hue -= 1.0;
                fixed4 hsl = fixed4(hue, _Saturation, _Luminosity, 1.0);
                fixed4 OutlineTex = tex2D(_OutlineTex, i.uv);
                fixed4 col = lerp(lerp(_OutlineColor, HSLtoRGB(hsl), _Switch2), OutlineTex, _Switch5);
                col.rgb *= SHADOW_ATTENUATION(i);
                clip(col.a - _Cutoff);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }
            Cull Off
            
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma multi_compile_fwdbase
            #pragma shader_feature TOGGLE_GLITCH
            #pragma shader_feature TOGGLE_YURAYURA_OUTLINE
            #pragma shader_feature TOGGLE_YURAYURA_MESH
            
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex: POSITION;
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
                float4 color: COLOR;
            };

            struct v2f
            {
                float4 vertex: SV_POSITION;
                float2 uv: TEXCOORD0;
                float4 color: TEXCOORD1;
                float4 grabPos: TEXCOORD2;
                float3 normal: TEXCOORD3;
                float4 wpos: TEXCOORD4;
                float4 pos: TEXCOORD5;
                UNITY_FOG_COORDS(6)
                SHADOW_COORDS(7)
            };

            uniform float4 _MainColor;
            uniform float _Cutoff;
            uniform float _Switch;
            uniform float _Switch3;
            uniform float _Switch4;
            uniform float _RimPower;
            uniform float _RimAmplitude;
            uniform float4 _RimTint;
            uniform float _WaveScale;
            uniform float _GlitchIntensity;
            uniform float _GlitchSpeed;
            uniform sampler2D _MainTex; float4 _MainTex_ST;
            uniform sampler2D _BackgroundTexture;
            
            v2f vert(appdata v)
            {
                #ifdef TOGGLE_YURAYURA_MESH
                    v.vertex.xyz += v.normal * rand(normalize(v.normal) * (_Time.w / 8000000)) / (1000. * _WaveScale);
                #endif
                #ifdef TOGGLE_GLITCH
                    v.vertex.x += _GlitchIntensity * (step(0.5, sin(_Time.y * 2.0 + v.vertex.y * 1.0)) * step(0.99, sin(_Time.y * _GlitchSpeed * 0.5)));
                #endif
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.grabPos = ComputeGrabScreenPos(o.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                fixed4 MainColor = _MainColor;
                fixed4 stColor = v.color;
                o.color = lerp(MainColor, stColor, _Switch);
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                TRANSFER_SHADOW(o)
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            };
            
            fixed4 frag(v2f i): SV_Target
            {
                float3 normalDir = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
                float NNdotV = 1 - dot(normalDir, viewDir);
                float rim = pow(NNdotV, _RimPower) * _RimAmplitude;
                fixed4 Color = i.color;
                fixed4 MainTex = tex2D(_MainTex, i.uv) * Color;
                half4 bgcolor = tex2Dproj(_BackgroundTexture, i.grabPos) * Color;
                fixed4 col = lerp(lerp(Color, MainTex, _Switch), bgcolor, _Switch3);
                fixed3 colRim = col.rgb * _RimTint.a + rim * _RimTint.rgb;
                col.rgb = lerp(col.rgb, colRim, _Switch4);
                col.rgb *= SHADOW_ATTENUATION(i);
                clip(col.a - _Cutoff);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}