//
//  SLImageClipView.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/21.
//  Copyright © 2020 alin. All rights reserved.
//

#import "SLImageClipView.h"
#import "SLGridView.h"
#import "UIView+SLImage.h"
#import "UIView+SLFrame.h"
#import "SLUtilsMacro.h"
#import "SLSubMenuClipImageView.h"
#import "UIImage+SLCommon.h"
#define KBottomMenuHeight (144+kSafeAreaBottomHeight)  //底部菜单高度
#define KGridTopMargin (16+kSafeAreaTopHeight)  //顶部间距
#define KGridBottomMargin 10  //底部间距
#define KGridLRMargin 16   //左右边距


@interface SLImageClipZoomViewProperty : NSObject
//zoomView的
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, assign) CGFloat zoomScale;
@property (nonatomic, assign) CGFloat minimumZoomScale;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) CGAffineTransform imageViewTransform;

@property (nonatomic, assign) CGSize contentSize;


@property (nonatomic, assign) CGRect imageViewFrame;
@property (nonatomic, assign) CGPoint imageViewCenter;
@property (nonatomic, strong) SLImageClipZoomViewProperty *subViewProperty;

//只用记录当前初始视图的
@property (nonatomic, assign) NSInteger rotateAngle;
@property (nonatomic, assign) CGFloat fixedScale;
@property (nonatomic, assign) NSInteger menuScaleSelectIndex;




@end
@implementation SLImageClipZoomViewProperty

+ (id)getPropertyModelWithZoomView:(SLImageZoomView *)zoomView {
    SLImageClipZoomViewProperty *model = [[SLImageClipZoomViewProperty alloc] init];
    model.image = zoomView.image;
    model.zoomScale = zoomView.zoomScale;
    model.minimumZoomScale = zoomView.minimumZoomScale;
    model.frame = zoomView.frame;
    model.center = zoomView.center;
    model.contentOffset = zoomView.contentOffset;
    model.transform = zoomView.transform;
    model.contentSize = zoomView.contentSize;
    model.imageViewFrame = zoomView.imageView.frame;
    model.imageViewCenter = zoomView.imageView.center;
//    model.imageViewTransform = zoomView.imageView.transform;
    
    for(UIView *view in zoomView.imageView.subviews){
        SLImageClipZoomViewProperty *subP = [[SLImageClipZoomViewProperty alloc] init];
        subP.frame = view.frame;
        subP.center = view.center;
        subP.transform = view.transform;
        model.subViewProperty = subP;
        break;
    }
    return model;
}

@end



@interface SLImageClipView ()<UIScrollViewDelegate, SLGridViewDelegate, SLImageZoomViewDelegate>
//网格视图 裁剪框
@property (nonatomic, strong) SLGridView *gridView;
//底部操作栏
@property (nonatomic, strong) SLSubMenuClipImageView *menuView;
@property (nonatomic, strong) UIView *menuViewContainer;
/// 最大裁剪区域
@property (nonatomic, assign) CGRect maxGridRect;
/// 当前旋转角度
@property (nonatomic, assign) NSInteger rotateAngle;
//zoomView的转换
@property (nonatomic, assign) CGAffineTransform scaleTrans;
/// 原始位置区域
@property (nonatomic, assign) CGRect originalRect;
//旋转过的zoomView原始rect
@property (nonatomic, assign) CGRect rotatedOriginalRect;
@property (nonatomic, strong) UIImage *originalImage;
///上一次的属性
@property (nonatomic, strong) SLImageClipZoomViewProperty *lastPropertyModel;
//原始的属性
@property (nonatomic, strong) SLImageClipZoomViewProperty *originalPropertyModel;
//当前的属性
@property (nonatomic, strong) SLImageClipZoomViewProperty *currentPropertyModel;



