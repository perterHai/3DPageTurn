//
//  ZYGLView.m
//  ESCOpenGLESShowImageDemo
//
//  Created by 海龙 on 2020/10/28.
//  Copyright © 2020 xiang. All rights reserved.
//

#import "ZYGLView.h"
#import "ZYShaderHelper.h"
#import "ZYOCFangCheng.h"
#import "UIView+Screenshot.h"

/*
 参考文档:
 https://blog.csdn.net/jeffasd/article/details/52152956
 https://www.cnblogs.com/liangliangh/p/4116164.html
 http://www.lymanli.com/categories/OpenGL-ES/
 https://learnopengl-cn.github.io/01%20Getting%20started/04%20Hello%20Triangle/
 https://developer.apple.com/library/archive/documentation/3DDrawing/Conceptual/OpenGLES_ProgrammingGuide/OpenGLESontheiPhone/OpenGLESontheiPhone.html#//apple_ref/doc/uid/TP40008793-CH101-SW3
 https://www.jianshu.com/p/5989b045430f
 https://colin1994.github.io/2017/11/11/OpenGLES-Lesson04/#%E5%8F%82%E6%95%B0%E9%99%90%E5%AE%9A%E7%AC%A6
 https://zhuanlan.zhihu.com/p/165881917
 https://www.cnblogs.com/java20130723/archive/2012/07/19/3212243.html
 
 ///颜色混合模式算法
 https://www.cgspread.com/3551.html
 */
@interface ZYGLView() {
    //Model-View-Proj matrix.
    GLfloat mvp[16];
}

@property (nonnull, nonatomic, strong) ZYOCFangCheng *fangCheng;
@property (nonatomic, assign) float screenScale;
//@property (nonatomic, strong) EAGLContext *context;
//@property (nonatomic)SenceVertex *vertexs; //顶点数据

@property (nonatomic, assign) GLuint frameBuffer; ///frame缓存
@property (nonatomic, assign) GLuint renderBuffer; ///颜色缓存
@property (nonatomic, assign) GLuint sampleFramebuffer; //多采样
@property (nonatomic, assign) GLuint sampleColorRenderbuffer; //多采样
@property (nonatomic, assign) GLint viewPortWidth; ///可视宽度
@property (nonatomic, assign) GLint viewPortHeight; ///可视高度

/**
 着色器相关
 */
@property (nonatomic, assign) GLuint positionSlot; ///顶点
@property (nonatomic, assign) GLuint posColorSlot; ///顶点颜色
@property (nonatomic, assign) GLuint textureSlot;  ///纹理
@property (nonatomic, assign) GLuint textureCoordsSlot;///纹理坐标
@property (nonatomic, assign) GLuint program; ///着色器, 因为只有一个,所以可以直接使用
/**
 绘制相关
 */
@property (nonatomic, assign) GLuint currentTexture;///当前纹理
@property (nonatomic, assign) GLuint current2Texture;///当前第二纹理
@property (nonatomic, assign) GLuint currentVAO; ///顶点数组vao
@property (nonatomic, assign) GLuint vertexBuffer; ///顶点缓冲数据vbo
@property (nonatomic, assign) GLuint bufferIndexEBO; ///顶点数据EBO
@property (nonatomic, assign) GLuint elementCount; //Number of entries in the index buffer

///测试用
@property (nonatomic, strong) UIImageView *testImageView;
@property (nonatomic, strong) UIImageView *test2ImageView;

@end

@implementation ZYGLView

//+(Class)layerClass {
//    return [CAEAGLLayer class];
//}

