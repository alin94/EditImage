//
//  SLEditImageController.m
//  DarkMode
//
//  Created by wsl on 2019/10/31.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditImageController.h"
#import <Photos/Photos.h>
#import "UIView+SLImage.h"
#import "UIView+SLFrame.h"
#import "NSString+SLLocalizable.h"
#import "SLEditMenuView.h"
#import "SLEditSelectedBox.h"
#import "SLImage.h"
#import "SLImageView.h"
#import "SLDrawView.h"
#import "SLEditTextView.h"
#import "SLMosaicView.h"
#import "UIImage+SLCommon.h"
#import "NSString+SLLocalizable.h"
#import "SLImageZoomView.h"
#import "SLImageClipController.h"
#import "SLDelayPerform.h"
#import "SLUtilsMacro.h"
#import "UIButton+SLButton.h"
#import "SLTransformGestureView.h"
#import "SLPaddingLabel.h"
#import "SLImageClipView.h"

#define SL_DISPATCH_ON_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(),mainQueueBlock);

#define KBottomMenuHeight (144+kSafeAreaBottomHeight)  //底部菜单高度
#define KImageTopMargin (16+kSafeAreaTopHeight)  //顶部间距
#define KImageBottomMargin 10  //底部间距
#define KImageLRMargin 16   //左右边距

@interface SLEditImageController ()<UIGestureRecognizerDelegate, SLImageZoomViewDelegate>

@property (nonatomic, strong) SLTransformGestureView *gestureView;
@property (nonatomic, strong) SLImageZoomView *zoomView; // 预览视图 展示编辑的图片 可以缩放
@property (nonatomic, strong) UIView *topNavView;
@property (nonatomic, strong) UIButton *cancelEditBtn; //取消编辑
@property (nonatomic, strong) SLEditMenuView *editMenuView; //编辑菜单栏
@property (nonatomic, strong) UIButton *trashTips; //垃圾桶提示 拖拽删除 贴图或文字

@property (nonatomic, strong) SLDrawBrushTool *drawGraffitiBrushTool;// 涂鸦工具
@property (nonatomic, strong) SLDrawBrushTool *drawMosicBrushTool;//马赛克工具
@property (nonatomic, strong) SLDrawView *drawView;//画板

@property (nonatomic, strong) SLImageClipView *clipView;//裁剪视图

@property (nonatomic, strong) NSMutableArray *watermarkArray; // 水印层 所有的贴图和文本
//@property (nonatomic, strong) SLEditSelectedBox *selectedBox; //水印选中框

@property (nonatomic, assign) SLEditMenuType editingMenuType; //当前正在编辑的菜单类型

@property (nonatomic, strong) NSMutableDictionary *menuSetting;//全部的设置

@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) CGAffineTransform normalTrans;
@property (nonatomic, assign) CGAffineTransform editingTrans;

@property (nonatomic, assign) CGFloat minNormalScale;
@property (nonatomic, assign) CGFloat minEditingScale;

@property (nonatomic, assign) NSInteger clipTime;


@end

@implementation SLEditImageController

#pragma mark - Override
- (instancetype)initWithImage:(UIImage *)image tipText:(NSString *)tipText {
    self = [super init];
    if(self){
        self.autoDismiss = YES;
        self.image = image;
        self.tipText = tipText;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _normalTrans = CGAffineTransformIdentity;
    _editingTrans = CGAffineTransformIdentity;
    self.minNormalScale = 1;
    [self setupUI];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}
- (BOOL)prefersStatusBarHidden {
    return YES;
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSLog(@"图片编辑视图释放了");
}

#pragma mark - UI
- (void)setupUI {
    self.view.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.zoomView];
    self.zoomView.pinchGestureRecognizer.enabled = YES;
    self.zoomView.image = self.image;
    
    //重新设置位置
    CGRect maxRect = self.view.bounds;
    UIImage *currentImage = self.zoomView.image;
    CGRect zoomViewBounds = CGRectZero;
    self.zoomView.contentOffset = CGPointZero;
    if(currentImage.size.width/currentImage.size.height > maxRect.size.width/maxRect.size.height){
        zoomViewBounds = CGRectMake(0, 0, maxRect.size.width, maxRect.size.width * currentImage.size.height/currentImage.size.width);
    }else {
        zoomViewBounds = CGRectMake(0, 0, maxRect.size.height*currentImage.size.width/currentImage.size.height, maxRect.size.height);
    }
    self.zoomView.frame = zoomViewBounds;
    self.zoomView.center = CGPointMake(self.view.sl_width/2, self.view.sl_height/2);
    self.zoomView.imageView.frame = self.zoomView.bounds;
    [self.zoomView.imageView addSubview:self.drawView];
    [self.zoomView.imageView addSubview:self.gestureView];
    [self.view addSubview:self.topNavView];
    [self hiddenEditMenus:NO];
}

