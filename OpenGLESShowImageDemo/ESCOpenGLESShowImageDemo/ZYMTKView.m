//
//  MetalImageFilterView.m
//  ESCOpenGLESShowImageDemo
//
//  Created by 海龙 on 2020/11/12.
//  Copyright © 2020 xiang. All rights reserved.
//

#import "ZYMTKView.h"
#import <MetalKit/MetalKit.h>
#import <Metal/Metal.h>
#import <AVFoundation/AVFoundation.h>
#import "ZYOCFangCheng.h"

// 桥接类
#import "ZYImageShaderTypes.h"

/**
 参考文档:
 https://www.jianshu.com/p/ad2ceae81a2b
 https://developer.apple.com/library/archive/documentation/Miscellaneous/Conceptual/MetalProgrammingGuide/Cmd-Submiss/Cmd-Submiss.html#//apple_ref/doc/uid/TP40014221-CH3-SW3
 https://www.invasivecode.com/weblog/metal-image-processing
 https://developer.apple.com/documentation/metal/synchronization/synchronizing_cpu_and_gpu_work
 */
#define MaxBuffersCount 3

@interface ZYMTKView () <MTKViewDelegate> {
    BOOL isChangeFillMode;
    CGSize imageSize;
    dispatch_semaphore_t frameBoundarySemaphore;
}
// 渲染范围
@property (nonatomic, assign) vector_int2 viewportSize;

// MTKView Metal渲染的view
//@property (nonatomic, strong) MTKView * mtkView;

// 用来渲染的设备(GPU)
//@property (nonatomic, strong) id <MTLDevice> device;

// 渲染管道，管理顶点函数和片元函数
@property (nonatomic, strong) id <MTLRenderPipelineState> renderPipelineState;

// 渲染指令队列
@property (nonatomic, strong) id <MTLCommandQueue> commondQueue;

// 顶点缓存对象
@property (nonatomic, strong) id <MTLBuffer> vertexBuffer;

// 索引缓存对象
@property (nonatomic, strong) id <MTLBuffer> indicesBuffer;

// 纹理对象
@property (nonatomic, strong) id <MTLTexture> texture;
@property (nonatomic, strong) id <MTLTexture> texture2;

// 顶点数量
@property (nonatomic, assign) NSUInteger vertexCount;

@property (nonatomic, assign) NSInteger lastUpdateColums;
@property (nonatomic, assign) NSInteger lastUpdateRows;

/*
 测试用
 */
@property (nonatomic, strong) ZYOCFangCheng *fangCheng;

@property (nonatomic, strong) UIImageView *testImageView;
@property (nonatomic, strong) UIImageView *test2ImageView;

@property (nonatomic, assign) NSInteger arcI;

@end

@implementation ZYMTKView

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.arcI = 100;
        self.backgroundColor = [UIColor clearColor];
        frameBoundarySemaphore = dispatch_semaphore_create(MaxBuffersCount);
        [self addSubview:self.testImageView];
        
        [self addSubview:self.test2ImageView];
        // 1.创建 MTKView
        [self createMTKView];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self testVer];
            // 3.设置纹理
            self.texture = [self setupTexture:self.testImageView];
            self.texture2 = [self setupTexture:self.test2ImageView];
            // 4.创建渲染管道
            [self createPipeLineState];
            __weak typeof(self) weakself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakself performSelector:@selector(testARC) withObject:nil afterDelay:1.0/60];
            });
            self.testImageView.hidden = YES;
            self.test2ImageView.hidden = YES;
        });
    }
    return self;
}

- (void)testVer {
    // 2.设置顶点 1.0和1.0表示宽高保持默认的拉伸状态，不去动态调整
    [self setupVertexs];
}

- (void)change {
    CGPoint point1 = CGPointMake(CGRectGetWidth(self.frame), 0);
    CGPoint point2 = CGPointMake(0, CGRectGetHeight(self.frame));
    CGPoint point3 = CGPointMake(CGRectGetWidth(self.frame),CGRectGetHeight(self.frame));
    [self.fangCheng straightLineEquationWithPoint1:point1 point2:point2];
    [self.fangCheng setInfoWithVertices:point3 circleR:self.arcI];
}

- (void)testARC {
    if (self.arcI <= 0) {
        self.arcI = 100;
    }
    dispatch_semaphore_wait(frameBoundarySemaphore, DISPATCH_TIME_FOREVER);
    [self change];
    [self testVer];
    self.arcI -= 1;
    [self setNeedsDisplay];
    [self performSelector:@selector(testARC) withObject:nil afterDelay:1.0/60];
}

