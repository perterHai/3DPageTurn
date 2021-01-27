//
//  ViewController.m
//  ESCOpenGLESShowImageDemo
//
//  Created by xiang on 2018/7/25.
//  Copyright © 2018年 xiang. All rights reserved.
//

#import "ViewController.h"
#import "ESCOpenGLESView.h"
#import "ZYGLView.h"
#import "TestViewController.h"

@interface ViewController ()

@property(nonatomic,weak)ESCOpenGLESView* openGLESView;

@property(nonatomic,weak)UIImageView* imageView;

@property(nonatomic,assign)NSInteger currentImageIndex;

@property(nonatomic,strong)dispatch_queue_t testqueue;

@property(nonatomic,weak)ZYGLView* glTestView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(30, 200, self.view.frame.size.width - 60, 60);
    [button setTitle:@"present" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor blueColor].CGColor;
    [button addTarget:self action:@selector(presentTest) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
//    self.testqueue = dispatch_queue_create("test", 0);
//
//    CGFloat screenwidth = [UIScreen mainScreen].bounds.size.width;
//    CGFloat screenheight = [UIScreen mainScreen].bounds.size.height;
//
//    CGFloat width = screenwidth;
//    CGFloat height = screenheight;
    
//    ESCOpenGLESView *openGLESView = [[ESCOpenGLESView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
//    [self.view addSubview:openGLESView];
//    self.openGLESView = openGLESView;
    
//    ZYGLView *glView = [[ZYGLView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
//    [self.view addSubview:glView];
//    self.glTestView = glView;
//
//    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, screenheight / 2, screenwidth, screenheight / 2)];
//    [self.view addSubview:imageView];
//    self.imageView = imageView;
    
//    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(loadImages) userInfo:nil repeats:YES];
}

- (void)presentTest {
    TestViewController *testVC = [[TestViewController alloc] init];
    testVC.modalPresentationStyle = UIModalPresentationCustom;
    [self presentViewController:testVC animated:YES completion:^{
    }];
}

- (void)loadImages {
    self.currentImageIndex++;
    if (self.currentImageIndex > 3) {
        self.currentImageIndex = 1;
    }
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self loadImageWithName:[NSString stringWithFormat:@"%ld",(long)self.currentImageIndex]];
    });
}

- (void)loadImageWithName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:@"ZYTest.jpg"];
    [self.openGLESView loadImage:image];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = image;
    });

}


@end
