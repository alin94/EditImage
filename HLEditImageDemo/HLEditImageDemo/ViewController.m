//
//  ViewController.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/4.
//  Copyright © 2020 alin. All rights reserved.
//

#import "ViewController.h"
#import "SLEditImageController.h"
#import "SLUtilsMacro.h"
@interface ViewController () <UIImagePickerControllerDelegate,UINavigationBarDelegate>
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController
- (UIImageView *)imageView {
    if(!_imageView){
        _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:_imageView];
        [self.view sendSubviewToBack:_imageView];
    }
    return _imageView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    btn.frame = CGRectMake(0, 0, 100, 40);
    btn.center = self.view.center;
    [btn setTitle:NSLocalizedString(@"选择照片", @"") forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(selectImage) forControlEvents:UIControlEventTouchUpInside];
    
//    [self createArrow];
    
}
- (void)selectImage {
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage * retusltImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self showEditImageVCWithImage:retusltImage];
    }];

}
- (void)showEditImageVCWithImage:(UIImage *)image {
    SLEditImageController *vc = [[SLEditImageController alloc] init];
    vc.image = image;
    WS(weakSelf);
    vc.editFinishedBlock = ^(UIImage * _Nonnull image) {
        weakSelf.imageView.image = image;
    };
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

- (CGFloat)distanceBetweenStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGFloat xDist = (endPoint.x - startPoint.x);
    CGFloat yDist = (endPoint.y - startPoint.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}
- (CGFloat)angleBetweenStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint{
    CGFloat height = endPoint.y - startPoint.y;
    CGFloat width = startPoint.x - endPoint.x;
    CGFloat rads = atan(height/width);
    return rads;

}
- (UIBezierPath *)createArrowWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    
    CGFloat lineWidth = 8;
    CGPoint controllPoint = CGPointZero;
    CGPoint pointUp = CGPointZero;
    CGPoint pointDown = CGPointZero;
    CGFloat distance = [self distanceBetweenStartPoint:startPoint endPoint:endPoint];
    CGFloat distanceX = lineWidth * (ABS(endPoint.x - startPoint.x) / distance);
    CGFloat distanceY = lineWidth*2 * (ABS(endPoint.y - startPoint.y) / distance);
    CGFloat distX = lineWidth * (ABS(endPoint.y - startPoint.y) / distance);
    CGFloat distY = lineWidth * (ABS(endPoint.x - startPoint.x) / distance);
    if (endPoint.x >= startPoint.x)
    {
        if (endPoint.y >= startPoint.y)
        {
            controllPoint = CGPointMake(endPoint.x - distanceX, endPoint.y - distanceY);
            pointUp = CGPointMake(controllPoint.x + distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x - distX, controllPoint.y + distY);
        }
        else
        {
            controllPoint = CGPointMake(endPoint.x - distanceX, endPoint.y + distanceY);
            pointUp = CGPointMake(controllPoint.x - distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x + distX, controllPoint.y + distY);
        }
    }
    else
    {
        if (endPoint.y >= startPoint.y)
        {
            controllPoint = CGPointMake(endPoint.x + distanceX, endPoint.y - distanceY);
            pointUp = CGPointMake(controllPoint.x - distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x + distX, controllPoint.y + distY);
        }
        else
        {
            controllPoint = CGPointMake(endPoint.x + distanceX, endPoint.y + distanceY);
            pointUp = CGPointMake(controllPoint.x + distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x - distX, controllPoint.y + distY);
        }
    }
    NSLog(@"control %@",NSStringFromCGPoint(controllPoint));
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint:endPoint];
    [arrowPath addLineToPoint:pointDown];
    [arrowPath addLineToPoint:pointUp];
    [arrowPath addLineToPoint:endPoint];
    return arrowPath;
}