@end
@implementation SLImageClipView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        [self setupUI];
    }
    return self;
}
- (void)startEditWithZoomView:(SLImageZoomView *)zoomView; {
    self.hidden = NO;
    if(!self.zoomView){
        self.zoomView = zoomView;
        self.originalRect = self.zoomView.frame;
        self.originalImage = self.zoomView.image;
        self.rotatedOriginalRect = self.originalRect;
        self.gridView.originalGridRect = self.originalRect;
        self.gridView.gridRect = self.zoomView.frame;
        self.gridView.maxGridRect = self.maxGridRect;
        //记录原始属性
        self.originalPropertyModel = [SLImageClipZoomViewProperty getPropertyModelWithZoomView:zoomView];
    }
    self.scaleTrans = zoomView.transform;
    //记录当前的属性
    self.currentPropertyModel = [SLImageClipZoomViewProperty getPropertyModelWithZoomView:zoomView];
    self.currentPropertyModel.rotateAngle = self.rotateAngle;
    self.currentPropertyModel.fixedScale = self.gridView.fixedScale;
    self.currentPropertyModel.menuScaleSelectIndex = self.menuView.currentSelectIndex;
    
    //还原成剪切前的状态
    if(self.lastPropertyModel){
        [self configZoomViewWithPropertyModel:self.lastPropertyModel];
        self.zoomView.image = self.originalImage;
    }
    [self resetMinimumZoomScale];
    //显示底部菜单
    [self hiddenView:self.menuViewContainer];
}
- (void)showMaskLayer:(BOOL)show {
    self.gridView.showMaskLayer = show;
}

