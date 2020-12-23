//
//  SLImageClipController.m
//  DarkMode
//
//  Created by wsl on 2019/11/2.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLImageClipController.h"
#import "SLImageZoomView.h"
#import "SLGridView.h"
#import "UIView+SLImage.h"
#import "UIView+SLFrame.h"
#import "SLUtilsMacro.h"
#import "SLSubMenuClipImageView.h"

#define KBottomMenuHeight (144+kSafeAreaBottomHeight)  //底部菜单高度
#define KGridTopMargin (16+kSafeAreaTopHeight)  //顶部间距
#define KGridBottomMargin 10  //底部间距
#define KGridLRMargin 16   //左右边距

@interface SLImageClipController ()<UIScrollViewDelegate, SLGridViewDelegate, SLImageZoomViewDelegate>

// 缩放视图
@property (nonatomic, strong) SLImageZoomView *zoomView;
//网格视图 裁剪框
@property (nonatomic, strong) SLGridView *gridView;
//底部操作栏
@property (nonatomic, strong) SLSubMenuClipImageView *menuView;

@property (nonatomic, strong) UILabel *testLabel;

/// 原始位置区域
@property (nonatomic, assign) CGRect originalRect;
/// 最大裁剪区域
@property (nonatomic, assign) CGRect maxGridRect;

/// 裁剪区域
//@property (nonatomic, assign) CGRect clipRect;

/// 当前旋转角度
@property (nonatomic, assign) NSInteger rotateAngle;
/// 图像方向
@property (nonatomic, assign) UIImageOrientation imageOrientation;
@property (nonatomic, assign) CGPoint originalOffset;
@property (nonatomic, assign) CGRect rotatedOriginalRect;
@property (nonatomic, assign) CGAffineTransform scaleTrans;

@end

@implementation SLImageClipController

//- (instancetype)initWithZoomView:(SLImageZoomView *)zoomView;{
//    self = [super init];
//    if(self){
//        self.scaleTrans = zoomView.transform;
//        self.image = zoomView.imageView.image;
//        _zoomView = zoomView;
//        _zoomView.imageView.backgroundColor = [UIColor greenColor];
//        [_zoomView removeFromSuperview];
//    }
//    return self;
//}
//
#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setupUI];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)dealloc {
    NSLog(@"图片裁剪视图释放了");
}
#pragma mark - UI
- (void)setupUI {
    self.zoomView.image = self.image;
    self.maxGridRect = CGRectMake(KGridLRMargin, KGridTopMargin, self.view.sl_width - KGridLRMargin * 2, self.view.sl_height - KGridTopMargin - KGridBottomMargin- KBottomMenuHeight);

    CGSize newSize = CGSizeMake(self.view.sl_width - 2 * KGridLRMargin, (self.view.sl_width - 2 * KGridLRMargin)*self.image.size.height/self.image.size.width);
    if (newSize.height > self.maxGridRect.size.height) {
        newSize = CGSizeMake(self.maxGridRect.size.height*self.image.size.width/self.image.size.height, self.maxGridRect.size.height);
        self.zoomView.sl_size = newSize;
        self.zoomView.sl_y = KGridTopMargin;
        self.zoomView.sl_centerX = self.view.sl_width/2.0;
    }else {
        self.zoomView.sl_size = newSize;
        self.zoomView.center = CGPointMake(self.view.sl_width/2.0, (self.view.sl_height - KBottomMenuHeight)/2.0);
    }

    [self.view addSubview:self.zoomView];
    self.zoomView.imageView.frame = self.zoomView.bounds;
    self.originalRect = self.zoomView.frame;
    self.rotatedOriginalRect = self.originalRect;
    self.gridView.originalGridRect = self.originalRect;
    self.gridView.gridRect = self.zoomView.frame;
    self.gridView.maxGridRect = self.maxGridRect;
    [self.view addSubview:self.gridView];
    
    //添加菜单
    UIView * bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.sl_height - KBottomMenuHeight, self.view.sl_width, KBottomMenuHeight)];
    bottomBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bottomBar];
    [self.view addSubview:self.menuView];
//    [self addTest];
    [self resetMinimumZoomScale];
    
}
- (void)addTest {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 30, 100, 40)];
    label.text = @"测试文字位置label呀";
    label.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
    [self.zoomView.imageView addSubview:label];
}

