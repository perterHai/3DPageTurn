precision mediump float;

uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;
varying vec4 v_Colors;

void main (void) {
    vec4 mask = texture2D(Texture, TextureCoordsVarying);
    float alpha = v_Colors[3];
    
    vec4 tempColor = (v_Colors * mask) / 1.0;
    gl_FragColor = tempColor;
}