#pragma mark - HelpMethods
- (void)hideTopNavView:(BOOL)isHidden{
    [self hiddenView:self.topNavView hidden:isHidden isBottom:NO originalRect:CGRectMake(0, 0, kScreenWidth,  64+kSafeAreaTopHeight)] ;
    [self hiddenView:self.cancelEditBtn hidden:isHidden isBottom:NO originalRect:CGRectMake(0, kSafeAreaTopHeight, 64, 64)];
}
- (void)hideMenuView:(BOOL)isHidden{
    [self hiddenView:self.editMenuView hidden:isHidden isBottom:YES originalRect:CGRectMake(0, self.view.sl_height - 144 - kSafeAreaBottomHeight, self.view.sl_width, 144 + kSafeAreaBottomHeight)];

}
- (void)hideTrashBtn:(BOOL)hide{
    [self hiddenView:self.trashTips hidden:hide isBottom:YES originalRect:CGRectMake((self.view.frame.size.width - 160)/2, self.view.frame.size.height - 80 - 10 - kSafeAreaBottomHeight, 160, 80)];

}
// 添加拖拽、缩放、旋转、单击、双击手势
- (void)addRotateAndPinchGestureRecognizer:(UIView *)view {
    if(!self.gestureView.superview){
        [self.zoomView.imageView addSubview:self.gestureView];
    }
    if(!view.superview){
        [self.gestureView addSubview:view];
    }
    [self.watermarkArray addObject:view];
    [self.gestureView addWatermarkView:view];
    [self topSelectedView:view];

}
//置顶视图
- (void)topSelectedView:(UIView *)topView {
    [self.zoomView.imageView bringSubviewToFront:topView];
    [self.watermarkArray removeObject:topView];
    [self.watermarkArray addObject:topView];
}
// 隐藏编辑时菜单按钮
- (void)hiddenEditMenus:(BOOL)isHidden {
    [self hideTopNavView:isHidden];
    [self hideMenuView:isHidden];
}
- (void)hiddenView:(UIView *)view hidden:(BOOL)hidden isBottom:(BOOL)isBottom originalRect:(CGRect)originalRect{
    if(view == nil || view.hidden == hidden){
        //        NSLog(@"隐藏视图是%@",view);
        return;
    }
    [view.layer removeAllAnimations];
    if (hidden) {
        [UIView animateWithDuration:0.25 animations:^{
            if(isBottom){
                view.frame = CGRectMake(view.frame.origin.x, self.view.frame.size.height, view.frame.size.width, view.frame.size.height);
            }else {
                view.frame = CGRectMake(view.frame.origin.x, -view.frame.size.height, view.frame.size.width, view.frame.size.height);
            }
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if(finished){
                view.hidden = YES;
                view.frame = originalRect;
            }else {
                NSLog(@"隐藏动画失败%@",view);
            }
        }];
        
    }else {
        view.hidden = NO;
        if(!view.superview){
            [self.view addSubview:view];
        }
        if(isBottom){
            view.frame = CGRectMake(view.frame.origin.x, self.view.frame.size.height, view.frame.size.width, view.frame.size.height);
        }else {
            view.frame = CGRectMake(view.frame.origin.x, -view.frame.size.height, view.frame.size.width, view.frame.size.height);
        }
        [UIView animateWithDuration:0.25 animations:^{
            view.frame = originalRect;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if(!finished){
                NSLog(@"显示动画失败%@",view);
            }
        }];
    }
}
- (void)changeZoomViewRectWithIsEditing:(BOOL)isEditing isClip:(BOOL)isClip {
    if(self.isEditing == isEditing){
        return;
    }
    self.isEditing = isEditing;
    self.zoomView.minimumZoomScale = 1;
    self.zoomView.zoomScale = 1;
    self.zoomView.contentOffset = CGPointZero;
    
    [UIView animateWithDuration:0.25 animations:^{
        CGRect maxRect = self.view.bounds;
        if(isEditing){
            maxRect = CGRectMake(KImageLRMargin, KImageTopMargin, self.view.sl_width - KImageLRMargin * 2, self.view.sl_height - KImageTopMargin - KImageBottomMargin- KBottomMenuHeight);
        }
        [self reConfigZoomImageViewRectWithMaxRect:maxRect isClip:isClip];
        [self.zoomView layoutIfNeeded];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        NSLog(@"%@",self.drawView);
    }];
}
- (void)reConfigZoomImageViewRectWithMaxRect:(CGRect)maxRect isClip:(BOOL)isClip {
    UIImage *currentImage = self.zoomView.image;
    CGRect zoomViewBounds = CGRectZero;
    self.zoomView.contentOffset = CGPointZero;
    if(currentImage.size.width/currentImage.size.height > maxRect.size.width/maxRect.size.height){
        zoomViewBounds = CGRectMake(0, 0, maxRect.size.width, maxRect.size.width * currentImage.size.height/currentImage.size.width);
    }else {
        zoomViewBounds = CGRectMake(0, 0, maxRect.size.height*currentImage.size.width/currentImage.size.height, maxRect.size.height);
    }
    if(maxRect.size.width != self.view.sl_width){
        CGSize newSize = zoomViewBounds.size;
        CGFloat scaleX = newSize.width/self.zoomView.imageView.frame.size.width;
        CGAffineTransform scale = CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleX);
        if(CGAffineTransformEqualToTransform(CGAffineTransformIdentity, self.editingTrans)){
            //最开始时候赋值
            self.editingTrans = scale;
        }
        self.zoomView.transform = self.editingTrans;
        self.zoomView.center = CGPointMake(maxRect.size.width/2.f+ maxRect.origin.x, maxRect.size.height/2.f + maxRect.origin.y);
        
    }else {
        //正常状态
        if(CGAffineTransformEqualToTransform(CGAffineTransformIdentity, self.normalTrans)){
            CGAffineTransform scale = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
            //最开始时候赋值
            self.normalTrans = scale;
        }
        
        self.zoomView.transform = self.normalTrans;
        self.zoomView.center = CGPointMake(maxRect.size.width/2.f+ maxRect.origin.x, maxRect.size.height/2.f + maxRect.origin.y);
    }
    self.zoomView.contentSize = self.zoomView.imageView.frame.size;
}