#pragma mark - Getter
- (SLImageZoomView *)zoomView {
    if (!_zoomView) {
        _zoomView = [[SLImageZoomView alloc] initWithFrame:CGRectMake(KGridLRMargin, KGridTopMargin, self.view.sl_width - KGridLRMargin *2,( self.view.sl_width - KGridLRMargin *2)*self.image.size.height/self.image.size.width)];
        _zoomView.sl_centerY = (self.view.sl_height - KBottomMenuHeight)/2.0;
        _zoomView.backgroundColor = [UIColor blackColor];
        _zoomView.backgroundColor = [UIColor redColor];
        _zoomView.imageView.backgroundColor = [UIColor greenColor];
        _zoomView.zoomViewDelegate = self;
        _scaleTrans = _zoomView.transform;
    }
    return _zoomView;
}
- (SLGridView *)gridView {
    if (!_gridView) {
        _gridView = [[SLGridView alloc] initWithFrame:self.view.bounds];
        _gridView.delegate = self;
    }
    return _gridView;
}
- (SLSubMenuClipImageView *)menuView {
    if(!_menuView){
        _menuView = [[SLSubMenuClipImageView alloc] initWithFrame:CGRectMake(0, self.view.sl_height - KBottomMenuHeight, self.view.sl_width, KBottomMenuHeight - kSafeAreaBottomHeight)];
        WS(weakSelf);
        _menuView.rotateBlock = ^{
            [weakSelf rotateBtnClicked:nil];
        };
        _menuView.cancelBlock = ^{
            [weakSelf cancleClipClicked:nil];
        };
        _menuView.doneBlock = ^{
            [weakSelf doneClipClicked:nil];
        };
        _menuView.selectScaleBlock = ^(NSInteger selectIndex) {
            if(selectIndex != 1){
                //更改zoomView的frame 和缩放比例 使图片可以全部展示在屏幕中间
                weakSelf.zoomView.frame = weakSelf.rotatedOriginalRect;
                weakSelf.gridView.originalGridRect = weakSelf.zoomView.frame;
                [weakSelf resetMinimumZoomScale];
                [weakSelf.zoomView setZoomScale:weakSelf.zoomView.minimumZoomScale];
            }
            if(selectIndex == 0){
                weakSelf.gridView.fixedScale = weakSelf.image.size.width/weakSelf.image.size.height;
            }else if (selectIndex == 1){
                weakSelf.gridView.fixedScale = 0;
            }else if (selectIndex == 2){
                weakSelf.gridView.fixedScale = 1;
            }else if (selectIndex == 3){
                weakSelf.gridView.fixedScale = 3/4.f;
            }else if (selectIndex == 4){
                weakSelf.gridView.fixedScale = 4/3.f;
            }else if (selectIndex == 5){
                weakSelf.gridView.fixedScale = 9/16.f;
            }else if (selectIndex == 6){
                weakSelf.gridView.fixedScale = 16/9.f;
            }
//            weakSelf.zoomView.frame =
        };
        _menuView.recoverBlock = ^{
            [weakSelf recoveryClicked:nil];
        };
    }
    return _menuView;
}
/// 返回图像方向
- (UIImageOrientation)imageOrientation {
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (_rotateAngle) {
        case 90:
        case -270:
            orientation = UIImageOrientationRight;
            break;
        case -90:
        case 270:
            orientation = UIImageOrientationLeft;
            break;
        case 180:
        case -180:
            orientation = UIImageOrientationDown;
            break;
        default:
            break;
    }
    _imageOrientation = orientation;
    return orientation;
}
#pragma mark - HelpMethods
//检查还原按钮是否可点
- (void)checkRecoverBtnIfEnable {
    if(CGRectEqualToRect(self.zoomView.frame ,self.originalRect) && _rotateAngle == 0 && self.zoomView.zoomScale == 1){
        [self.menuView enableRecoverBtn:NO];
    }else {
        [self.menuView enableRecoverBtn:YES];
    }
}
// 放大zoomView区域到指定网格gridRect区域
- (void)zoomInToRect:(CGRect)gridRect{
    // 正在拖拽或减速
    if (self.zoomView.dragging || self.zoomView.decelerating) {
        return;
    }
    
    CGRect imageRect = [self.zoomView convertRect:self.zoomView.imageView.frame toView:self.view];
    //当网格往图片边缘(x/y轴方向)移动即将出图片边界时，调整self.zoomView.contentOffset和缩放zoomView大小，把网格外的图片区域逐步移到网格内
    if (!CGRectContainsRect(imageRect,gridRect)) {
        CGPoint contentOffset = self.zoomView.contentOffset;
        if (self.imageOrientation == UIImageOrientationRight) {
            if (CGRectGetMaxX(gridRect) > CGRectGetMaxX(imageRect)) contentOffset.y = 0;
            if (CGRectGetMinY(gridRect) < CGRectGetMinY(imageRect)) contentOffset.x = 0;
        }
        if (self.imageOrientation == UIImageOrientationLeft) {
            if (CGRectGetMinX(gridRect) < CGRectGetMinX(imageRect)) contentOffset.y = 0;
            if (CGRectGetMaxY(gridRect) > CGRectGetMaxY(imageRect)) contentOffset.x = 0;
        }
        if (self.imageOrientation == UIImageOrientationUp) {
            if (CGRectGetMinY(gridRect) < CGRectGetMinY(imageRect)) contentOffset.y = 0;
            if (CGRectGetMinX(gridRect) < CGRectGetMinX(imageRect)) contentOffset.x = 0;
        }
        if (self.imageOrientation == UIImageOrientationDown) {
            if (CGRectGetMaxY(gridRect) > CGRectGetMaxY(imageRect)) contentOffset.y = 0;
            if (CGRectGetMaxX(gridRect) > CGRectGetMaxX(imageRect)) contentOffset.x = 0;
        }
        NSLog(@"新的偏移量====%@",NSStringFromCGPoint(contentOffset));
        self.zoomView.contentOffset = contentOffset;
        
        /** 取最大值缩放 */
        CGRect myFrame = self.zoomView.frame;
        myFrame.origin.x = MIN(myFrame.origin.x, gridRect.origin.x);
        myFrame.origin.y = MIN(myFrame.origin.y, gridRect.origin.y);
        myFrame.size.width = MAX(myFrame.size.width, gridRect.size.width);
        myFrame.size.height = MAX(myFrame.size.height, gridRect.size.height);
        self.zoomView.frame = myFrame;
        
        [self resetMinimumZoomScale];
        [self.zoomView setZoomScale:self.zoomView.zoomScale];
    }
}
//重置最小缩放系数  只要改变了zoomView大小就重置
- (void)resetMinimumZoomScale {
    CGRect rotateoriginalRect = CGRectApplyAffineTransform(self.originalRect, self.zoomView.transform);
    
//    CGRect rotateoriginalRect = self.rotatedOriginalRect;

    if (CGSizeEqualToSize(rotateoriginalRect.size, CGSizeZero)) {
        /** size为0时候不能继续，否则minimumZoomScale=+Inf，会无法缩放 */
        return;
    }
    //设置最小缩放系数
    CGFloat zoomScale = MAX(CGRectGetWidth(self.zoomView.frame) / CGRectGetWidth(rotateoriginalRect), CGRectGetHeight(self.zoomView.frame) / CGRectGetHeight(rotateoriginalRect));
    CGFloat zoomScale1 = MAX(CGRectGetWidth(self.zoomView.frame) / CGRectGetWidth(rotateoriginalRect), CGRectGetHeight(self.zoomView.frame) / CGRectGetHeight(rotateoriginalRect)) * self.scaleTrans.a;

    NSLog(@"最小比例是===%f ====%f",zoomScale,zoomScale1);
    self.zoomView.minimumZoomScale = zoomScale1;
//    self.zoomView.minimumZoomScale = 1;

}
//获取网格区域在图片上的相对位置
- (CGRect)rectOfGridOnImageByGridRect:(CGRect)cropRect {
    CGRect rect = [self.view convertRect:cropRect toView:self.zoomView.imageView];
    return rect;
}
//保存图片完成后调用的方法
- (void)savedPhotoImage:(UIImage*)image didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo {
    if (error) {
        NSLog(@"保存图片出错%@", error.localizedDescription);
    } else {
        NSLog(@"保存图片成功");
    }
}
#pragma mark - EventsHandle
- (void)rotateBtnClicked:(id)sender {
    _rotateAngle = (_rotateAngle-=90)%360;
    CGFloat angleInRadians = 0.0f;
    switch (_rotateAngle) {
        case 90:    angleInRadians = M_PI_2;            break;
        case -90:   angleInRadians = -M_PI_2;           break;
        case 180:   angleInRadians = M_PI;              break;
        case -180:  angleInRadians = -M_PI;             break;
        case 270:   angleInRadians = (M_PI + M_PI_2);   break;
        case -270:  angleInRadians = -(M_PI + M_PI_2);  break;
        default:                                        break;
    }
    //旋转前获得网格框在图片上选择的区域
    CGRect gridRectOfImage = [self rectOfGridOnImageByGridRect:self.gridView.gridRect];
    
    /// 旋转变形
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
    CGAffineTransform com = CGAffineTransformConcat(self.scaleTrans, transform);
    self.zoomView.transform = com;
    //transform后，bounds不会变，frame会变
    CGFloat width = CGRectGetWidth(self.zoomView.frame);
    CGFloat height = CGRectGetHeight(self.zoomView.frame);
    //计算旋转之后
    CGSize newSize = CGSizeMake(self.view.sl_width - 2 * KGridLRMargin, (self.view.sl_width - 2 * KGridLRMargin)*height/width);
    if (newSize.height > self.gridView.maxGridRect.size.height) {
        newSize = CGSizeMake(self.gridView.maxGridRect.size.height*width/height, self.gridView.maxGridRect.size.height);
        self.zoomView.sl_size = newSize;
        self.zoomView.sl_y = KGridTopMargin;
        self.zoomView.sl_centerX = self.view.sl_width/2.0;
    }else {
        self.zoomView.sl_size = newSize;
        self.zoomView.center = CGPointMake(self.view.sl_width/2.0, (self.view.sl_height - KBottomMenuHeight)/2.0);
    }
    //重新设置图片初始rect
    if(_rotateAngle%180 != 0){
        CGSize rotateSize = CGSizeMake(self.originalRect.size.height, self.originalRect.size.width);
        CGSize newSize = CGSizeMake(self.view.sl_width - 2 * KGridLRMargin, (self.view.sl_width - 2 * KGridLRMargin)*rotateSize.height/rotateSize.width);

       self.rotatedOriginalRect =  CGRectMake((self.view.sl_width - newSize.width)/2, (self.view.sl_height - KBottomMenuHeight - newSize.height)/2, newSize.width, newSize.height);
    }else {
        self.rotatedOriginalRect = self.originalRect;
    }
    //重新设置裁剪比例
    self.gridView.originalGridRect = self.zoomView.frame;
    if(!self.gridView.fixedScale){
        self.gridView.gridRect = self.zoomView.frame;
    }else {
        if(self.menuView.currentSelectIndex == 0){
            self.gridView.fixedScale = 1/self.gridView.fixedScale;
        }else if (self.menuView.currentSelectIndex == 2){
            [self.menuView selectIndex:2];
            self.gridView.fixedScale = 1.f;
        }
        else if(self.menuView.currentSelectIndex == 3){
            [self.menuView selectIndex:4];
            self.gridView.fixedScale = 4/3.f;
        }else if (self.menuView.currentSelectIndex == 4){
            [self.menuView selectIndex:3];
            self.gridView.fixedScale = 3/4.f;
        }else if (self.menuView.currentSelectIndex == 5){
            [self.menuView selectIndex:6];
            self.gridView.fixedScale = 16/9.f;
        }else if (self.menuView.currentSelectIndex == 6){
            self.menuView.currentSelectIndex = 5;
            self.gridView.fixedScale = 9/16.f;
        }
    }
    //重置最小缩放系数
    [self resetMinimumZoomScale];
    CGFloat scale = MIN(CGRectGetWidth(self.zoomView.frame) / width, CGRectGetHeight(self.zoomView.frame) / height);
    [self.zoomView setZoomScale:self.zoomView.zoomScale * scale];
    // 调整contentOffset
    if(_rotateAngle%180 != 0){
        self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale*self.scaleTrans.a - (self.gridView.gridRect.origin.y - self.zoomView.sl_y), gridRectOfImage.origin.y*self.zoomView.zoomScale*self.scaleTrans.d - (self.gridView.gridRect.origin.x - self.zoomView.sl_x));

    }else {
        self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale*self.scaleTrans.a - (self.gridView.gridRect.origin.x - self.zoomView.sl_x), gridRectOfImage.origin.y*self.zoomView.zoomScale*self.scaleTrans.d - (self.gridView.gridRect.origin.y - self.zoomView.sl_y));
    }
    
    NSLog(@"偏移===%@",NSStringFromCGPoint(self.zoomView.contentOffset));

    self.originalOffset = self.zoomView.contentOffset;
    //检查还原按钮
    [self checkRecoverBtnIfEnable];
}
- (void)cancleClipClicked:(id)sender {
    [self recoveryClicked:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
    if(self.clipFinishedBlock){
        self.clipFinishedBlock(self.zoomView);
    }
}
//还原
- (void)recoveryClicked:(UIButton *)sender {
    self.zoomView.minimumZoomScale = 1;
    self.zoomView.zoomScale = 1;
    self.zoomView.transform = self.scaleTrans;
    self.zoomView.frame = self.originalRect;
//    self.zoomView.imageView.frame = self.zoomView.bounds;
    self.gridView.gridRect = self.zoomView.frame;
    self.gridView.originalGridRect = self.zoomView.frame;
    self.rotatedOriginalRect = self.originalRect;
    self.gridView.fixedScale = 0;
    [self.menuView selectIndex:1];
    _rotateAngle = 0;
    [self checkRecoverBtnIfEnable];
}
//完成编辑
- (void)doneClipClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];

    UIImage *clipImage = [self.zoomView.imageView sl_imageByViewInRect:[self rectOfGridOnImageByGridRect:_gridView.gridRect]];
    UIImage *roImage = [UIImage imageWithCGImage:clipImage.CGImage scale:[UIScreen mainScreen].scale orientation:self.imageOrientation];
    self.zoomView.image = roImage;
    if(self.clipFinishedBlock){
        self.clipFinishedBlock(self.zoomView);
    }

