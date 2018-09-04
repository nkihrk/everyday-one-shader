Shader "Custom/RotateWireVoxel"
{
    Properties
    {
        [Header(Voxel Setting)]
        _Scale ("Box Scale", float) = 0.005
        _Color ("Wire Color", Color) = (1., 1., 1., 1.)
        _WireframeVal ("Wireframe width", Range(0., 0.34)) = 0.05
        [Header(Rotate Settings)]
        _Speed ("Rotation Speed", Float) = 1.0
        [Toggle]_SwitchX ("Rotate around X axis", Float) = 0.0
        [Toggle]_SwitchY ("Rotate around Y axis", Float) = 0.0
        [Toggle]_SwitchZ ("Rotate around Z axis", Float) = 0.0
        [Toggle]_SwitchR ("Rotate randomly", Float) = 0.0
    }
    
    CGINCLUDE
    #include "UnityCG.cginc"
    
    uniform float _Speed;
    uniform float _SwitchX;
    uniform float _SwitchY;
    uniform float _SwitchZ;
    uniform float _SwitchR;
    
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
    
    #define convertToClip1(v) o.vertex = UnityObjectToClipPos(v); o.bary = float3(1., 0., 0.); UNITY_TRANSFER_FOG(o, o.vertex); TriStream.Append(o);
    #define convertToClip2(v) o.vertex = UnityObjectToClipPos(v); o.bary = float3(0., 1., 0.); UNITY_TRANSFER_FOG(o, o.vertex); TriStream.Append(o);
    #define convertToClip3(v) o.vertex = UnityObjectToClipPos(v); o.bary = float3(0., 0., 1.); UNITY_TRANSFER_FOG(o, o.vertex); TriStream.Append(o);
    #define makeTri(v1, v2, v3) convertToClip1(v1) convertToClip2(v2) convertToClip3(v3) TriStream.RestartStrip();
    ENDCG
    
    SubShader
    {
        Tags { "Queue" = "Transparent" }
        LOD 100
        
        pass
        {
            Cull Front
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float2 uv: TEXCOORD0;
                float4 vertex: POSITION;
                float4 color: COLOR;
            };
            
            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 color: TEXCOORD2;
                float4 wpos: TEXCOORD3;
                float4 vertex: SV_POSITION;
                float3 bary: TEXCOORD5;
            };
            
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _Scale;
            uniform float _WireframeVal;
            uniform fixed4 _Color;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.color = v.color;
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                o.bary = float3(0., 0., 0.);
                return o;
            }
            
            [maxvertexcount(36)]
            void geo(triangle v2f v[3], inout TriangleStream < v2f > TriStream)
            {
                float4 wpos = (v[0].wpos + v[1].wpos + v[2].wpos) / 3;
                float4 vertex = (v[0].vertex + v[1].vertex + v[2].vertex) / 3;
                
                v2f o = v[0];
                o.wpos = wpos;
                
                float4 a[8];
                a[0] = float4(1, 1, 1, 0);
                a[1] = float4(1, 1, -1, 0);
                a[2] = float4(1, -1, 1, 0);
                a[3] = float4(1, -1, -1, 0);
                a[4] = float4(-1, 1, 1, 0);
                a[5] = float4(-1, 1, -1, 0);
                a[6] = float4(-1, -1, 1, 0);
                a[7] = float4(-1, -1, -1, 0);
                float4 vertexR[8];
                for (int i = 0; i < 8; i ++)
                {
                    vertexR[i] = allInOne(a[i]);
                    if (vertexR[i].x == 0 && vertexR[i].y == 0 && vertexR[i].z == 0)
                    {
                        vertexR[i] = a[i];
                    }
                }
                float4 v0 = (vertexR[0] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v1 = (vertexR[1] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v2 = (vertexR[2] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v3 = (vertexR[3] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v4 = (vertexR[4] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v5 = (vertexR[5] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v6 = (vertexR[6] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v7 = (vertexR[7] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                makeTri(v0, v2, v3);
                makeTri(v3, v1, v0);
                makeTri(v5, v7, v6);
                makeTri(v6, v4, v5);
                makeTri(v4, v0, v1);
                makeTri(v1, v5, v4);
                makeTri(v7, v3, v2);
                makeTri(v2, v6, v7);
                makeTri(v6, v2, v0);
                makeTri(v0, v4, v6);
                makeTri(v5, v1, v3);
                makeTri(v3, v7, v5);
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                if(!any(bool3(i.bary.x < _WireframeVal, i.bary.y < _WireframeVal, i.bary.z < _WireframeVal))) discard;
                return _Color;
            }
            ENDCG
            
        }
        
        pass
        {
            Cull Back
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma geometry geo
            
            #include "UnityCG.cginc"
            
            struct appdata
            {
                float2 uv: TEXCOORD0;
                float4 vertex: POSITION;
                float4 color: COLOR;
            };
            
            struct v2f
            {
                float2 uv: TEXCOORD0;
                float4 color: TEXCOORD2;
                float4 wpos: TEXCOORD3;
                float4 vertex: SV_POSITION;
                float3 bary: TEXCOORD5;
            };
            
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            uniform float _Scale;
            uniform float _WireframeVal;
            uniform fixed4 _Color;
            
            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = v.vertex;
                o.color = v.color;
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                o.bary = float3(0., 0., 0.);
                return o;
            }
            
            [maxvertexcount(36)]
            void geo(triangle v2f v[3], inout TriangleStream < v2f > TriStream)
            {
                float4 wpos = (v[0].wpos + v[1].wpos + v[2].wpos) / 3;
                float4 vertex = (v[0].vertex + v[1].vertex + v[2].vertex) / 3;
                
                v2f o = v[0];
                o.wpos = wpos;
                
                float4 a[8];
                a[0] = float4(1, 1, 1, 0);
                a[1] = float4(1, 1, -1, 0);
                a[2] = float4(1, -1, 1, 0);
                a[3] = float4(1, -1, -1, 0);
                a[4] = float4(-1, 1, 1, 0);
                a[5] = float4(-1, 1, -1, 0);
                a[6] = float4(-1, -1, 1, 0);
                a[7] = float4(-1, -1, -1, 0);
                float4 vertexR[8];
                for (int i = 0; i < 8; i ++)
                {
                    vertexR[i] = allInOne(a[i]);
                    if (vertexR[i].x == 0 && vertexR[i].y == 0 && vertexR[i].z == 0)
                    {
                        vertexR[i] = a[i];
                    }
                }
                float4 v0 = (vertexR[0] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v1 = (vertexR[1] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v2 = (vertexR[2] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v3 = (vertexR[3] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v4 = (vertexR[4] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v5 = (vertexR[5] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v6 = (vertexR[6] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                float4 v7 = (vertexR[7] + float4(0, 0, 0, 1)) * _Scale + float4(vertex.xyz, 0);
                makeTri(v0, v2, v3);
                makeTri(v3, v1, v0);
                makeTri(v5, v7, v6);
                makeTri(v6, v4, v5);
                makeTri(v4, v0, v1);
                makeTri(v1, v5, v4);
                makeTri(v7, v3, v2);
                makeTri(v2, v6, v7);
                makeTri(v6, v2, v0);
                makeTri(v0, v4, v6);
                makeTri(v5, v1, v3);
                makeTri(v3, v7, v5);
            }
            
            fixed4 frag(v2f i): SV_Target
            {
                if(!any(bool3(i.bary.x < _WireframeVal, i.bary.y < _WireframeVal, i.bary.z < _WireframeVal))) discard;
                return _Color;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