//改变
- (void)changeZoomViewRectWithIsEditing:(BOOL)isEditing {
    [self changeZoomViewRectWithIsEditing:isEditing isClip:NO];
}

#pragma mark - Setter
- (void)setIsEditing:(BOOL)isEditing {
    _isEditing = isEditing;
    [self hideTopNavView:isEditing];
}
- (void)setEditingMenuType:(SLEditMenuType)editingMenuType {
    _editingMenuType = editingMenuType;
    switch (_editingMenuType) {
        case SLEditMenuTypeUnknown:
            self.zoomView.imageView.clipsToBounds = YES;
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.gestureView.userInteractionEnabled = YES;
            self.drawView.enableDraw = NO;
            break;
        case SLEditMenuTypeGraffiti:
            self.zoomView.scrollEnabled = NO;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.gestureView.userInteractionEnabled = NO;
            self.drawView.enableDraw = YES;
            break;
        case SLEditMenuTypeText:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = NO;
            self.gestureView.userInteractionEnabled = YES;
            self.drawView.enableDraw = NO;
            break;
        case SLEditMenuTypeSticking:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = NO;
            self.gestureView.userInteractionEnabled = YES;
            self.drawView.enableDraw = NO;
            break;
        case SLEditMenuTypePictureMosaic:
            self.zoomView.scrollEnabled = NO;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.gestureView.userInteractionEnabled = NO;
            self.drawView.enableDraw = YES;
            break;
        case SLEditMenuTypePictureClipping:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.gestureView.userInteractionEnabled = NO;
            self.drawView.enableDraw = NO;
            break;
        default:
            break;
    }
}

