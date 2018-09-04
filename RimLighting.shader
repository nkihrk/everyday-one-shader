Shader "Custom/RimLighting"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" { }
        [Header(Rim lighting Settings)]
        _RimTint ("Rim Tint", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Float) = 1
        _RimAmplitude ("Rim Amplitude", Float) = 1
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        LOD 100

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
                float3 normal: NORMAL;
                float2 uv: TEXCOORD0;
                float4 color: COLOR;
            };

            struct v2f
            {
                float4 vertex: SV_POSITION;
                float2 uv: TEXCOORD0;
                float4 color: TEXCOORD1;
                float3 normal: TEXCOORD2;
                float4 wpos: TEXCOORD3;
                UNITY_FOG_COORDS(4)
            };

            uniform float _RimPower;
            uniform float _RimAmplitude;
            uniform float4 _RimTint;
            uniform sampler2D _MainTex; uniform float4 _MainTex_ST;
            
            v2f vert(appdata v)
            {
                v2f o;
           
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                o.wpos = mul(unity_ObjectToWorld, v.vertex);
                o.color = v.color;
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            };
            
            fixed4 frag(v2f i): SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 normalDir = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wpos.xyz);
                float NNdotV = 1 - dot(normalDir, viewDir);
                float rim = pow(NNdotV, _RimPower) * _RimAmplitude;
                col.rgb = col.rgb * _RimTint.a + rim * _RimTint.rgb;
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
            
        }
    }
    Fallback "Diffuse"
}
