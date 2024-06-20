Shader "Custom/VHSEffect"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        // CRT
        _ShakeIntensity ("Shake Intensity", Range(0, 1)) = 0.2
        _ShakeThickness ("Shake Thickness", Range(0, 1)) = 0.2
        _ShakeSpeed ("Shake Speed", Range(0, 10)) = 1
        _VerticalOffset ("Vertical Offset", Range(0, 1)) = 0.1

        // distortion
        _DistortionStrength ("Distortion Strength", Range(0, 1)) = 0.5
        _DistortionOffset ("Distortion Offset", Float) = 0.0

        // glitch (falowanie pionowe)
        _GlitchIntensity ("Glitch Intensity", Range(0, 1)) = 0.5

        // tension (rozciąganie i ściskanie ekranu)
        _TensionIntensity ("Tension Intensity", Range(0, 1)) = 0.205
        _TensionSize ("Tension Size", Range(0, 0.1)) = 0.002

        // color shift (RGB kanaly)
        _ColorShift ("Color Shift Amount", Range(0, 1)) = 0.05

        // jitter effect
        _TapeJitter ("Tape Jitter Amount", Range(0, 1)) = 0.02
        _JitterEnabled ("Enable Jitter", Float) = 0.0

        // waving (falowanie poziome)
        _WaveFrequency ("Wave Frequency", Float) = 10.0
        _WaveAmplitude ("Wave Amplitude", Float) = 0.05
        _WaveSpeed ("Wave Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float2 texcoord : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float _ShakeIntensity;
            float _ShakeThickness;
            float _ShakeSpeed;
            float _VerticalOffset;
            float _DistortionStrength;
            float _DistortionOffset;
            float _GlitchIntensity;
            float _TensionIntensity;
            float _TensionSize;
            float _ColorShift;
            float _TapeJitter;
            float _JitterEnabled;
            float _WaveFrequency;
            float _WaveAmplitude;
            float _WaveSpeed;

            // przetwarzanie danych wierzchołków
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                // obliczenie przesunięcia jittera, jeśli włączone
                float jitter = _JitterEnabled > 0.5 ? sin(_Time.y * 10) * _TapeJitter : 0.0;
                o.texcoord = v.texcoord + float2(jitter, 0);
                return o;
            }

            // funkcja do przetwarzania pikseli
            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.texcoord;

                // CRT
                float shake = sin(uv.y * _ShakeThickness + _Time.y * _ShakeSpeed) * _ShakeIntensity;
                uv.y += shake - _VerticalOffset * 0.1;

                // distortion
                float distortion = frac(sin((uv.x + _DistortionOffset) * 10 + uv.y * 20) * 44000) * _DistortionStrength * 0.1;
                uv += distortion;

                // glitch
                float glitchOffset = _GlitchIntensity * (sin(_Time.y * 20.0) + sin(uv.y * 40.0)) * 0.5;
                uv.x += glitchOffset;
                // dodanie dodatkowych zakłóceń pionowych
                if (frac(sin(dot(uv.xy, float2(13, 78))) * 44000) < _GlitchIntensity * 0.5)
                {
                    uv.y += _GlitchIntensity * 0.1;
                }

                // tension (rozciąganie i ściskanie obrazu)
                float tension = sin(uv.y * _TensionSize * 100) * _TensionIntensity;
                uv.y += tension;

                // VHS - kolor, szum i linie
                float noise = frac(sin(dot(uv * _Time.y, float2(13, 78))) * 44000);
                float lines = step(0.5, frac(uv.y * 30.0 + _Time.y * 5.0)) * 0.1;
                // przesunięcie kolorów RGB
                float2 redUV = uv + float2(_ColorShift, 0);
                float2 greenUV = uv;
                float2 blueUV = uv - float2(_ColorShift, 0);

                fixed4 redCol = tex2D(_MainTex, redUV);
                fixed4 greenCol = tex2D(_MainTex, greenUV);
                fixed4 blueCol = tex2D(_MainTex, blueUV);
                // lączenie kolorów w jeden kolor VHS
                fixed4 vhsCol = fixed4(redCol.r, greenCol.g, blueCol.b, 1.0);
                // dodanie szumu i linii do koloru
                vhsCol.rgb += noise * 0.1;
                vhsCol.rgb *= 1.0 - lines;

                // waving
                uv.y += sin(uv.x * _WaveFrequency + _Time.y * _WaveSpeed) * _WaveAmplitude;

                // pobieranie koloru z tekstury
                fixed4 col = tex2D(_MainTex, uv);
                col.rgb = lerp(col.rgb, vhsCol.rgb, 0.5);

                return col;
            }
            ENDCG
        }
    }
}