#pragma mark - Getter
-(SLImageClipView *)clipView {
    if(!_clipView){
        _clipView = [[SLImageClipView alloc] initWithFrame:self.view.bounds];
        WS(weakSelf);
        _clipView.cancelBtnClickBlock = ^{
            [weakSelf.drawView hideMaskLayer:NO];
            weakSelf.editingMenuType = SLEditMenuTypeUnknown;
            [weakSelf changeZoomViewRectWithIsEditing:NO isClip:YES];
        };
        _clipView.doneBtnClickBlock = ^{
            CGFloat zoomScale = weakSelf.zoomView.zoomScale;
            CGPoint offset = weakSelf.zoomView.contentOffset;
            CGSize imageSize = weakSelf.zoomView.imageView.frame.size;
            CGPoint center1 = weakSelf.zoomView.imageView.center;
            NSLog(@"起始值==zoomScale=%f 偏移%@ 图片大小==%@  中心点==%@",zoomScale,NSStringFromCGPoint(offset),NSStringFromCGSize(imageSize),NSStringFromCGPoint(center1));
            weakSelf.zoomView.minimumZoomScale = 1;
            weakSelf.zoomView.zoomScale = 1;
            weakSelf.zoomView.center = CGPointMake(weakSelf.view.sl_width/2, weakSelf.view.sl_height/2);

            //记录编辑状态下视图的转变
            weakSelf.editingTrans = weakSelf.zoomView.transform;
            //正常的trans
            CGFloat scaleX = weakSelf.view.sl_width/weakSelf.zoomView.sl_width;
            CGFloat scaleY = weakSelf.view.sl_height/weakSelf.zoomView.sl_height;
            if(scaleX >scaleY){
                weakSelf.normalTrans =
                weakSelf.zoomView.transform = CGAffineTransformScale(weakSelf.editingTrans, scaleY, scaleY);
            }else {
                weakSelf.normalTrans =
                weakSelf.zoomView.transform = CGAffineTransformScale(weakSelf.editingTrans, scaleX, scaleX);
            }
            weakSelf.zoomView.contentOffset = CGPointZero;
            weakSelf.zoomView.imageView.bounds = weakSelf.zoomView.bounds;
            weakSelf.zoomView.imageView.frame = weakSelf.zoomView.bounds;
            weakSelf.zoomView.fixedImageViewCenter = weakSelf.zoomView.imageView.center;
            CGPoint center2 = weakSelf.zoomView.imageView.center;
            NSLog(@"设置完==图片大小==%@  中心点==%@",NSStringFromCGSize(weakSelf.zoomView.imageView.frame.size),NSStringFromCGPoint(center2));

            //imageview上的子视图做对应的transform
            for(UIView *subView in weakSelf.zoomView.imageView.subviews){
                CGSize oldSize = subView.frame.size;
                subView.transform = CGAffineTransformScale(subView.transform, zoomScale, zoomScale);
                    CGPoint center = subView.center;
                    center.x+= (subView.sl_width - oldSize.width)/2 - offset.x;
                    center.y+= (subView.sl_height - oldSize.height)/2 - offset.y;
                    subView.center = center;
            }
            weakSelf.editingMenuType = SLEditMenuTypeUnknown;
            weakSelf.isEditing = NO;
            CGRect displayRect = [weakSelf.zoomView.imageView convertRect:weakSelf.zoomView.imageView.frame toView:weakSelf.drawView];
            //设置显示区域
            weakSelf.drawView.displayRect = displayRect;
            [weakSelf.drawView hideMaskLayer:NO];
        };
    }
    return _clipView;
}
- (SLImageZoomView *)zoomView {
    if (_zoomView == nil) {
        _zoomView = [[SLImageZoomView alloc] initWithFrame:self.view.bounds];
        _zoomView.backgroundColor = [UIColor clearColor];
        _zoomView.userInteractionEnabled = YES;
        _zoomView.maximumZoomScale = MAXFLOAT;
        _zoomView.zoomViewDelegate = self;
        _zoomView.imageView.autoresizesSubviews = NO;

    }
    return _zoomView;
}
- (UIView *)topNavView {
    if(!_topNavView){
        _topNavView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 64+kSafeAreaTopHeight)];
        // Background Code
        CAGradientLayer *gl = [CAGradientLayer layer];
        gl.frame = _topNavView.bounds;
        gl.startPoint = CGPointMake(0.50, -1.48);
        gl.endPoint = CGPointMake(0.50, 1.00);
        gl.colors = @[
                      (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1].CGColor,
                      (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                      ];
        gl.locations = @[@(0),@(1)];
        [_topNavView.layer addSublayer:gl];
        [_topNavView addSubview:self.cancelEditBtn];
    }
    return _topNavView;
}
- (UIButton *)cancelEditBtn {
    if (_cancelEditBtn == nil) {
        _cancelEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, kSafeAreaTopHeight, 64, 64)];
        [_cancelEditBtn setTitle:kNSLocalizedString(@"取消") forState:UIControlStateNormal];
        [_cancelEditBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
        [_cancelEditBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelEditBtn addTarget:self action:@selector(cancelEditBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelEditBtn;
}

- (SLEditMenuView *)editMenuView {
    if (!_editMenuView) {
        _editMenuView = [[SLEditMenuView alloc] initWithFrame:CGRectMake(0, self.view.sl_height - 144 - kSafeAreaBottomHeight, self.view.sl_width, 144 + kSafeAreaBottomHeight)];
        _editMenuView.hidden = YES;
        _editMenuView.tipText = self.tipText;
        _editMenuView.doneBtnTitle = self.doneBtnTitle;
        __weak typeof(self) weakSelf = self;
        _editMenuView.editObject = SLEditObjectPicture;
        _editMenuView.doneBtnClickBlock = ^{
            [weakSelf doneEditBtnClicked:nil];
        };
        _editMenuView.hideSubMenuBlock = ^(SLEditMenuType menuType) {
            if(menuType == SLEditMenuTypeGraffiti || menuType == SLEditMenuTypePictureMosaic){
                weakSelf.editingMenuType = SLEditMenuTypeUnknown;
                [weakSelf changeZoomViewRectWithIsEditing:NO];
            }
        };
        _editMenuView.selectEditMenu = ^(SLEditMenuType editMenuType, NSDictionary * _Nullable setting) {
            weakSelf.editingMenuType = editMenuType;
            if (editMenuType == SLEditMenuTypeGraffiti || editMenuType == SLEditMenuTypePictureMosaic) {
                //添加画板视图
                if(!weakSelf.drawView.superview){
                    [weakSelf.zoomView.imageView insertSubview:weakSelf.drawView atIndex:0];
                }
                if(editMenuType == SLEditMenuTypeGraffiti){
                    weakSelf.drawView.brushTool = weakSelf.drawGraffitiBrushTool;
                }else {
                    weakSelf.drawView.brushTool = weakSelf.drawMosicBrushTool;
                }
                [weakSelf changeZoomViewRectWithIsEditing:YES];
                if (setting[@"lineColor"]) {
                    weakSelf.drawView.brushTool.isErase = NO;
                    weakSelf.drawView.brushTool.lineColor = setting[@"lineColor"];
                }
                if(setting[@"squareWidth"]){
                    weakSelf.drawView.brushTool.isErase = NO;
                    CGRect rect = [weakSelf.zoomView.imageView.superview convertRect:weakSelf.zoomView.imageView.frame toView:weakSelf.drawView];
                    weakSelf.drawView.brushTool.viewBounds =  weakSelf.drawView.bounds;
                    [weakSelf.drawView.brushTool setPatternImage:weakSelf.zoomView.imageView.image drawRect:rect];
                    weakSelf.drawView.brushTool.squareWidth = [setting[@"squareWidth"] floatValue];
                }
                if(setting[@"erase"]){
                    weakSelf.drawView.brushTool.isErase = [setting[@"erase"] boolValue];
                    if(weakSelf.drawView.brushTool.isErase){
                            CGRect rect = [weakSelf.zoomView.imageView.superview convertRect:weakSelf.zoomView.imageView.frame toView:weakSelf.drawView];
                        weakSelf.drawView.brushTool.viewBounds =  weakSelf.drawView.bounds;
                            [weakSelf.drawView.brushTool setPatternImage:weakSelf.zoomView.imageView.image drawRect:rect];
                    }
                }
                if (setting[@"goBack"]) {
                    [weakSelf.drawView goBack];
                }
                if (setting[@"goForward"]) {
                    [weakSelf.drawView goForward];
                }
                if(setting[@"goBackToLast"]) {
                    [weakSelf.drawView goBackToLastDrawState];
                    if(weakSelf.editingMenuType == SLEditMenuTypeGraffiti){
                        if(weakSelf.drawView.tempShapeViewArray.count){
                            //去掉之前画的线条
                            for(UIView *view in weakSelf.drawView.tempShapeViewArray){
                                if([weakSelf.gestureView.watermarkArray containsObject:view]){
                                    [weakSelf.gestureView.watermarkArray removeObject:view];
                                    [view removeFromSuperview];
                                }
                            }
                        }
                        [weakSelf.drawView.tempShapeViewArray removeAllObjects];
                    }
                }
                if (setting[@"lineWidth"]) {
                    weakSelf.drawView.brushTool.lineWidth = [setting[@"lineWidth"] floatValue];
                }
                if (setting[@"lineWidthIndex"]) {
                    weakSelf.drawView.brushTool.lineWidthIndex = [setting[@"lineWidthIndex"] floatValue];
                }

                if(setting[@"shape"]){
                    weakSelf.drawView.brushTool.shapeType = [setting[@"shape"] integerValue];
                    weakSelf.drawView.brushTool.isErase = NO;
                    [weakSelf.editMenuView selectLineColor:weakSelf.drawView.brushTool.lineColor];
                }
                //更新设置
                [weakSelf.menuSetting setValuesForKeysWithDictionary:setting];
            }
            if (editMenuType == SLEditMenuTypeSticking) {
                SLImage *image = setting[@"image"];
                if ([setting[@"hidden"] boolValue]) weakSelf.editingMenuType = SLEditMenuTypeUnknown;
                if (image) {
                    SLImageView *imageView = [[SLImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width/[UIScreen mainScreen].scale, image.size.height/[UIScreen mainScreen].scale)];
                    imageView.autoPlayAnimatedImage = NO;
                    CGRect imageRect = [weakSelf.zoomView convertRect:weakSelf.zoomView.imageView.frame toView:weakSelf.view];
                    CGPoint center = CGPointZero;
                    center.x = fabs(imageRect.origin.x)+weakSelf.zoomView.sl_width/2.0;
                    center.y = 0;
                    if (imageRect.origin.y >= 0 && imageRect.size.height <= weakSelf.zoomView.sl_height) {
                        center.y = imageRect.size.height/2.0;
                    }else {
                        center.y = fabs(imageRect.origin.y) + weakSelf.zoomView.sl_height/2.0;
                    }
                    imageView.transform = CGAffineTransformMakeScale(1/weakSelf.zoomView.zoomScale, 1/weakSelf.zoomView.zoomScale);
                    center = CGPointMake(center.x/weakSelf.zoomView.zoomScale, center.y/weakSelf.zoomView.zoomScale);
                    imageView.center = center;
                    imageView.image = image;
                    [weakSelf addRotateAndPinchGestureRecognizer:imageView];
                }
            }
            if (editMenuType == SLEditMenuTypeText) {
                weakSelf.isEditing = YES;
                weakSelf.editingMenuType = SLEditMenuTypeText;
                SLEditTextView *editTextView = [[SLEditTextView alloc] initWithFrame:CGRectMake(0, kSafeAreaTopHeight, kScreenWidth, kScreenHeight - kSafeAreaTopHeight - kSafeAreaBottomHeight)];
                [weakSelf.view addSubview:editTextView];
                editTextView.editTextCompleted = ^(UILabel * _Nullable label) {
                    weakSelf.isEditing = NO;
                    weakSelf.editingMenuType = SLEditMenuTypeUnknown;
                    if (label.text.length == 0 || label == nil) {
                        return;
                    }
                    //始终放在屏幕最中间
                    CGPoint newCenter = [weakSelf.view convertPoint:weakSelf.view.center toView:weakSelf.gestureView];
                    //恢复形变
                   CGFloat radians = atan2f(weakSelf.normalTrans.b, weakSelf.normalTrans.a);
                    CGAffineTransform rotateTrans = CGAffineTransformRotate(CGAffineTransformIdentity,radians);
                    CGAffineTransform invertTrans = CGAffineTransformInvert(rotateTrans);
                    CGFloat zoomScale = weakSelf.gestureView.sl_scaleX*weakSelf.zoomView.zoomScale;
                    CGAffineTransform scaleTrans = CGAffineTransformScale(invertTrans, 1/zoomScale, 1/zoomScale);
                    label.transform = scaleTrans;
                    label.center = newCenter;
                    //添加手势
                    [weakSelf addRotateAndPinchGestureRecognizer:label];
                };
            }
            if (editMenuType == SLEditMenuTypePictureClipping) {
                [weakSelf showImageClipVC];
            }

        };
        [self.view addSubview:_editMenuView];
    }
    return _editMenuView;
}
- (UIButton *)trashTips {
    if (!_trashTips) {
        _trashTips = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 160)/2, self.view.frame.size.height - 80 - 10 - kSafeAreaBottomHeight, 160, 80)];
        _trashTips.layer.cornerRadius = 10;
        _trashTips.clipsToBounds = YES;
        _trashTips.hidden = YES;
        [_trashTips setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _trashTips.titleLabel.font = [UIFont systemFontOfSize:12];
        [_trashTips setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_trashTips setTitle:kNSLocalizedString(@"拖动到此处删除") forState:UIControlStateNormal];
        [_trashTips setImage:[UIImage imageNamed:@"EditTrash"] forState:UIControlStateNormal];;
        [_trashTips setBackgroundColor:kColorWithHex(0x151515)];
        [_trashTips sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(22, 22) space:9];
    }
    return _trashTips;
}
- (SLDrawBrushTool *)drawMosicBrushTool {
    if(!_drawMosicBrushTool){
        _drawMosicBrushTool = [[SLDrawBrushTool alloc] initWithDrawBounds:self.zoomView.imageView.bounds];
    }
    return _drawMosicBrushTool;
}
-(SLDrawBrushTool *)drawGraffitiBrushTool {
    if(!_drawGraffitiBrushTool){
        _drawGraffitiBrushTool = [[SLDrawBrushTool alloc] initWithDrawBounds:self.zoomView.imageView.bounds];
    }
    return _drawGraffitiBrushTool;
}