-(instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context {
    if (self = [super initWithFrame:frame context:context]) {
        self.backgroundColor = [UIColor clearColor];
//        self.antialiasing = YES;
        self.screenScale = [UIScreen mainScreen].scale;
        [self resetGLConfig];
        
        ///设置图片到纹理
        ///测试用
        [self addSubview:self.testImageView];
        [self addSubview:self.test2ImageView];
        [self drawDefaultView];
//        self.test2ImageView.alpha = 0;
        [self drawGL];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)resetGLConfig {
    ///设置view的scale
    [self setContentScaleFactor:self.screenScale];
    ///设置layer属性
    [self setupLayer];
    ///创建glcontext
//    [self setupContext];
    ///设置buffers
    [self setupBuffers];
    ///设置着色器
    [self setupGPUShaderPrograme];
    ///清空纹理
    [self destoryTextures:_currentTexture];
    ///设置纹理
    self.currentTexture = [self generateTexture:0];
    
    [self destoryTextures:_current2Texture];
    
    self.current2Texture = [self generateTexture:1];
    ///初始化gl数据
    [self setupInitGL];
    
    ///测试翻页从下往上绘制图片
//    CGPoint point1 = CGPointMake(0, 0);
//    CGPoint point2 = CGPointMake(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
//    CGPoint point3 = CGPointMake(CGRectGetWidth(self.frame),0);
    ///测试翻页从上往下绘制图片
    CGPoint point1 = CGPointMake(CGRectGetWidth(self.frame), 0);
    CGPoint point2 = CGPointMake(0, CGRectGetHeight(self.frame));
    CGPoint point3 = CGPointMake(CGRectGetWidth(self.frame),CGRectGetHeight(self.frame));
    [self.fangCheng straightLineEquationWithPoint1:point1 point2:point2];
    [self.fangCheng setInfoWithVertices:point3 circleR:100];
}

- (void)setupVAO {
    
    [self destoryVAO];
    [EAGLContext setCurrentContext:self.context];
    ///创建顶点数组对象
    glGenVertexArraysOES(1, &_currentVAO);
    ///绑定顶点数组对象
    glBindVertexArrayOES(_currentVAO);
    
    ///绑定顶点缓冲数据vbo
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    ///顶点相关数据
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, 0, sizeof(SenceVertex), (void *)offsetof(SenceVertex, x));
    
    glEnableVertexAttribArray(_posColorSlot);
    glVertexAttribPointer(_posColorSlot, 4, GL_FLOAT, 0, sizeof(SenceVertex), (void *)offsetof(SenceVertex, r));

    ///纹理相关数据
    glEnableVertexAttribArray(_textureCoordsSlot);
    glVertexAttribPointer(_textureCoordsSlot, 2, GL_FLOAT, 0, sizeof(SenceVertex), (void *)offsetof(SenceVertex, u));
    ///绑定顶点索引数据
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _bufferIndexEBO);
}

- (void)destoryVAO {
    [EAGLContext setCurrentContext:self.context];
    glDeleteVertexArraysOES(1, &_currentVAO);
    _currentVAO = 0;
}

- (void)setupInitGL {
    
    ///视口大小
    glViewport(0, 0, _viewPortWidth, _viewPortHeight);
    
    //传递纹理对象
    glUseProgram(_program);
    
    ///绑定纹理到当前的纹理
    glActiveTexture(GL_TEXTURE0);// 在绑定纹理之前先激活纹理单元
    glBindTexture(GL_TEXTURE_2D, _currentTexture);
    //glUniform1i(textureSlot, 0) 的意思是，将 textureSlot 赋值为 0，而 0 与 GL_TEXTURE0 对应，这里如果写 1，glActiveTexture 也要传入 GL_TEXTURE1 才能对应起来。
    glUniform1i(_textureSlot, 0);
}

- (void)glClear {
    [EAGLContext setCurrentContext:self.context];
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    self.backgroundColor = [UIColor clearColor];
}

- (void)dealloc {
    [self destoryVAO];
    [self destoryFrameBuffers];
    [self destoryRanderBuffers];
    [self destorySampleBuffers];
    [self destoryTextures:_currentTexture];
    [self destoryTextures:_current2Texture];
    [self destoryVertex];
    [self destoryGPUShaderPrograme];
//    self.context = nil;
    [EAGLContext setCurrentContext:nil];
}


#pragma mark - openGL

- (void)setupLayer {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    NSDictionary *dict = @{kEAGLDrawablePropertyRetainedBacking:@(NO),
                           kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8
                           };
    ///设置图层是否透明
    [eaglLayer setOpaque:NO];
    [eaglLayer setDrawableProperties:dict];
}

