attribute vec4 Position;
attribute vec4 PosColor;
attribute vec2 TextureCoords;
varying vec2 TextureCoordsVarying;
varying vec4 v_Colors;

void main (void) {
    gl_Position = Position;
    TextureCoordsVarying = TextureCoords;
    v_Colors = PosColor;
}
