//
//  ZYOCFangCheng.m
//  ESCOpenGLESShowImageDemo
//
//  Created by 海龙 on 2020/10/30.
//  Copyright © 2020 xiang. All rights reserved.
//

#import "ZYOCFangCheng.h"

@interface ZYOCFangCheng()

@property (nonatomic, assign) float A;
@property (nonatomic, assign) float B;
@property (nonatomic, assign) float C;
@property (nonatomic, assign) float K;
@property (nonatomic, assign) float KB;
@property (nonatomic, assign) float mCircleR;
@property (nonatomic, assign) CGPoint mDingPoint;

@end

@implementation ZYOCFangCheng

-(instancetype)init {
    if (self = [super init]) {
        self.mCircleR = 100;
    }
    return self;
}

//// 根据两点求直线的方程
//FangCheng::FangCheng(ZLPointF pointF1, ZLPointF pointF2) {
//    K = getPointsK(pointF1, pointF2);
//    KB = pointF1.y - K * pointF1.x;
//
//    A = -K;
//    B = 1;
//    C = -KB;
//}


// 根据两点求直线的方程
- (void)straightLineEquationWithPoint1:(CGPoint)point1 point2:(CGPoint)point2 {
    self.K = [self straightSlopeEquationWithPoint1:point1 point2:point2];
    self.KB = point1.y - self.K * point1.x;
    self.A = -self.K;
    self.B = 1;
    self.C = -self.KB;
}

//// 根据两点求直线的方程
//FangCheng::FangCheng(ZLPointF pointF1, float inK) {
//    K = inK;
//    KB = pointF1.y - K * pointF1.x;
//
//    A = -K;
//    B = 1;
//    C = -KB;
//}

// 根据两点求直线的方程
- (void)straightLineEquationWithPoint1:(CGPoint)point1 K:(float)K {
    self.K = K;
    self.KB = point1.y - self.K * point1.x;
    self.A = -self.K;
    self.B = 1;
    self.C = -self.KB;
}

//void FangCheng::setInfo(ZLPointF dingPoint, float CircleR) {
//    mDingPoint = dingPoint;
//    mCircleR = CircleR;
//}

- (void)setInfoWithVertices:(CGPoint)vertices circleR:(float)circleR {
    self.mCircleR = circleR;
    self.mDingPoint = vertices;
}

// 根据两点求直线的斜率
//float FangCheng::getPointsK(ZLPointF pointF1, ZLPointF pointF2) {
//    return (pointF1.y - pointF2.y) / (pointF1.x - pointF2.x);
//}

// 根据两点求直线的斜率
- (float)straightSlopeEquationWithPoint1:(CGPoint)point1 point2:(CGPoint)point2 {
    return (point1.y - point2.y)/(point1.x - point2.x);
}

// 判断两点是否在直线的同侧
//bool FangCheng::isTwoPointSameSide(ZLPointF pointF1, ZLPointF pointF2) {
//    double value1 = A * pointF1.x + B * pointF1.y + C;
//    double value2 = A * pointF2.x + B * pointF2.y + C;
//    return value1 * value2 > 0;
//}

// 判断两点是否在直线的同侧
- (BOOL)theTwoPointIsSameSideWithPoint1:(CGPoint)point1 point2:(CGPoint)point2 {
    double value1 = self.A * point1.x + self.B * point1.y + self.C;
    double value2 = self.A * point2.x + self.B * point2.y + self.C;
    return  value1 * value2 > 0;
}

//// 点到直线的距离
//float FangCheng::getDisPointToLine(ZLPointF pointF1) {
//    float value1 = std::abs(A * pointF1.x + B * pointF1.y + C);
//    double value2 = std::sqrt(A * A + B * B);
//    return value1 / (float) value2;
//}

// 点到直线的距离
- (float)getTheDistanceFromThePointToTheLineWithPoint:(CGPoint)point {
    float value1 = fabs(self.A * point.x + self.B * point.y + self.C);
//    double value2 = sqrt(self.A * self.A + self.B * self.B);
    float value2 = sqrtf(self.A * self.A + self.B * self.B);
    return value1/value2;
}

