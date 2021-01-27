//
//  TestViewController.m
//  ESCOpenGLESShowImageDemo
//
//  Created by 海龙 on 2020/11/3.
//  Copyright © 2020 xiang. All rights reserved.
//

#import "TestViewController.h"
#import "ZYGLView.h"
#import "ZYMTKView.h"
#import "ZYGLKView.h"


@interface TestViewController ()

@property(nonatomic,weak)ZYGLView* glTestView;
@property(nonatomic,strong)ZYMTKView* mtkTestView;

@property (nonatomic, assign) BOOL supportMetal;

@end

@implementation TestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    if (!self.supportMetal) {
        ZYGLView *glView = [[ZYGLView alloc] initWithFrame:self.view.bounds context:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
        [self.view addSubview:glView];
        self.glTestView = glView;
    } else {
        ZYMTKView *metalView = [[ZYMTKView alloc] init];
        [self.view addSubview:metalView];
        self.mtkTestView = metalView;
    }
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(50, 50, 45, 45);
    [button setTitle:@"关闭" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor blueColor].CGColor;
    [button addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.frame = CGRectMake(30, 200, self.view.frame.size.width - 60, 60);
    [button2 setTitle:@"present" forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button2.layer.borderWidth = 1;
    button2.layer.borderColor = [UIColor blueColor].CGColor;
    [button2 addTarget:self action:@selector(presentTest) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button2];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.mtkTestView.frame = self.view.bounds;
    self.glTestView.frame = self.view.bounds;
}

- (void)dismissSelf {
    if (self.mtkTestView) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self.mtkTestView];
    }
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)presentTest {
    TestViewController *testVC = [[TestViewController alloc] init];
    testVC.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:testVC animated:YES completion:^{
    }];
}

- (BOOL)supportMetal {
    return NO;
    id <MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (device != nil) {
        BOOL featureSet = [device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily1_v2];
        return featureSet;
    }
    return NO;
}

@end
