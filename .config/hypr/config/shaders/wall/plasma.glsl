void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy * vec2(iResolution.x / iResolution.y, 1.0) * 3.0;
    float t = iTime * 0.4;
    float v = sin(uv.x + t) + sin(uv.y * 1.3 - t) + sin((uv.x + uv.y) * 0.7 + t * 1.3) + sin(length(uv - 1.5) * 2.0 - t);
    vec3 col = 0.5 + 0.5 * cos(6.2831 * (v * 0.25 + vec3(0.0, 0.33, 0.67)));
    fragColor = vec4(col * 0.45, 1.0);
}