- (void)layoutSubviews {
    [super layoutSubviews];
//    self.mtkView.frame = self.bounds;
//    self.viewportSize = (vector_int2){self.mtkView.drawableSize.width, self.mtkView.drawableSize.height};
    self.testImageView.frame = self.bounds;
    self.test2ImageView.frame = self.bounds;
}

- (void)dealloc {
    NSLog(@"");
}

// 创建 MTKView
- (void)createMTKView {
//    MTKView * mtkView = [[MTKView alloc] init];
    self.delegate = self;
    self.backgroundColor = [UIColor clearColor];
    // 创建Device
    self.device = MTLCreateSystemDefaultDevice();
    self.enableSetNeedsDisplay = YES;
    // 设置device
//    self.device = mtkView.device;
//    self.mtkView = mtkView;
//    [self addSubview:mtkView];
}

// 2.设置顶点
- (void)setupVertexs {
    // 1.顶点纹理数组
    NSInteger rows = 24;
    NSInteger colums = 57;
    BOOL needUpdateIndices = NO;
    UInt32 * vertexIndices;
    ///索引个数
    NSInteger indexCount = rows*colums*2*3;
    //数据大小 = 单个四边形大小 * 行 * 列
    NSUInteger dataSize = sizeof(UInt32) * indexCount;
    if (self.lastUpdateRows != rows || self.lastUpdateColums != colums) {
        needUpdateIndices = YES;
        self.lastUpdateRows = rows;
        self.lastUpdateColums = colums;
        
        //开辟空间
        vertexIndices = (UInt32 *)malloc(dataSize);
    }
    ///顶点数据
    NSInteger verCount = (rows + 1) * (colums + 1);
    ZYVertex vertexArray[verCount];
    
    //当前顶点数据
    for (int y = 0; y < colums+1; ++y) {
        GLfloat tv = (GLfloat)y/colums;
        GLfloat vy = tv * 2 - 1;
        for (int x = 0; x < rows+1; ++x) {
            ///从上往下算三角形的顶点数据
            NSInteger arrayIndex = (colums - y) * (rows + 1) + x;
            ZYVertex *v = &vertexArray[arrayIndex];
            ///从下往上算三角形的顶点数据
//            SenceVertex *v = &vertices[y*(rows+1) + x];
            vector_float2 texure;
            texure.x = (GLfloat)x/rows;
            texure.y = tv;
            v->textureCoordinate = texure;
            
            vector_float4 pos;
            pos.x = (GLfloat)x/rows*2-1;
            pos.y = vy;
            pos.z = 0;
            pos.w = 1;
            vector_float4 newPos = [self.fangCheng transGridWithVertexPoint:pos];
            v->position = newPos;
            
            vector_float4 color;
            color.x = 1.0;
            color.y = 0.0;
            color.z = 0.0;
            color.w = 1.0;
            v->positionColor = color;
            
            if (!needUpdateIndices || y >= colums || x >= rows) {
                continue;
            }
            long i = y*(rows+1) + x;
            long idx = y*rows + x;
            vertexIndices[idx*6+0] = i;
            vertexIndices[idx*6+1] = i + 1;
            vertexIndices[idx*6+2] = i + rows + 1;
            vertexIndices[idx*6+3] = i + 1;
            vertexIndices[idx*6+4] = i + rows + 2;
            vertexIndices[idx*6+5] = i + rows + 1;
        }
    }

    // 2.生成顶点缓存
    // MTLResourceStorageModeShared 属性可共享的，表示可以被顶点或者片元函数或者其他函数使用
//    self.vertexBuffer = [self.device newBufferWithLength:dataSize options:MTLResourceStorageModeShared];
    self.vertexBuffer = [self.device newBufferWithLength:sizeof(vertexArray) options:MTLResourceStorageModeShared];
    memcpy(self.vertexBuffer.contents, vertexArray, sizeof(vertexArray));
    if (needUpdateIndices) {
        self.indicesBuffer = [self.device newBufferWithLength:dataSize options:MTLResourceStorageModeShared];
        memcpy(self.indicesBuffer.contents, vertexIndices, dataSize);
        free(vertexIndices);
    }
    // 3.获取顶点数量
    self.vertexCount = indexCount;
}


