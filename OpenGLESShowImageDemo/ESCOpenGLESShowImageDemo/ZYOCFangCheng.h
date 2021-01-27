//
//  ZYOCFangCheng.h
//  ESCOpenGLESShowImageDemo
//
//  Created by 海龙 on 2020/10/30.
//  Copyright © 2020 xiang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ZYGLView.h"

typedef NS_ENUM(NSInteger, PageTurnPointType) {
    PageTurnPointBackground,            // 翻页效果中，非折叠的部分
    PageTurnPointFront,                    // 翻页效果中，翻转过来的部分
    PageTurnPointDownCircle,            // 翻页效果中，下半个圆的部分
    PageTurnPointUpCircle,                // 翻页效果中，上半个圆的部分
};

//enum PageTurnPointType {
//    PageTurnPointBackground,            // 翻页效果中，非折叠的部分
//    PageTurnPointFront,                    // 翻页效果中，翻转过来的部分
//    PageTurnPointDownCircle,            // 翻页效果中，下半个圆的部分
//    PageTurnPointUpCircle,                // 翻页效果中，上半个圆的部分
//};

typedef void (^PageTurnOutputBlock)(CGPoint outPoint, PageTurnPointType outType);

NS_ASSUME_NONNULL_BEGIN

@interface ZYOCFangCheng : NSObject

// 根据两点求直线的方程
- (void)straightLineEquationWithPoint1:(CGPoint)point1 point2:(CGPoint)point2;

// 根据两点求直线的方程
- (void)straightLineEquationWithPoint1:(CGPoint)point1 K:(float)K;

- (void)setInfoWithVertices:(CGPoint)vertices circleR:(float)circleR;

// 根据两点求直线的斜率
- (float)straightSlopeEquationWithPoint1:(CGPoint)point1 point2:(CGPoint)point2;

// 判断两点是否在直线的同侧
- (BOOL)theTwoPointIsSameSideWithPoint1:(CGPoint)point1 point2:(CGPoint)point2;

// 点到直线的距离
- (float)getTheDistanceFromThePointToTheLineWithPoint:(CGPoint)point;

// 是否是翻页的时候，翻页部分
- (void)getPageTurnPointWithInputPoint:(CGPoint )inputPoint  outPutCallBack:(PageTurnOutputBlock)outputCallBack;

- (void)transGridWithVertex:(SenceVertex *)vertex;

- (vector_float4)transGridWithVertexPoint:(vector_float4)point;

@end

NS_ASSUME_NONNULL_END
