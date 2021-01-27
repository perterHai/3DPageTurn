//
//  ZYGLView.h
//  ESCOpenGLESShowImageDemo
//
//  Created by 海龙 on 2020/10/28.
//  Copyright © 2020 xiang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    GLfloat x, y, z; //顶点坐标数据
    GLfloat r, g, b, a; //顶点坐标数据
    GLfloat u, v; //纹理坐标数据
} SenceVertex;

@interface ZYGLView : GLKView

@property (nonatomic, assign) BOOL antialiasing; //是否开启抗锯齿

@end

NS_ASSUME_NONNULL_END
