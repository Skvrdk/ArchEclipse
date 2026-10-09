precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;
void main() {
    vec4 c = texture2D(tex, v_texcoord);
    gl_FragColor = vec4(c.r, c.g * 0.82, c.b * 0.55, c.a);
}
