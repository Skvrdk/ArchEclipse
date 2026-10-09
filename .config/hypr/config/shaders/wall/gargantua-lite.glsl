// Single-pass black hole with an accretion disk, a lensed ring and a cheap analytic bloom.
// Inspired by the multi-pass "Gargantua With HDR Bloom" on Shadertoy; papertoy runs one pass only, so the scene and the glow are fused here.
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

vec3 heat(float t) { // dark red -> orange -> white
    return pow(vec3(1.0, 0.55, 0.18), vec3(2.2 - 1.6 * clamp(t, 0.0, 1.0))) * (0.4 + 1.8 * t);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 p = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    float r = length(p);
    float t = iTime;
    const float shadow = 0.13;

    // stars, pulled outwards around the hole (lensing)
    vec2 sp = p * (1.0 + 0.012 / max(r * r, 0.002)) * 90.0;
    float star = step(0.985, hash(floor(sp))) * smoothstep(0.45, 0.0, length(fract(sp) - 0.5));
    vec3 col = vec3(star) * vec3(0.8, 0.9, 1.0) * 0.8 * smoothstep(shadow, shadow + 0.04, r);

    // disk seen almost edge-on: an ellipse, spinning faster near the centre, brighter on the approaching side
    vec2 d = vec2(p.x, p.y / 0.16);
    float rd = length(d);
    float ang = atan(d.y, d.x) - t * 0.9 / (rd + 0.2);
    float swirl = 0.55 + 0.45 * noise(vec2(ang * 3.0, rd * 14.0));
    float band = smoothstep(0.17, 0.24, rd) * smoothstep(0.62, 0.30, rd);
    float doppler = 0.65 + 0.55 * (-p.x / (rd + 0.3));
    float disk = band * swirl * doppler * (0.5 + 0.9 / (1.0 + 7.0 * rd));
    float front = step(p.y, 0.0); // the lower half passes in front of the hole, the upper half behind it
    float hidden = (1.0 - front) * (1.0 - smoothstep(shadow, shadow + 0.01, r));
    col += heat(disk) * disk * (1.0 - hidden);

    // light from the far side of the disk bent over and under the hole
    vec2 l = vec2(p.x, p.y / 0.85);
    float rl = length(l);
    float lens = smoothstep(0.13, 0.16, rl) * smoothstep(0.34, 0.17, rl);
    float swirl2 = 0.6 + 0.4 * noise(vec2(atan(l.y, l.x) * 3.0 - t * 0.9 / (rl + 0.2), rl * 16.0));
    col += heat(lens * swirl2 * 0.9) * lens * swirl2 * 0.85 * (0.7 + 0.5 * (-p.x / (rl + 0.3)));

    // photon ring and the black shadow
    col += vec3(1.0, 0.8, 0.55) * 0.012 / (abs(r - shadow - 0.012) + 0.006);
    col *= smoothstep(shadow - 0.006, shadow + 0.006, r) + hidden * 0.0 + (front * 0.0);
    col = mix(col, heat(disk) * disk, front * step(r, shadow) * band);

    // cheap bloom: a wide soft halo around the whole thing
    col += vec3(1.0, 0.55, 0.25) * 0.03 / (0.04 + abs(rd - 0.3) * abs(rd - 0.3) * 12.0 + r * 0.8);

    // tone mapping and grading (from the original post pass)
    col *= 1.6;
    col = pow(col, vec3(1.5));
    col = col / (1.0 + col);
    col = pow(col, vec3(1.0 / 1.5));
    col = mix(col, col * col * (3.0 - 2.0 * col), vec3(1.0));
    col = pow(clamp(col * 1.01, 0.0, 1.0), vec3(0.7 / 2.2));
    fragColor = vec4(col, 1.0);
}