#pragma mark - UI
- (void)setupUI {
    self.maxGridRect = CGRectMake(KGridLRMargin, KGridTopMargin, self.sl_width - KGridLRMargin * 2, self.sl_height - KGridTopMargin - KGridBottomMargin- KBottomMenuHeight);

    [self addSubview:self.gridView];
    self.gridView.hidden = YES;
    //添加菜单
    UIView * bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.sl_height - KBottomMenuHeight, self.sl_width, KBottomMenuHeight)];
    bottomBar.backgroundColor = [UIColor whiteColor];
    bottomBar.hidden = YES;
    [self addSubview:bottomBar];
    [bottomBar addSubview:self.menuView];
    self.menuViewContainer = bottomBar;
    [self resetMinimumZoomScale];
    
}
- (void)endEdit {
    self.gridView.hidden = YES;
    //隐藏底部菜单
    [self hiddenView:self.menuViewContainer];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.hidden = YES;
    });
}
#pragma mark - Getter
- (SLGridView *)gridView {
    if (!_gridView) {
        _gridView = [[SLGridView alloc] initWithFrame:self.bounds];
        _gridView.delegate = self;
    }
    return _gridView;
}
- (SLSubMenuClipImageView *)menuView {
    if(!_menuView){
        _menuView = [[SLSubMenuClipImageView alloc] initWithFrame:CGRectMake(0, 0, self.sl_width, KBottomMenuHeight - kSafeAreaBottomHeight)];
        WS(weakSelf);
        _menuView.rotateBlock = ^{
            [weakSelf rotateBtnClicked:nil];
        };
        _menuView.cancelBlock = ^{
            [weakSelf cancelClipClicked:nil];
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
                if(weakSelf.rotateAngle%180 != 0){
                    weakSelf.gridView.fixedScale =weakSelf.zoomView.image.size.height/ weakSelf.zoomView.image.size.width;
                }else {
                    weakSelf.gridView.fixedScale = weakSelf.zoomView.image.size.width/weakSelf.zoomView.image.size.height;
                }
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
- (CGFloat)transScaleX {

    CGAffineTransform trans = self.scaleTrans;
    if(!trans.b){
        return trans.a;
    }
    CGFloat angleInRadians = [self getRadiansWithRotateAngle:self.currentPropertyModel.rotateAngle];
    double aa = cos(angleInRadians);
    return trans.a/aa;
}
- (CGFloat)transScaleY {
//    CGAffineTransform trans = self.scaleTrans;
//    if(!trans.b){
//        return trans.d;
//    }
//    CGFloat angleInRadians = [self getRadiansWithRotateAngle:self.currentPropertyModel.rotateAngle];
//    double aa = sin(angleInRadians);
//    return trans.d/aa;
//
    return [self transScaleX];
}

#pragma mark - HelpMethods
//旋转角度转成弧度
- (CGFloat)getRadiansWithRotateAngle:(NSInteger)angle {
    CGFloat angleInRadians = 0;
    switch (angle) {
        case 90:    angleInRadians = M_PI_2;            break;
        case -90:   angleInRadians = -M_PI_2;           break;
        case 180:   angleInRadians = M_PI;              break;
        case -180:  angleInRadians = -M_PI;             break;
        case 270:   angleInRadians = (M_PI + M_PI_2);   break;
        case -270:  angleInRadians = -(M_PI + M_PI_2);  break;
        default:                                        break;
    }
    return angleInRadians;
}
//配置zoomView
- (void)configZoomViewWithPropertyModel:(SLImageClipZoomViewProperty *)model{
    self.zoomView.minimumZoomScale = model.minimumZoomScale;
    self.zoomView.zoomScale = model.zoomScale;
    self.zoomView.transform = model.transform;
    self.zoomView.frame = model.frame;
    self.zoomView.center = model.center;
    self.zoomView.contentOffset = model.contentOffset;
    
    self.zoomView.imageView.frame = model.imageViewFrame;
    self.zoomView.imageView.center = model.imageViewCenter;
    self.zoomView.contentSize = model.contentSize;
    for(UIView *sub in self.zoomView.imageView.subviews){
        //必须先设置transform
        sub.transform = model.subViewProperty.transform;
        sub.frame = model.subViewProperty.frame;
        sub.center = model.subViewProperty.center;
    }
}
//检查还原按钮是否可点
- (void)checkRecoverBtnIfEnable {
    if(CGRectEqualToRect(self.zoomView.frame ,self.originalRect) && _rotateAngle == 0 && self.zoomView.zoomScale == 1 && CGSizeEqualToSize(self.zoomView.image.size, self.originalImage.size)){
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
    
    CGRect imageRect = [self.zoomView convertRect:self.zoomView.imageView.frame toView:self];
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

    if (CGSizeEqualToSize(rotateoriginalRect.size, CGSizeZero)) {
        /** size为0时候不能继续，否则minimumZoomScale=+Inf，会无法缩放 */
        return;
    }
    //设置最小缩放系数
    CGFloat zoomScale1 = MAX(CGRectGetWidth(self.zoomView.frame) / CGRectGetWidth(rotateoriginalRect), CGRectGetHeight(self.zoomView.frame) / CGRectGetHeight(rotateoriginalRect)) * [self transScaleX];
    self.zoomView.minimumZoomScale = zoomScale1;
}
//获取网格区域在图片上的相对位置
- (CGRect)rectOfGridOnImageByGridRect:(CGRect)cropRect {
    CGRect rect = [self convertRect:cropRect toView:self.zoomView.imageView];
    NSLog(@"frame是这样的%@",NSStringFromCGRect(rect));
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
- (void)hiddenView:(UIView *)view {
    [self hiddenView:view hidden:!view.hidden];
}
- (void)hiddenView:(UIView *)view hidden:(BOOL)hidden{
    if(view == nil || view.hidden == hidden) return;
    if (hidden) {
        CGRect originalRect = view.frame;
        [UIView animateWithDuration:0.25 animations:^{
            view.frame = CGRectMake(0, self.frame.size.height, view.frame.size.width, view.frame.size.height);
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            view.hidden = YES;
            view.frame = originalRect;
            [view removeFromSuperview];
        }];
        
    }else {
        view.hidden = NO;
        [self addSubview:view];
        CGRect originalRect = view.frame;
        view.frame = CGRectMake(0, self.frame.size.height, view.frame.size.width, view.frame.size.height);
        [UIView animateWithDuration:0.25 animations:^{
            view.frame = originalRect;
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.gridView.hidden = NO;
        }];
    }
}


#pragma mark - EventsHandle
- (void)rotateBtnClicked:(id)sender {
    _rotateAngle = (_rotateAngle-=90)%360;
    CGFloat angleInRadians = [self getRadiansWithRotateAngle:_rotateAngle];
    //旋转前获得网格框在图片上选择的区域
    CGRect gridRectOfImage = [self rectOfGridOnImageByGridRect:self.gridView.gridRect];
    /// 旋转变形
    CGAffineTransform transform = CGAffineTransformRotate(CGAffineTransformIdentity, angleInRadians);
    CGAffineTransform scaleTrans = CGAffineTransformScale(CGAffineTransformIdentity,[self transScaleX], [self transScaleY]);
    CGAffineTransform com = CGAffineTransformConcat(transform, scaleTrans);
    self.zoomView.transform = com;
    //transform后，bounds不会变，frame会变
    CGFloat width = CGRectGetWidth(self.zoomView.frame);
    CGFloat height = CGRectGetHeight(self.zoomView.frame);
    //计算旋转之后
    CGSize newSize = CGSizeMake(self.sl_width - 2 * KGridLRMargin, (self.sl_width - 2 * KGridLRMargin)*height/width);
    if (newSize.height > self.gridView.maxGridRect.size.height) {
        newSize = CGSizeMake(self.gridView.maxGridRect.size.height*width/height, self.gridView.maxGridRect.size.height);
        self.zoomView.sl_size = newSize;
        self.zoomView.sl_y = KGridTopMargin;
        self.zoomView.sl_centerX = self.sl_width/2.0;
    }else {
        self.zoomView.sl_size = newSize;
        self.zoomView.center = CGPointMake(self.sl_width/2.0, (self.sl_height - KBottomMenuHeight)/2.0);
    }
    //重新设置图片初始rect
    if(_rotateAngle%180 != 0){
        CGSize rotateSize = CGSizeMake(self.originalRect.size.height, self.originalRect.size.width);
        CGSize newSize = CGSizeMake(self.sl_width - 2 * KGridLRMargin, (self.sl_width - 2 * KGridLRMargin)*rotateSize.height/rotateSize.width);
        
        self.rotatedOriginalRect =  CGRectMake((self.sl_width - newSize.width)/2, (self.sl_height - KBottomMenuHeight - newSize.height)/2, newSize.width, newSize.height);
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
        self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale - (self.gridView.gridRect.origin.y - self.zoomView.sl_y)*self.zoomView.zoomScale, gridRectOfImage.origin.y*self.zoomView.zoomScale - (self.gridView.gridRect.origin.x - self.zoomView.sl_x)*self.zoomView.zoomScale);

    }else {
        self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale- (self.gridView.gridRect.origin.x - self.zoomView.sl_x)*self.zoomView.zoomScale, gridRectOfImage.origin.y*self.zoomView.zoomScale- (self.gridView.gridRect.origin.y - self.zoomView.sl_y)*self.zoomView.zoomScale);
    }
    NSLog(@"偏移===%@",NSStringFromCGPoint(self.zoomView.contentOffset));
    //检查还原按钮
    [self checkRecoverBtnIfEnable];
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if(view == self){
        return nil;
    }
    return view;
}
- (void)cancelClipClicked:(id)sender {
    [self configZoomViewWithPropertyModel:self.currentPropertyModel];
    [self configZoomViewWithPropertyModel:self.currentPropertyModel];

    self.zoomView.image = self.currentPropertyModel.image;
    self.gridView.fixedScale = self.currentPropertyModel.fixedScale;
    [self.menuView selectIndex:self.currentPropertyModel.menuScaleSelectIndex];
    self.rotateAngle = self.currentPropertyModel.rotateAngle;
    self.gridView.gridRect = self.zoomView.frame;
    self.gridView.originalGridRect = self.zoomView.frame;
//    self.rotatedOriginalRect = self.originalRect;
    [self checkRecoverBtnIfEnable];
    //结束编辑
    [self endEdit];
    if(self.cancelBtnClickBlock){
        self.cancelBtnClickBlock();
    }
}
//还原
- (void)recoveryClicked:(id)sender {
    [self configZoomViewWithPropertyModel:self.originalPropertyModel];
    [self configZoomViewWithPropertyModel:self.originalPropertyModel];

    self.zoomView.image = self.originalImage;
    self.scaleTrans = self.originalPropertyModel.transform;

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
    [self resetZoomView];
    //记录上一次的状态
    self.lastPropertyModel = [SLImageClipZoomViewProperty getPropertyModelWithZoomView:self.zoomView];
    //结束编辑
    [self endEdit];
    //copy图片视图（为了去掉上面的子视图，只裁剪图片本身）
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.zoomView.image];
    imageView.transform = self.zoomView.imageView.transform;
    imageView.frame = self.zoomView.imageView.frame;
    imageView.bounds = self.zoomView.imageView.bounds;
    CGRect rect = [self rectOfGridOnImageByGridRect:_gridView.gridRect];
    UIImage *clipImage = [imageView sl_imageByViewInRect:rect];
    self.zoomView.image = clipImage;
    if(self.doneBtnClickBlock){
        self.doneBtnClickBlock();
    }
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
    CGFloat preZoomScale = MIN(preZoomViewRect.size.width/gridView.gridRect.size.width, preZoomViewRect.size.height/gridView.gridRect.size.height);
    //居中
    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         CGSize newSize = CGSizeMake(self.sl_width - 2 * KGridLRMargin, (self.sl_width - 2 * KGridLRMargin)*gridView.gridRect.size.height/gridView.gridRect.size.width);
                         if (newSize.height > self.gridView.maxGridRect.size.height) {
                             newSize = CGSizeMake(self.gridView.maxGridRect.size.height*gridView.gridRect.size.width/gridView.gridRect.size.height, self.gridView.maxGridRect.size.height);
                             self.zoomView.sl_size = newSize;
                             self.zoomView.sl_y = KGridTopMargin;
                             self.zoomView.sl_centerX = self.sl_width/2.0;

                         }else {
                             self.zoomView.sl_size = newSize;
                             self.zoomView.center = CGPointMake(self.sl_width/2.0, (self.sl_height - KBottomMenuHeight)/2.0);
                         }
                         CGFloat zoomScale = MIN(newSize.width/gridView.gridRect.size.width, newSize.height/gridView.gridRect.size.height);
                         if(self.zoomView.zoomScale == 1){
                             zoomScale = preZoomScale;
                         }
                         //重置最小缩放系数
                         [self resetMinimumZoomScale];
                         [self.zoomView setZoomScale:self.zoomView.zoomScale];
                         // 调整contentOffset
                         gridView.gridRect = self.zoomView.frame;
                         [self.zoomView setZoomScale:self.zoomView.zoomScale * zoomScale];
                         // 调整contentOffset
                         self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale, gridRectOfImage.origin.y*self.zoomView.zoomScale);
                         
                     } completion:^(BOOL finished) {
                         [self checkRecoverBtnIfEnable];
                     }];
}