- (void)setupContext {
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (self.context == nil) {
        NSLog(@"create context failed!");
        return;
    }
    BOOL result = [EAGLContext setCurrentContext:self.context];
    if (result == NO) {
        NSLog(@"set context failed!");
    }
}

- (void)setupBuffers {
    ///清空上次帧缓冲数据
    [self destoryFrameBuffers];
    ///清空上次绘制数据
    [self destoryRanderBuffers];
    ///清空多采样
    [self destorySampleBuffers];
    ///帧数据缓冲
    [self setupFrameBuffers];
    ///绘制数据缓冲
    [self setupRanderBuffers];
    
    //为绘制缓冲区分配内存
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer *)self.layer];
    
    //获取绘制缓冲区像素高度/宽度
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_viewPortWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_viewPortHeight);
    
//    _viewPortWidth += 10;
//    _viewPortHeight += 10;
    //将绘制缓冲区绑定到帧缓冲区
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    
    //检查状态
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"failed to make complete frame buffer object!");
        return;
    }
    GLenum glError = glGetError();
    if (GL_NO_ERROR != glError) {
        NSLog(@"failed to setup GL %x", glError);
    }
    if (self.antialiasing) {
        glGenFramebuffers(1, &_sampleFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, _sampleFramebuffer);
        
        glGenRenderbuffers(1, &_sampleColorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, _sampleColorRenderbuffer);
        glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER, 4, GL_RGBA8_OES, _viewPortWidth, _viewPortHeight);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _sampleColorRenderbuffer);
        
        status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            NSLog(@"Failed to create multisamping framebuffer: 0x%X", status);
        }
        glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
    }
}

- (void)setupFrameBuffers {
    //创建帧缓冲区
    glGenFramebuffers(1, &_frameBuffer);
    //绑定缓冲区
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
}

- (void)destoryFrameBuffers {
    [EAGLContext setCurrentContext:self.context];
    glDeleteFramebuffers(1, &_frameBuffer);
    _frameBuffer = 0;
}

- (void)setupRanderBuffers {
    //创建绘制缓冲区
    glGenRenderbuffers(1, &_renderBuffer);
    //绑定缓冲区
    glBindRenderbuffer(GL_RENDERBUFFER, _renderBuffer);
}

- (void)destoryRanderBuffers {
    [EAGLContext setCurrentContext:self.context];
    glDeleteRenderbuffers(1, &_renderBuffer);
    _renderBuffer = 0;
}

- (void)setupGPUShaderPrograme {
    ///清空着色器
    [self destoryGPUShaderPrograme];
    // 获取着色器程序
    self.program = [ZYShaderHelper programWithShaderName:@"spring"];
    glUseProgram(self.program);
    
    self.positionSlot = glGetAttribLocation(self.program, "Position");
    self.posColorSlot = glGetAttribLocation(self.program, "PosColor");
    self.textureSlot = glGetUniformLocation(self.program, "Texture");
    self.textureCoordsSlot = glGetAttribLocation(self.program, "TextureCoords");
    
    ///绑定脚本和系统数据之间的关系
//    glBindAttribLocation(self.program, ATTRIB_VERTEX, "Position");
}

- (void)destoryGPUShaderPrograme {
    [EAGLContext setCurrentContext:self.context];
    glDeleteProgram(_program);
    _program = 0;
}

- (GLuint)generateTexture:(GLuint)glTextureId {
    [EAGLContext setCurrentContext:self.context];
    GLuint tex;
    ///创建纹理
    glGenTextures(1, &tex);
    ///绑定纹理
    glBindTexture(GL_TEXTURE_2D, tex);
    ///设置过滤参数
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    ///设置映射规则
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    ///解绑纹理
    glBindTexture(GL_TEXTURE_2D, 0);
    return tex;
}

- (void)destoryTextures:(GLuint)texture {
    glDeleteTextures(1, &texture);
    texture = 0;
}

- (void)destoryVertex {
    [EAGLContext setCurrentContext:self.context];
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_bufferIndexEBO);
    _vertexBuffer = _bufferIndexEBO = _elementCount = 0;
}