- (SLDrawView *)drawView {
    if(!_drawView){
        _drawView = [[SLDrawView alloc] initWithFrame:self.zoomView.imageView.bounds];
        _drawView.shapeViewSuperView = self.gestureView;
        _drawView.backgroundColor = [UIColor clearColor];
        WS(weakSelf);
        _drawView.lineCountChangedBlock = ^(BOOL canBack, BOOL canForward) {
            [weakSelf.editMenuView enableBackBtn:canBack forwardBtn:canForward];
        };
        _drawView.drawShapeViewFinishedBlock = ^(UIView *shapeView, CAShapeLayer *layer) {
            //添加到手势管理view上
            [weakSelf addRotateAndPinchGestureRecognizer:shapeView];
        };
    }
    return _drawView;
}
- (SLTransformGestureView *)gestureView{
    if(!_gestureView){
        _gestureView = [[SLTransformGestureView alloc] initWithFrame:self.zoomView.imageView.bounds];
        _gestureView.watermarkArray = self.watermarkArray;
        [_gestureView changeEditBtnSuperView:self.view];
        WS(weakSelf);
        _gestureView.gestureActionBlock = ^(UIGestureRecognizer *gesture, UIView *currentSelectView) {
            if(currentSelectView){
                if(gesture.state == UIGestureRecognizerStateBegan){
                    [weakSelf topSelectedView:currentSelectView];
                }
                if([gesture isKindOfClass:[UITapGestureRecognizer class]]){
                    UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gesture;
                    //单击
                    if(tap.numberOfTapsRequired == 2 && currentSelectView){
                        [weakSelf doubleTapAction:tap withView:currentSelectView];
                    }
                }else if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]){
                    [weakSelf dragAction:(UIPanGestureRecognizer *)gesture withView:currentSelectView];
                }
            }
        };
    }
    return _gestureView;
}