- (void)resetZoomView {
    SLGridView *gridView = self.gridView;
    CGRect gridRectOfImage = [self rectOfGridOnImageByGridRect:gridView.gridRect];
    CGRect preZoomViewRect = self.zoomView.frame;
    CGFloat preZoomScale = MIN(preZoomViewRect.size.width/gridView.gridRect.size.width, preZoomViewRect.size.height/gridView.gridRect.size.height);


    CGSize newSize = CGSizeMake(self.sl_width - 2 * KGridLRMargin, (self.sl_width - 2 * KGridLRMargin)*gridView.gridRect.size.height/gridView.gridRect.size.width);
    if (newSize.height > self.gridView.maxGridRect.size.height) {
        newSize = CGSizeMake(self.gridView.maxGridRect.size.height*gridView.gridRect.size.width/gridView.gridRect.size.height, self.gridView.maxGridRect.size.height);
        self.zoomView.sl_size = newSize;
        self.zoomView.sl_y = KGridTopMargin;
        self.zoomView.sl_centerX = self.sl_width/2.0;
    }else {
        self.zoomView.sl_size = newSize;
        self.zoomView.center = CGPointMake(self.sl_width/2.0, (self.sl_height - KBottomMenuHeight)/2.0);
    }
    CGFloat zoomScale = MIN(newSize.width/gridView.gridRect.size.width, newSize.height/gridView.gridRect.size.height);
    if(self.zoomView.zoomScale == 1){
        zoomScale = preZoomScale;
    }
    //重置最小缩放系数
    [self resetMinimumZoomScale];
    [self.zoomView setZoomScale:self.zoomView.zoomScale];
    // 调整contentOffset
    gridView.gridRect = self.zoomView.frame;
    NSLog(@"现在的缩放比例是===%f",zoomScale);
    [self.zoomView setZoomScale:self.zoomView.zoomScale * zoomScale];
    self.zoomView.contentOffset = CGPointMake(gridRectOfImage.origin.x*self.zoomView.zoomScale, gridRectOfImage.origin.y*self.zoomView.zoomScale);
}


@end