- (void)destorySampleBuffers {
    [EAGLContext setCurrentContext:self.context];
    glDeleteFramebuffers(1, &_sampleFramebuffer);
    _sampleFramebuffer = 0;
    glDeleteRenderbuffers(1, &_sampleColorRenderbuffer);
    _sampleColorRenderbuffer = 0;
}

- (void)drawGL {
    ///重设
    [EAGLContext setCurrentContext:self.context];
    [self glClear];
//    glEnable(GL_CULL_FACE);
    glDisable(GL_CULL_FACE);
    [self setupInitGL];
    
    [self setupVAO];
    glBindVertexArrayOES(_currentVAO);
    //执行绘制操作
    glDrawElements(GL_TRIANGLES, _elementCount, GL_UNSIGNED_SHORT, (void *)0);
//    [self.context presentRenderbuffer:GL_RENDERBUFFER];
    ///第二次
    [self drawView:self.test2ImageView onTexture:_currentTexture flipHorizontal:NO];
    self.test2ImageView.alpha = 0;
    // 开启第二个纹理混合
//    glEnable(GL_BLEND);
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
//    glActiveTexture(GL_TEXTURE1);
//    glBindTexture(GL_TEXTURE_2D, _current2Texture);
//    glUniform1i(_textureSlot, 0);

    [self setupVAO];
    
    glBindVertexArrayOES(_currentVAO);
    //执行绘制操作
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, (rowsNum + 1) * (columsNum + 1));
    glDrawElements(GL_TRIANGLES, _elementCount, GL_UNSIGNED_SHORT, (void *)0);
    
    ///测试
//    glCullFace(GL_FRONT);
    if (self.antialiasing) {
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER_APPLE, _frameBuffer);
        glBindFramebuffer(GL_READ_FRAMEBUFFER_APPLE, _sampleFramebuffer);
        glResolveMultisampleFramebufferAPPLE();
        
        GLenum attachments[] = {GL_COLOR_ATTACHMENT0};
        glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);
        
        glBindFramebuffer(GL_FRAMEBUFFER, _sampleFramebuffer);
    }
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}

#pragma mark -图片处理

- (void)drawImage:(UIImage *)image onTexture:(GLuint)texture flipHorizontal:(BOOL)flipHorizontal
{
    CGFloat width = CGImageGetWidth(image.CGImage);
    CGFloat height = CGImageGetHeight(image.CGImage);
    
    [self drawOnTexture:texture width:width height:height drawBlock:^(CGContextRef context) {
        if (flipHorizontal) {
            CGContextTranslateCTM(context, width, height);
            CGContextScaleCTM(context, -1, -1);
        }
        else {
            CGContextTranslateCTM(context, 0, height);
            CGContextScaleCTM(context, 1, -1);
        }
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image.CGImage);
    }];
}

- (void)drawView:(UIView *)view onTexture:(GLuint)texture flipHorizontal:(BOOL)flipHorizontal
{
    [self drawOnTexture:texture width:view.bounds.size.width height:view.bounds.size.height drawBlock:^(CGContextRef context) {
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        if (flipHorizontal) {
            CGContextTranslateCTM(context, view.bounds.size.width*self.screenScale, 0);
            CGContextScaleCTM(context, -self.screenScale, self.screenScale);
        }
        else {
            CGContextScaleCTM(context, self.screenScale, self.screenScale);
        }
        CGFloat horizontalScale =   sqrtl(view.transform.a*view.transform.a + view.transform.b*view.transform.b);
        CGFloat verticalScale =     sqrtl(view.transform.c*view.transform.c + view.transform.d*view.transform.d);
        CGContextScaleCTM(context, horizontalScale, verticalScale);
        CGContextSetInterpolationQuality(context, kCGInterpolationNone);
        [view.layer renderInContext:context];
        NSTimeInterval nextTime = [[NSDate date] timeIntervalSince1970];
        NSLog(@"---->差值:%lf<----", nextTime - currentTime);
    }];
}

- (CGPoint)applyAffinePoint:(CGPoint)point currentContext:(CGContextRef)currentContext {
    CGAffineTransform transform = CGContextGetCTM(currentContext);
    CGPoint originPoint = CGPointApplyAffineTransform(point, transform);
    return originPoint;
}

