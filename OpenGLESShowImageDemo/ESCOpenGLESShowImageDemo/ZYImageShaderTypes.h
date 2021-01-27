//
//  ZYImageShaderTypes.h
//  ESCOpenGLESShowImageDemo
//
//  Created by 海龙 on 2020/11/12.
//  Copyright © 2020 xiang. All rights reserved.
//

#ifndef ZYImageShaderTypes_h
#define ZYImageShaderTypes_h

// 这个simd.h文件里有一些桥接的数据类型
#include <simd/simd.h>

// 存储数据的自定义结构，用于桥接OC和Metal代码
// ZYVertex结构体类型

typedef struct {
    // 顶点坐标 4维向量
    vector_float4 position;
    // 顶点颜色
    vector_float4 positionColor;
    // 纹理坐标
    vector_float2 textureCoordinate;
    
} ZYVertex;


// 自定义枚举，用于桥接OC和Metal代码
// 顶点的桥接枚举值 ZYImageVertexInputIndexVertexs
typedef enum {
    
    ZYImageVertexInputIndexVertexs = 0,
    
} ZYImageVertexInputIndex;


// 纹理的桥接枚举值 ZYImageTextureIndexBaseTexture
typedef enum {
    
    ZYImageTextureIndexBaseTexture = 0,
    
} ZYImageTextureIndex;

// 顶点颜色的桥接枚举值 ZYImageVertexColorIndexColors
typedef enum {
    
    ZYImageVertexColorIndexColors = 0,
    
} ZYImageVertexColorIndex;


#endif /* ZYImageShaderTypes_h */
