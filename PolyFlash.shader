Shader "Custom/PolyFlash_ver2.2"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _Color ("Color", Color) = (1, 1, 1, 1)
        [Header(Rainbow Shading Settings)]
        _Switch ("Switch", Range(0., 1.)) = 0.
        [Toggle] _Switch2 ("X-axis direction", Float) = 0
        [Toggle] _Switch3 ("Y-axis direction", Float) = 0
        _Saturation ("Saturation", Range(0.0, 1.0)) = 0.8
        _Luminosity ("Luminosity", Range(0.0, 1.0)) = 0.57
        _Spread ("Spread", Range(0.5, 10.0)) = 2.36
        _SpeedRainbow ("Speed", Range(-10.0, 10.0)) = 0.2
        [Header(UV Scroll Settings)]
        _ScrollSpeeds ("Scroll Speed", Float) = 0.1
        _Speed ("Rotation Speed", Float) = 1.0
        [Toggle]_uvScroll ("Scroll UV", Float) = 0
        [Toggle]_SwitchX ("Rotate around X axis", Float) = 0
        [Toggle]_SwitchY ("Rotate around Y axis", Float) = 0
        [Toggle]_SwitchZ ("Rotate around Z axis", Float) = 0
        [Toggle]_SwitchR ("Rotate randomly", Float) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Geometry" "RenderType" = "Opaque" "LightMode" = "ForwardBase" }
        LOD 100
        
        Pass
        {
            Cull Off
            CGPROGRAM
            
            #pragma vertex vert
            #pragma geometry geom
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"
            
            struct v2g
            {
                float4 pos: SV_POSITION;
                float2 uv: TEXCOORD0;
                float4 vertex: TEXCOORD1;
                float3 normal: TEXCOORD2;
            };
            
            struct g2f
            {
                float2 uv: TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos: SV_POSITION;
                float4 localvertex: TEXCOORD3;
            };
            
            float rand(float3 co)
            {
                return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 45.5432))) * 43758.5453);
            }
            
            uniform float4 _Color;
            uniform float _Switch;
            uniform float _Switch2;
            uniform float _Switch3;
            uniform fixed _Saturation;
            uniform fixed _Luminosity;
            uniform half _Spread;
            uniform half _SpeedRainbow;
            uniform float _ScrollSpeeds;
            uniform float _Speed;
            uniform float _uvScroll;
            uniform float _SwitchX;
            uniform float _SwitchY;
            uniform float _SwitchZ;
            uniform float _SwitchR;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            
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
            
            float2x2 rotateFnc(float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                return float2x2(cosa, -sina, sina, cosa);
            }
            
            float4 RotateX(float4 a, float degrees)
            {
                float2x2 m = rotateFnc(degrees);
                return float4(mul(m, a.xz), a.yw).xzyw;
            }
            
            float4 RotateY(float4 a, float degrees)
            {
                float2x2 m = rotateFnc(degrees);
                return float4(a.x, mul(m, a.yz), a.w).xyzw;
            }
            
            float4 RotateZ(float4 a, float degrees)
            {
                float2x2 m = rotateFnc(degrees);
                return float4(mul(m, a.xy), a.zw).xyzw;
            }
            
            float4 RotateR(float4 a, float degrees)
            {
                float2x2 m = rotateFnc(degrees);
                float4 a2 = float4(mul(m, a.xz), a.yw).xzyw;
                float4 a3 = float4(a2.x, mul(m, a2.yz), a2.w).xyzw;
                return float4(mul(m, a3.xy), a3.zw).xyzw;
            }
            
            float4 allInOne(float4 a)
            {
                float4 aRotate = 0;
                aRotate += lerp(0, RotateX(a, _Time.z * _Speed * 10), _SwitchX);
                aRotate += lerp(0, RotateY(a, _Time.z * _Speed * 10), _SwitchY);
                aRotate += lerp(0, RotateZ(a, _Time.z * _Speed * 10), _SwitchZ);
                aRotate += lerp(0, RotateR(a, _Time.z * _Speed * 10), _SwitchR);
                return aRotate;
            }
            
            v2g vert(appdata_full v)
            {
                v2g o;
                o.vertex = v.vertex;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                o.normal = v.normal;
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            [maxvertexcount(3)]
            void geom(triangle v2g v[3], inout TriangleStream < g2f > tristream)
            {
                g2f o;
                
                o.uv = (v[0].uv + v[1].uv + v[2].uv) / 3;
                
                for (int i = 0; i < 3; i ++)
                {
                    o.pos = v[i].pos;
                    o.localvertex = v[i].vertex;
                    tristream.Append(o);
                }
            }
            
            fixed4 frag(g2f i): SV_Target
            {
                fixed4 lPos = i.localvertex / _Spread;
                half time = _Time.y * _SpeedRainbow / _Spread;
                fixed hue = 0;
                hue += lerp(0, (-lPos.x) / 2., _Switch2);
                hue += lerp(0, (-lPos.y) / 2., _Switch3);
                if(hue == 0)
                {
                    hue += ((-lPos.x - lPos.y - lPos.z) / 3.) / 2.;
                }
                hue += time;
                while(hue < 0.0) hue += 1.0;
                while(hue > 1.0) hue -= 1.0;
                fixed4 hsl = fixed4(hue, _Saturation, _Luminosity, 1.0);
                // sample the texture
                fixed4 col = tex2D(_MainTex, lerp(allInOne(float4(i.uv, 0, 0)), i.uv + _ScrollSpeeds * _Time.z, _uvScroll));
                col.rgb *= lerp(_Color, HSLtoRGB(hsl), _Switch);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Deffuse"
}