- (void)drawOnTexture:(GLuint)texture width:(CGFloat)width height:(CGFloat)height drawBlock:(void (^)(CGContextRef context))drawBlock
{
    [EAGLContext setCurrentContext:self.context];

    size_t bitsPerComponent = 8;
    size_t bytesPerRow = _viewPortWidth * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, _viewPortWidth, _viewPortHeight, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGRect r = CGRectMake(0, 0, width, height);
    CGContextClearRect(context, r);
    CGContextSaveGState(context);
    
    drawBlock(context);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGImageRelease(image);
    CGContextRestoreGState(context);
    
    GLubyte *textureData = (GLubyte *)CGBitmapContextGetData(context);
    ///绑定纹理
//    GLuint texId = texture - 1;
//    if (texId == 0) {
        glActiveTexture(GL_TEXTURE0);
//    } else {
//        glActiveTexture(GL_TEXTURE1);
//    }
    glBindTexture(GL_TEXTURE_2D, texture);
    ///绑定纹理数据
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _viewPortWidth, _viewPortHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
    CGContextRelease(context);
}

#pragma mark 业务逻辑处理

- (void)calculateCoordinatesWithRows:(uint)rows columns:(uint)colums {
    [self destoryVertex];
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
            v->u = (GLfloat)x/rows;
            v->v = tv;
            v->x = v->u*2 - 1;
            v->y = vy;
            v->z = 0;
            v->r = 1;
            v->g = 0.5;
            v->b = 0.5;
            v->a = 1;
            [self.fangCheng transGridWithVertex:v];
        }
    }
    
    ///顶点数据缓存
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, verticesSize, (GLvoid *)vertices, GL_DYNAMIC_DRAW);
    free(vertices);
    
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

- (void)drawDefalutImage {
    [EAGLContext setCurrentContext:self.context];
    UIImage *image = [UIImage imageNamed:@"ZYTest.jpg"];
    ///开始
    [self drawImage:image onTexture:_currentTexture flipHorizontal:NO];
    
    ///传入的行和列
    GLsizei rowsNum = 30;
    GLsizei columsNum = 30;
    
    [self calculateCoordinatesWithRows:rowsNum columns:columsNum];

    [self drawGL];
}

- (void)drawDefaultView {
    [EAGLContext setCurrentContext:self.context];
    
    self.testImageView.layer.shadowColor = [[UIColor grayColor] colorWithAlphaComponent:0.8].CGColor;
    
    self.testImageView.layer.shadowOffset = CGSizeMake(10,10);//阴影偏移的位置
    
    self.testImageView.layer.shadowOpacity = 0.5;//阴影透明度
    
    self.testImageView.layer.shadowRadius = 8;//阴影圆角
    
    self.test2ImageView.layer.shadowColor = [[UIColor grayColor] colorWithAlphaComponent:0.8].CGColor;
    
    self.test2ImageView.layer.shadowOffset = CGSizeMake(10,10);//阴影偏移的位置
    
    self.test2ImageView.layer.shadowOpacity = 0.5;//阴影透明度
    
    self.test2ImageView.layer.shadowRadius = 8;//阴影圆角
    
    [self drawView:self.testImageView onTexture:_currentTexture flipHorizontal:NO];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        self.testImageView.alpha = 1;
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self.testImageView screenshot];
//        });
//    });
    ///传入的行和列
    GLsizei rowsNum = 30;
    GLsizei columsNum = 30;
    
    [self calculateCoordinatesWithRows:rowsNum columns:columsNum];
    self.testImageView.alpha = 0;
}

#pragma mark - Utils

-(ZYOCFangCheng *)fangCheng {
    if (!_fangCheng) {
        _fangCheng = [[ZYOCFangCheng alloc] init];
    }
    return _fangCheng;
}

-(UIImageView *)testImageView {
    if (!_testImageView) {
        _testImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _testImageView.image = [UIImage imageNamed:@"ZYTest.jpg"];
    }
    return _testImageView;
}

-(UIImageView *)test2ImageView {
    if (!_test2ImageView) {
        _test2ImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _test2ImageView.image = [UIImage imageNamed:@"ZYTest2.jpg"];
    }
    return _test2ImageView;
}

@end