//    [[NSNotificationCenter defaultCenter] postNotificationName:@"sl_ImageClippingComplete" object:nil userInfo:@{@"image" : roImage}];
}

#pragma mark - SLGridViewDelegate
//开始调整
- (void)gridViewDidBeginResizing:(SLGridView *)gridView {
    CGPoint contentOffset = self.zoomView.contentOffset;
    if (self.zoomView.contentOffset.x < 0) contentOffset.x = 0;
    if (self.zoomView.contentOffset.y < 0) contentOffset.y = 0;
    [self.zoomView setContentOffset:contentOffset animated:NO];
}
//正在调整
- (void)gridViewDidResizing:(SLGridView *)gridView {
    //放大到 >= gridRect
    [self zoomInToRect:gridView.gridRect];
}
// 结束调整
- (void)gridViewDidEndResizing:(SLGridView *)gridView {
    CGRect gridRectOfImage = [self rectOfGridOnImageByGridRect:gridView.gridRect];
    CGRect preZoomViewRect = self.zoomView.frame;
    //居中
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        CGSize newSize = CGSizeMake(self.view.sl_width - 2 * KGridLRMargin, (self.view.sl_width - 2 * KGridLRMargin)*gridView.gridRect.size.height/gridView.gridRect.size.width);
        if (newSize.height > self.gridView.maxGridRect.size.height) {
            newSize = CGSizeMake(self.gridView.maxGridRect.size.height*gridView.gridRect.size.width/gridView.gridRect.size.height, self.gridView.maxGridRect.size.height);
            self.zoomView.sl_size = newSize;
            self.zoomView.sl_y = KGridTopMargin;
            self.zoomView.sl_centerX = self.view.sl_width/2.0;
        }else {
            self.zoomView.sl_size = newSize;
            self.zoomView.center = CGPointMake(self.view.sl_width/2.0, (self.view.sl_height - KBottomMenuHeight)/2.0);
        }
        //重置最小缩放系数
        [self resetMinimumZoomScale];
        [self.zoomView setZoomScale:self.zoomView.zoomScale];
        // 调整contentOffset
//        CGFloat zoomScale = self.zoomView.sl_width/gridView.gridRect.size.width;
        CGFloat zoomScale = MIN(preZoomViewRect.size.width/gridView.gridRect.size.width, preZoomViewRect.size.height/gridView.gridRect.size.height);
        gridView.gridRect = self.zoomView.frame;
         NSLog(@"现在的缩放比例是===%f",zoomScale);
        [self.zoomView setZoomScale:self.zoomView.zoomScale * zoomScale];
        self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale*self.scaleTrans.a, gridRectOfImage.origin.y*self.zoomView.zoomScale*self.scaleTrans.d);
    } completion:^(BOOL finished) {
        [self checkRecoverBtnIfEnable];
    }];
}

#pragma mark - SLZoomViewDelegate
- (void)zoomViewDidBeginMoveImage:(SLImageZoomView *)zoomView {
    self.gridView.showMaskLayer = NO;
}
- (void)zoomViewDidEndMoveImage:(SLImageZoomView *)zoomView {
    self.gridView.showMaskLayer = YES;
}

@end