// 3.设置纹理
- (id <MTLTexture>)setupTexture:(UIImageView *)imageView {
    CGContextRef context = [self drawView:imageView flipHorizontal:NO];
//    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    // 1.创建纹理描述符
    MTLTextureDescriptor * textureDescriptor = [[MTLTextureDescriptor alloc] init];
    // 设置纹理描述符的宽，高，像素存储格式
    textureDescriptor.width = self.viewportSize.x;
    textureDescriptor.height = self.viewportSize.y;
    imageSize = CGSizeMake(self.viewportSize.x, self.viewportSize.y);
    //MTLPixelFormatRGBA8Unorm 表示每个像素有蓝色,绿色,红色和alpha通道.其中每个通道都是8位无符号归一化的值.(即0映射成0,255映射成1)
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    
    // 2.创建纹理对象
    id <MTLTexture> texture = [self.device newTextureWithDescriptor:textureDescriptor];
    // id <MTLDevice> -> id <MTLTexture>
    
    // 3.将图片数据读取到纹理对象内
    /*
     typedef struct
     {
     MTLOrigin origin; //开始位置x,y,z
     MTLSize   size; //尺寸width,height,depth
     } MTLRegion;
     */
    //MLRegion结构用于标识纹理的特定区域。 demo使用图像数据填充整个纹理；因此，覆盖整个纹理的像素区域等于纹理的尺寸。
    //4. 创建MTLRegion 结构体  [纹理上传的范围]
    MTLRegion region = {{0, 0, 0}, {self.viewportSize.x, self.viewportSize.y, 1}};
    
    // 图片的二进制数据 UIImage的数据需要转成二进制才能上传，且不用jpg、png的NSData
//    Byte * imageBytes = [self loadImage:image];
    Byte *imageBytes = CGBitmapContextGetData(context);
    // 将图片数据读取到纹理对象内
    // region 纹理区域
    // 0 mip贴图层次
    // imageBytes 图片二进制数据
    // image.size.width * 4 每一行字节数
    if (imageBytes) {
        [texture replaceRegion:region mipmapLevel:0 withBytes:imageBytes bytesPerRow:self.viewportSize.x * 4];
    }
    CGContextRelease(context);
    imageBytes = nil;
    return texture;
}

// 图片加载为二进制数据
- (Byte *)loadImage:(UIImage *)image {
    CGImageRef spriteImage = image.CGImage;
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    Byte * spriteData = (Byte *)calloc(width * height * 4, sizeof(Byte));
    
    CGContextRef context = CGBitmapContextCreate(spriteData, width, height, 8, width *4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    // 纹理翻转
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), spriteImage);
    CGContextRelease(context);
    return spriteData;
}

// 4.创建渲染管道
// 根据.metal里的函数名，使用MTLLibrary创建顶点函数和片元函数
// 从这里可以看出来，MTLLibrary里面包含所有.metal的文件，所以，不同的.metal里面的函数名不能相同
// id <MTLDevice> 创建library、MTLRenderPipelineState、MTLCommandQueue
- (void)createPipeLineState {
    
    // 1.从项目中加载.metal文件，创建一个library
    id <MTLLibrary> library = [self.device newDefaultLibrary];
    // id <MTLDevice> -> id <MTLLibrary>
    
    // 2.从库中MTLLibrary，加载顶点函数
    id <MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexImageShader"];
    
    // 3.从库中MTLLibrary，加载顶点函数
    id <MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentImageShader"];
    
    // 4.创建管道渲染管道描述符
    MTLRenderPipelineDescriptor * renderPipeDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    // 5.设置管道顶点函数和片元函数
    renderPipeDescriptor.vertexFunction = vertexFunction;
    renderPipeDescriptor.fragmentFunction = fragmentFunction;
    
    // 6.设置管道描述的关联颜色存储方式
    renderPipeDescriptor.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    renderPipeDescriptor.colorAttachments[0].blendingEnabled = YES;
    renderPipeDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    NSError * error = nil;
    // 7.根据渲染管道描述符 创建渲染管道
    id <MTLRenderPipelineState> renderPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipeDescriptor error:&error];
    self.renderPipelineState = renderPipelineState;
    // id <MTLDevice> -> id <MTLRenderPipelineState>
    
    // 8. 创建渲染指令队列
    id <MTLCommandQueue> commondQueue = [self.device newCommandQueueWithMaxCommandBufferCount:3];
    self.commondQueue = commondQueue;
    // id <MTLDevice> -> id <MTLCommandQueue>
}

