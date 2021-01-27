//
//  ZYGLKView.m
//  ESCOpenGLESShowImageDemo
//
//  Created by 海龙 on 2020/11/17.
//  Copyright © 2020 xiang. All rights reserved.
//

#import "ZYGLKView.h"

/**
 定义顶点类型
 */
typedef struct {
    GLKVector3 positionCoord; // (X, Y, Z)
    GLKVector4 colorCoord;    // (R, G, B, A)
    GLKVector2 textureCoord; // (U, V)
} SenceVertex;

@interface ZYGLKView()<GLKViewDelegate> {
    
}
//@property (nonatomic, assign) float screenScale;

@property (nonatomic, strong) GLKBaseEffect *baseEffect;

@property (nonatomic, assign) GLuint vertexBuffer; ///顶点缓冲数据vbo
@property (nonatomic, assign) GLuint bufferIndexEBO; ///顶点数据EBO
@property (nonatomic, assign) GLuint elementCount; //Number of entries in the index buffer


///测试用
@property (nonatomic, strong) UIImageView *testImageView;
@end

@implementation ZYGLKView

-(instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context {
    if (self = [super initWithFrame:frame context:context]) {
        self.delegate = self;
        
//        dispatch_async(dispatch_get_main_queue(), ^{
            [self initOnce];
            [self setupLayer];
            [self setupTexure];
            [self setupData];
            [self setNeedsDisplay];
//        });
    }
    return self;
}

- (void)dealloc {
    [self destoryVertex];
//    [self destoryFrameBuffers];
//    [self destoryRanderBuffers];
    [EAGLContext setCurrentContext:nil];
}

- (void)initOnce {
    [EAGLContext setCurrentContext:self.context];
//    self.screenScale = [UIScreen mainScreen].scale;
//    self.contentScaleFactor = self.screenScale;
//    self.delegate = self;
    self.baseEffect = [[GLKBaseEffect alloc] init];
    //配置视图创建的渲染缓冲区
    self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;
    self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
}

- (void)setupLayer {
    [EAGLContext setCurrentContext:self.context];
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    NSDictionary *dict = @{kEAGLDrawablePropertyRetainedBacking:@(NO),
                           kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
                           };
    ///设置图层是否透明
    [eaglLayer setOpaque:NO];
    [eaglLayer setDrawableProperties:dict];
}

- (void)setupData {
    [EAGLContext setCurrentContext:self.context];
    [self destoryVertex];
    NSInteger rows = 1;
    NSInteger colums = 1;
    GLsizeiptr verticesSize = (rows+1)*(colums+1)*sizeof(SenceVertex);
    SenceVertex *vertices = (SenceVertex *)malloc(verticesSize);
    
    for (int y = 0; y < colums+1; ++y) {
        GLfloat tv = (GLfloat)y/colums;
        GLfloat vy = tv * 2 - 1;
        for (int x = 0; x < rows+1; ++x) {
            ///从上往下算三角形的顶点数据
            SenceVertex *v = &vertices[(colums - y) * (rows + 1) + x];
            ///从下往上算三角形的顶点数据
//            SenceVertex *v = &vertices[y*(rows+1) + x];
//            v->u = (GLfloat)x/rows;
//            v->v = tv;
//            v->x = v->u*2 - 1;
//            v->y = vy;
//            v->z = 0;
//            [self.fangCheng transGridWithVertex:v];
            v->textureCoord.x = (GLfloat)x/rows;
            v->textureCoord.y = tv;
            v->positionCoord.x = (GLfloat)x/rows * 2 - 1;
            v->positionCoord.y = vy;
            v->positionCoord.z = 0;
            ///color 为源颜色
            v->colorCoord.r = 1.0;
            v->colorCoord.g = 0.5;
            v->colorCoord.b = 0.5;
            v->colorCoord.a = 1.0;
        }
    }
    
    ///顶点数据缓存
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, verticesSize, (GLvoid *)vertices, GL_DYNAMIC_DRAW);
    free(vertices);
    
//    glGenBuffers(1, &_colorVBO);
//    glBindBuffer(GL_ARRAY_BUFFER, _colorVBO);
//    glBufferData(GL_ARRAY_BUFFER, colorSize, (GLvoid *)colors, GL_STATIC_DRAW);
//    free(colors);
    _elementCount = rows*colums*2*3;
    
    GLsizeiptr indicesSize = _elementCount*sizeof(GLushort);//Two triangles per square, 3 indices per triangle
    GLushort *indices = (GLushort *)malloc(indicesSize);
    
    for (int y=0; y<colums; ++y) {
        for (int x=0; x<rows; ++x) {
            int i = y*(rows+1) + x;
            int idx = y*rows + x;
            assert(i < _elementCount*3-1);
            indices[idx*6+0] = i;
            indices[idx*6+1] = i + 1;
            indices[idx*6+2] = i + rows + 1;
            indices[idx*6+3] = i + 1;
            indices[idx*6+4] = i + rows + 2;
            indices[idx*6+5] = i + rows + 1;
        }
    }
    ///索引
    glGenBuffers(1, &_bufferIndexEBO);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _bufferIndexEBO);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, indicesSize, (GLvoid *)indices, GL_STATIC_DRAW);
    free(indices);
}