// 是否是翻页的时候，翻页部分
//void FangCheng::getPageTurnPoint(ZLPointF inPoint, ZLPointF &outPointF, PageTurnPointType &outPointType) {
//    if (!isTwoPointSameSide(mDingPoint, inPoint)) {
//        outPointF = inPoint;
//        outPointType = PageTurnPointBackground;
//        return;
//    }
//
//    //求相垂直的直线的斜率
//    double K2 = -1 / K;
//    double Len = getDisPointToLine(inPoint);
//
//    // 对于区域A来说，如果大于圆的半径，就返回原位置点
//    if (Len > (PI * mCircleR)) {
//        double t_len = Len + (Len - PI * mCircleR);                                             // x, y, k2为已知项，求新的点的x，y
//        double Point_x = inPoint.x - std::sqrt(t_len*t_len / (1 + K2*K2));
//        double Point_y = inPoint.y + (Point_x - inPoint.x) * K2;
//
//        outPointF.x = Point_x;
//        outPointF.y = Point_y;
//        outPointType = PageTurnPointFront;
//        return;
//    }
//
//    double thO = Len / mCircleR;                                                                // 得到弧度的度数
//    double Point_len = std::sin(thO)*mCircleR;
//
//    double t_len = Len - Point_len;                                                         // x, y, k2为已知项，求新的点的x，y
//    double Point_x = inPoint.x - std::sqrt(t_len*t_len / (1 + K2*K2));
//    double Point_y = inPoint.y + (Point_x - inPoint.x) * K2;
//
//    outPointF.x = Point_x;
//    outPointF.y = Point_y;
//
//    if (Len > (PI * mCircleR) / 2) {
//        outPointType = PageTurnPointUpCircle;
//        return;
//    }
//    outPointType = PageTurnPointDownCircle;
//}


- (void)getPageTurnPointWithInputPoint:(CGPoint)inputPoint  outPutCallBack:(PageTurnOutputBlock)outputCallBack {
    if (![self theTwoPointIsSameSideWithPoint1:self.mDingPoint point2:inputPoint]) {
        if (outputCallBack) {
            outputCallBack(inputPoint, PageTurnPointBackground);
        }
        return;
    }
    //求相垂直的直线的斜率
    double K2 = -1/self.K;
    double len = [self getTheDistanceFromThePointToTheLineWithPoint:inputPoint];
    // 对于区域A来说，如果大于圆的半径，就返回原位置点
    if (len > M_PI * self.mCircleR) {
        double t_len = len + (len - M_PI * self.mCircleR);
        // x, y, k2为已知项，求新的点的x，y
        double pointX = inputPoint.x - sqrt(t_len * t_len
                                             / (1 + K2 * K2));
        double pointY = inputPoint.y + (pointX - inputPoint.x) * K2;
        
        if (outputCallBack) {
            outputCallBack(CGPointMake(pointX, pointY), PageTurnPointFront);
        }
        return;
    }
    
    double thO = len / self.mCircleR;
    // 得到弧度的度数
    double pointLen = sin(thO) * self.mCircleR;
    double t_len = len - pointLen;
    // x, y, k2为已知项，求新的点的x，y
    double pointX = inputPoint.x - sqrt(t_len * t_len / (1 + K2 * K2));
    double PointY = inputPoint.y + (pointX - inputPoint.x) * K2;
    if (len > (M_PI * self.mCircleR) / 2) {
        if (outputCallBack) {
            outputCallBack(CGPointMake(pointX, PointY), PageTurnPointUpCircle);
        }
        return;
    }
    if (outputCallBack) {
        outputCallBack(CGPointMake(pointX, PointY), PageTurnPointDownCircle);
    }
}

- (vector_float4)transGridWithVertexPoint:(vector_float4)point {
    vector_float4 newPoint = point;
    CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat viewHeight = [UIScreen mainScreen].bounds.size.height;
    CGPoint inputPoint = CGPointMake((point.x + 1) * viewWidth / 2, viewHeight - ((point.y + 1) * viewHeight / 2));
    __block CGPoint outputPoint = CGPointZero;
    __block PageTurnPointType outputType = PageTurnPointBackground;
    [self getPageTurnPointWithInputPoint:inputPoint outPutCallBack:^(CGPoint outPoint, PageTurnPointType outType) {
        outputPoint = outPoint;
        outputType = outType;
    }];
//    vertex->x = (outputPoint.x / viewWidth) * 2 - 1;
//    vertex->y = -(outputPoint.y / viewHeight) * 2 + 1;
    newPoint.x = (outputPoint.x / viewWidth) * 2 - 1;
    newPoint.y = -(outputPoint.y / viewHeight) * 2 + 1;
    return newPoint;
}

- (void)transGridWithVertex:(SenceVertex *)vertex {
    CGFloat viewWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat viewHeight = [UIScreen mainScreen].bounds.size.height;
    CGPoint inputPoint = CGPointMake((vertex->x + 1) * viewWidth / 2, viewHeight - ((vertex->y + 1) * viewHeight / 2));
    __block CGPoint outputPoint = CGPointZero;
    __block PageTurnPointType outputType = PageTurnPointBackground;
    [self getPageTurnPointWithInputPoint:inputPoint outPutCallBack:^(CGPoint outPoint, PageTurnPointType outType) {
        outputPoint = outPoint;
        outputType = outType;
    }];
    vertex->x = (outputPoint.x / viewWidth) * 2 - 1;
    vertex->y = -(outputPoint.y / viewHeight) * 2 + 1;
}

@end