// MTKViewDelegate
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
    self.viewportSize = (vector_int2){size.width, size.height};
}

// MTKViewDelegate
- (void)drawInMTKView:(nonnull MTKView *)view {
    [self drawContent];
}

- (void)drawContent {
    // 1.为当前渲染的每个渲染传递创建一个新的命令缓冲区
    id <MTLCommandBuffer> commandBuffer = [self.commondQueue commandBuffer];
    
    //指定缓存区名称
    commandBuffer.label = @"EachCommand";
    
    // 2.获取渲染命令编码器 MTLRenderCommandEncoder的描述符
    // currentRenderPassDescriptor描述符包含currentDrawable's的纹理、视图的深度、模板和sample缓冲区和清晰的值。
    // MTLRenderPassDescriptor描述一系列attachments的值，类似GL的FrameBuffer；同时也用来创建MTLRenderCommandEncoder
    MTLRenderPassDescriptor * renderPassDescriptor = self.currentRenderPassDescriptor;
    if (renderPassDescriptor) {
        // 设置默认颜色 背景色
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0f);
        
        // 3.根据描述创建x 渲染命令编码器
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        ///剔除背面
        [renderEncoder setCullMode:MTLCullModeBack];
        
//        typedef struct {
//            double originX, originY, width, height, znear, zfar;
//        } MTLViewport;
        // 4.设置绘制区域
        [renderEncoder setViewport:(MTLViewport){0, 0, self.viewportSize.x, self.viewportSize.y, -1.0, 1.0}];
        
        // 5.设置渲染管道
        [renderEncoder setRenderPipelineState:self.renderPipelineState];
        
        // 6.传递顶点缓存
        [renderEncoder setVertexBuffer:self.vertexBuffer offset:0 atIndex:ZYImageVertexInputIndexVertexs];
        // 7.传递纹理缓存
        [renderEncoder setFragmentTexture:self.texture atIndex:ZYImageTextureIndexBaseTexture];
        
        // 8.绘制
//        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:self.vertexCount];
        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:self.vertexCount indexType:MTLIndexTypeUInt32 indexBuffer:self.indicesBuffer indexBufferOffset:0];
        
        [renderEncoder setCullMode:MTLCullModeFront];
        
        // 7.传递纹理缓存
        [renderEncoder setFragmentTexture:self.texture2 atIndex:ZYImageTextureIndexBaseTexture];
        
        // 8.绘制
        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:self.vertexCount indexType:MTLIndexTypeUInt32 indexBuffer:self.indicesBuffer indexBufferOffset:0];
        
        // 9.命令结束
        [renderEncoder endEncoding];
        
        // 10.显示
        [commandBuffer presentDrawable:self.currentDrawable];
        
        __weak dispatch_semaphore_t semaphore = frameBoundarySemaphore;
        [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull buffer) {
            ///完成
            dispatch_semaphore_signal(semaphore);
        }];
    }
    // 11. 提交
    [commandBuffer commit];
}

- (CGContextRef)drawView:(UIView *)view flipHorizontal:(BOOL)flipHorizontal
{
    CGFloat scale = [UIScreen mainScreen].scale;
    CGContextRef context = [self drawOnTextureWidth:self.viewportSize.x height:self.viewportSize.y];
    if (flipHorizontal) {
        CGContextTranslateCTM(context, view.bounds.size.width*scale, 0);
        CGContextScaleCTM(context, -scale, scale);
    }
    else {
        CGContextScaleCTM(context, scale, scale);
    }
    CGFloat horizontalScale =   sqrtl(view.transform.a*view.transform.a + view.transform.b*view.transform.b);
    CGFloat verticalScale =     sqrtl(view.transform.c*view.transform.c + view.transform.d*view.transform.d);
    CGContextScaleCTM(context, horizontalScale, verticalScale);
    
    [view.layer renderInContext:context];
    return context;
}

- (CGContextRef)drawOnTextureWidth:(CGFloat)width height:(CGFloat)height
{
    
    size_t bitsPerComponent = 8;
    size_t bytesPerRow = width * 4;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    CGColorSpaceRelease(colorSpace);
    
    CGRect r = CGRectMake(0, 0, width, height);
    CGContextClearRect(context, r);
    
    return context;
}


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
