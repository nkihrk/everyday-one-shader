Shader "Custom/RotateMesh"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        _Color ("Main Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Speed ("Rotation Speed", Float) = 1.0
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
        [Toggle]_SwitchX ("Rotate around X axis", Float) = 0.0
        [Toggle]_SwitchY ("Rotate around Y axis", Float) = 0.0
        [Toggle]_SwitchZ ("Rotate around Z axis", Float) = 0.0
        [Toggle]_SwitchR ("Rotate randomly", Float) = 0.0        
        //_EmissionTex ("Emission", 2D) = "white" {}
        //_EmissionColor("Emission Color", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Pass
        {
            Tags { "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
            LOD 100

            Cull Off
            ZWrite On
            
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
            };

            uniform sampler2D _MainTex;  uniform float4 _MainTex_ST;
            uniform float _Speed;
            uniform float _SwitchX;
            uniform float _SwitchY;
            uniform float _SwitchZ;
            uniform float _SwitchR;
            uniform float _Cutoff;
            uniform fixed4 _Color;
            uniform half4 _EmissionColor;
            uniform sampler2D _EmissionTex;

            float4 RotateMeshX(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float4(mul(m, vertex.xz), vertex.yw).xzyw;
            }

            float4 RotateMeshY(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float4(vertex.x, mul(m, vertex.yz), vertex.w).xyzw;
            }

            float4 RotateMeshZ(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                return float4(mul(m, vertex.xy), vertex.zw).xyzw;
            }

            float4 RotateMeshR(float4 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180.0;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, -sina, sina, cosa);
                float4 vertex2 = float4(mul(m, vertex.xz), vertex.yw).xzyw;
                float4 vertex3 = float4(vertex2.x, mul(m, vertex2.yz), vertex2.w).xyzw;
                return float4(mul(m, vertex3.xy), vertex3.zw).xyzw;
            }
            
            v2f vert(appdata v)
            {
                v2f o;
                float4 vertexRotate = 0;
                vertexRotate += lerp(0, RotateMeshX(v.vertex, _Time.z * _Speed * 10), _SwitchX);
                vertexRotate += lerp(0, RotateMeshY(v.vertex, _Time.z * _Speed * 10), _SwitchY);
                vertexRotate += lerp(0, RotateMeshZ(v.vertex, _Time.z * _Speed * 10), _SwitchZ);
                vertexRotate += lerp(0, RotateMeshR(v.vertex, _Time.z * _Speed * 10), _SwitchR);
                if (vertexRotate.x == 0 && vertexRotate.y == 0 && vertexRotate.z == 0)
                {
                    vertexRotate = v.vertex;
                }
                o.vertex = UnityObjectToClipPos(vertexRotate);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * _Color;
                float t = ((2 * _SinTime.w * _CosTime.w) + 1.0) * 0.5;
                float e = tex2D(_EmissionTex, i.uv).a * t;
                //col += _EmissionColor * e;
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