- (NSMutableArray *)watermarkArray {
    if (!_watermarkArray) {
        _watermarkArray = [NSMutableArray array];
    }
    return _watermarkArray;
}
- (NSMutableDictionary *)menuSetting {
    if(!_menuSetting){
        _menuSetting = [NSMutableDictionary dictionary];
        //默认设置
        _menuSetting[@"lineWidth"] = @(4);
        _menuSetting[@"lineColor"] = kColorWithHex(0xFA5051);
    }
    return _menuSetting;
}
#pragma mark - Events Handle
- (void)showImageClipVC {
    [self changeZoomViewRectWithIsEditing:YES];
    [self.drawView hideMaskLayer:YES];
    if(!self.clipView.superview){
        [self.view addSubview:self.clipView];
    }
    [self.clipView startEditWithZoomView:self.zoomView];
}
//先把画板视图转成一整张图片加在imageView上（防止橡皮擦画笔图案位置错乱）
- (void)transDrawViewToImage {
    //把drawView拷贝成imageView贴上，并移除drawView
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self.drawView getDrawViewRenderImage]];
    [self.zoomView.imageView addSubview:imageView];
    imageView.contentMode = UIViewContentModeScaleToFill;
    imageView.transform = self.drawView.transform;
    imageView.frame = self.drawView.frame;
    imageView.bounds = self.drawView.bounds;
    [self.drawView removeFromSuperview];
}
//完成编辑 导出编辑后的对象
- (void)doneEditBtnClicked:(id)sender {
    [self.gestureView endEditing];
    [self transDrawViewToImage];
    UIImage *image = [self.zoomView.imageView sl_imageByViewInRect:self.zoomView.imageView.bounds shouldTranslateCTM:NO];
    UIImage *roImage = [UIImage imageWithCGImage:image.CGImage scale:[UIScreen mainScreen].scale orientation:self.clipView.imageOrientation];
    if(self.editFinishedBlock){
        self.editFinishedBlock(roImage);
    }
    if(self.autoDismiss){
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}
//取消编辑
- (void)cancelEditBtnClicked:(id)sender {
    if(self.cancelEditBlock){
        self.cancelEditBlock();
    }
    if(self.autoDismiss){
        [self dismissViewControllerAnimated:YES completion:^{
            
        }];
    }
}
//双击 文本水印 开始编辑文本
- (void)doubleTapAction:(UITapGestureRecognizer *)doubleTap withView:(UIView *)view {
    if(![view isKindOfClass:[SLPaddingLabel class]]){
        return;
    }
    view.hidden = YES;
    [self hideTopNavView:YES];
    SLPaddingLabel *tapLabel = (SLPaddingLabel *)view;
    SLEditTextView *editTextView = [[SLEditTextView alloc] initWithFrame:CGRectMake(0, kSafeAreaTopHeight, kScreenWidth, kScreenHeight - kSafeAreaTopHeight - kSafeAreaBottomHeight)];
    editTextView.configureEditParameters(@{@"textColor":tapLabel.textColor, @"backgroundColor":[UIColor colorWithCGColor:tapLabel.layer.backgroundColor], @"text":tapLabel.text, @"textAlignment":@(tapLabel.textAlignment)});
    WS(weakSelf);
    editTextView.editTextCompleted = ^(UILabel * _Nullable label) {
        [weakSelf hideTopNavView:NO];
        view.hidden = NO;
        if (label == nil) {
            return;
        }
        label.transform = tapLabel.transform;
        label.center = tapLabel.center;
        [tapLabel removeFromSuperview];
        [weakSelf.gestureView removeEditingView:tapLabel];
        [weakSelf addRotateAndPinchGestureRecognizer:label];
    };
    [self.view addSubview:editTextView];
}
// 拖拽 水印视图
- (void)dragAction:(UIPanGestureRecognizer *)pan withView:(UIView *)view{
    // 返回的是相对于最原始的手指的偏移量
    CGRect rect = [view convertRect:view.bounds toView:self.view];
    if([view isKindOfClass:[SLPaddingLabel class]]){
        //去掉空白区域的padding
        SLPaddingLabel *label = (SLPaddingLabel *)view;
        rect = CGRectMake(rect.origin.x - label.textPadding.left, rect.origin.y - label.textPadding.top, rect.size.width - label.textPadding.left - label.textPadding.right, rect.size.height - label.textPadding.top - label.textPadding.bottom);
    }
    if (pan.state == UIGestureRecognizerStateBegan) {
        [self hiddenEditMenus:YES];
        [self hideTrashBtn:NO];
    } else if (pan.state == UIGestureRecognizerStateChanged ) {
//        [self hiddenEditMenus:YES];
//        [self hiddenView:self.trashTips hidden:NO isBottom:YES];
        //获取拖拽的视图在屏幕上的位置
        //是否删除 删除视图Y < 视图中心点Y坐标
        if (CGRectIntersectsRect(self.trashTips.frame, rect)) {
            [self.trashTips setTitle:kNSLocalizedString(@"松手即可删除") forState:UIControlStateNormal];
            [self.trashTips setImage:[UIImage imageNamed:@"EditTrashOpen"] forState:UIControlStateNormal];;
            [self.trashTips setBackgroundColor:kColorWithHex(0xDC4747)];
            [_trashTips sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(22, 22) space:9];
        }else {
            [self.trashTips setTitle:kNSLocalizedString(@"拖动到此处删除") forState:UIControlStateNormal];
            [self.trashTips setImage:[UIImage imageNamed:@"EditTrash"] forState:UIControlStateNormal];;
            [self.trashTips setBackgroundColor:kColorWithHex(0x151515)];
            [_trashTips sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(22, 22) space:9];

        }

    } else if (pan.state == UIGestureRecognizerStateFailed || pan.state == UIGestureRecognizerStateEnded) {
        [self hiddenEditMenus:NO];
//        self.zoomView.imageView.clipsToBounds = YES;
        //获取拖拽的视图在屏幕上的位置
        CGRect imageRect = [self.zoomView convertRect:self.zoomView.imageView.frame toView:self.view];
        //删除拖拽的视图
        if (CGRectIntersectsRect(self.trashTips.frame, rect)) {
            [self.gestureView removeEditingView:view];
        }else if (!CGRectIntersectsRect(imageRect, rect)) {
            //如果出了父视图zoomView的范围，则置于屏幕中心
            CGPoint center = [self.view convertPoint:self.view.center toView:view.superview];
            [self.gestureView changeEditingViewCenter:center];
        }
        [self hideTrashBtn:YES];
    }
}
#pragma mark - SLZoomViewDelegate
- (void)zoomViewDidBeginMoveImage:(SLImageZoomView *)zoomView {
    if(self.editingMenuType == SLEditMenuTypePictureClipping){
        [_clipView showMaskLayer:NO];
    }
}
- (void)zoomViewDidEndMoveImage:(SLImageZoomView *)zoomView {
    self.drawView.superViewZoomScale = self.zoomView.zoomScale;
    if(self.editingMenuType == SLEditMenuTypePictureClipping){
        [_clipView showMaskLayer:YES];
    }
}
@end