//创建线条图层
- (CAShapeLayer *)createShapeLayer:(UIBezierPath *)path {
    /** 1、渲染快速。CAShapeLayer使用了硬件加速，绘制同一图形会比用Core Graphics快很多。Core Graphics实现示例： https://github.com/wsl2ls/Draw.git
     2、高效使用内存。一个CAShapeLayer不需要像普通CALayer一样创建一个寄宿图形，所以无论有多大，都不会占用太多的内存。
     3、不会被图层边界剪裁掉。
     4、不会出现像素化。 */
    CAShapeLayer *slayer = [CAShapeLayer layer];
    slayer.path = path.CGPath;
    slayer.backgroundColor = [UIColor clearColor].CGColor;
    slayer.fillColor = [UIColor clearColor].CGColor;
//    if(self.brushTool.shapeType != SLDrawShapeArrow){
//        slayer.lineCap = kCALineCapRound;
//        slayer.lineJoin = kCALineJoinRound;
//    }
    slayer.strokeColor = [UIColor redColor].CGColor;
    slayer.lineWidth = path.lineWidth;
    
    //自定义路径的描述
    return slayer;
}
- (void)createArrow {
    //箭头的角度
    CGFloat arrowAngle = 70*M_PI/180.f;
    //箭头腰长
    CGFloat arrowWaistLength = 34.f;
    //起点圆角半径
    CGFloat radius = 1.7;
    CGPoint beginPoint = CGPointMake(150, 100);
    CGPoint endpoint = CGPointMake(10, 100);

    CGPoint point1 = CGPointZero;
    CGPoint point2 = CGPointZero;
    CGPoint point3 = CGPointZero;
    CGPoint point4 = endpoint;//终点
    CGPoint point5 = CGPointZero;
    CGPoint point6 = CGPointZero;
    CGPoint point7 = CGPointZero;

    CGFloat lineAngle = [self angleBetweenStartPoint:beginPoint endPoint:endpoint];
    //箭头底边长
    CGFloat arrowBottomLength = arrowWaistLength*sin(arrowAngle/2.f)*2;
    
    //箭头空白地儿宽度
    CGFloat arrowGapWidth = 10.f;
    //箭头垂直高度
    CGFloat arrowVerticalLenght = arrowWaistLength *cos(arrowAngle/2.f);
    CGPoint arrowGapCenter = CGPointZero;
    if(endpoint.x > beginPoint.x){
        arrowGapCenter = CGPointMake(endpoint.x - arrowVerticalLenght*cos(lineAngle), endpoint.y + arrowVerticalLenght*sin(lineAngle));
    }else {
        arrowGapCenter = CGPointMake(endpoint.x + arrowVerticalLenght*cos(lineAngle), endpoint.y - arrowVerticalLenght*sin(lineAngle));
    }
    //两个箭头左右尖端
    point5 = CGPointMake(arrowGapCenter.x+ arrowBottomLength/2.f*sin(lineAngle), arrowGapCenter.y + arrowBottomLength/2.f*cos(lineAngle));
    point3 = CGPointMake(arrowGapCenter.x- arrowBottomLength/2.f*sin(lineAngle), arrowGapCenter.y - arrowBottomLength/2.f*cos(lineAngle));
    
    //两个箭头内角
    point6 = CGPointMake(arrowGapCenter.x+ arrowGapWidth/2.f*sin(lineAngle), arrowGapCenter.y + arrowGapWidth/2.f*cos(lineAngle));
    point2 = CGPointMake(arrowGapCenter.x- arrowGapWidth/2.f*sin(lineAngle), arrowGapCenter.y - arrowGapWidth/2.f*cos(lineAngle));
    //起点两边的角
    point1 = beginPoint;
    point7 = beginPoint;
    
    UIBezierPath *path = [[UIBezierPath alloc] init];
    path.lineWidth = 1;
    //底部半圆中心点
    if(endpoint.x > beginPoint.x){
        CGPoint arcCenter = CGPointMake(beginPoint.x + radius*cos(lineAngle), beginPoint.y - radius*sin(lineAngle));
        [path addArcWithCenter:arcCenter radius:M_PI startAngle:M_PI_2 - lineAngle endAngle:M_PI_2 - lineAngle + M_PI clockwise:YES];
    }else {
        CGPoint arcCenter = CGPointMake(beginPoint.x - radius*cos(lineAngle), beginPoint.y + radius*sin(lineAngle));
        [path addArcWithCenter:arcCenter radius:M_PI startAngle:M_PI_2 - lineAngle endAngle:M_PI_2 - lineAngle + M_PI clockwise:NO];
    }
    [path addLineToPoint:point2];
    [path addLineToPoint:point3];
    [path addLineToPoint:point4];
    [path addLineToPoint:point5];
    [path addLineToPoint:point6];
    [path closePath];
    

    CAShapeLayer *layer = [self createShapeLayer:path];
    
    [self.view.layer addSublayer:layer];

}
@end