- (void)setupTexure {
    [EAGLContext setCurrentContext:self.context];
    //2.设置纹理参数
    //纹理坐标原点是左下角,但是图片显示原点应该是左上角.
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:@(1),GLKTextureLoaderOriginBottomLeft, nil];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ZYTest" ofType:@"jpg"];
    NSError *error = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfFile:filePath options:options error:&error];

    //3.使用苹果GLKit 提供GLKBaseEffect 完成着色器工作(顶点/片元)
    self.baseEffect.texture2d0.enabled = GL_TRUE;
    self.baseEffect.texture2d0.name = textureInfo.name;
}

- (void)destoryVertex {
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_bufferIndexEBO);
    _vertexBuffer = _bufferIndexEBO = _elementCount = 0;
}

- (void)glClear {
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

- (void)drawGL {
    [EAGLContext setCurrentContext:self.context];
//    glViewport(0, 0, _viewPortWidth, _viewPortHeight);
    [self glClear];
    [self.baseEffect prepareToDraw];
    glEnable(GL_BLEND);
    
    /*(将要画上去的颜色称为“源颜色”，把原来的颜色称为“目标颜色”。)
    如果设置了glBlendFunc(GL_ONE, GL_ZERO);，则表示完全使用源颜色，完全不使用目标颜色，因此画面效果和不使用混合的时候一致（当然效率可能会低一点点）。如果没有设置源因子和目标因子，则默认情况就是这样的设置。
    如果设置了glBlendFunc(GL_ZERO, GL_ONE);，则表示完全不使用源颜色，因此无论你想画什么，最后都不会被画上去了。（但这并不是说这样设置就没有用，有些时候可能有特殊用途）
     */
    glBlendFunc(GL_ONE,GL_ONE_MINUS_SRC_ALPHA);
    
    //绑定顶点缓冲数据vbo
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_TRUE, sizeof(SenceVertex), (void *)offsetof(SenceVertex, positionCoord));

    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_TRUE, sizeof(SenceVertex), (void *)offsetof(SenceVertex, colorCoord));

    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_TRUE, sizeof(SenceVertex), (void *)offsetof(SenceVertex, textureCoord));

    ///绑定顶点索引数据
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _bufferIndexEBO);

    //3.开始绘制
//    glDrawArrays(GL_TRIANGLES, 0, 4);
    glDrawElements(GL_TRIANGLES, _elementCount, GL_UNSIGNED_SHORT, (void *)0);
}

- (void)glkView:(nonnull GLKView *)view drawInRect:(CGRect)rect {
    NSLog(@"");
    [self drawGL];
}

-(UIImageView *)testImageView {
    if (!_testImageView) {
        _testImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _testImageView.image = [UIImage imageNamed:@"ZYTest.jpg"];
    }
    return _testImageView;
}

@end
