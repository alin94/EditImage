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

@property (nonatomic, strong) NSMutableArray *watermarkArray; // 水印层 所有的贴图和文本
//@property (nonatomic, strong) SLEditSelectedBox *selectedBox; //水印选中框

@property (nonatomic, assign) SLEditMenuType editingMenuType; //当前正在编辑的菜单类型

@property (nonatomic, strong) NSMutableDictionary *menuSetting;//全部的设置

@property (nonatomic, assign) BOOL isEditing;

@end

@implementation SLEditImageController

#pragma mark - Override
- (void)viewDidLoad {
    [super viewDidLoad];
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
    [self reConfigZoomImageViewRect];
    //添加裁剪完成监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageClippingComplete:) name:@"sl_ImageClippingComplete" object:nil];
    
    [self.view addSubview:self.topNavView];
    [self hiddenEditMenus:NO];
}

#pragma mark - HelpMethods
// 添加拖拽、缩放、旋转、单击、双击手势
- (void)addRotateAndPinchGestureRecognizer:(UIView *)view {
    view.userInteractionEnabled = YES;
    if(!self.gestureView.superview){
        [self.zoomView addSubview:self.gestureView];
    }
    [self.gestureView addWatermarkView:view];
}
//置顶视图
- (void)topSelectedView:(UIView *)topView {
    [self.zoomView.imageView bringSubviewToFront:topView];
    [self.watermarkArray removeObject:topView];
    [self.watermarkArray addObject:topView];
}
// 隐藏编辑时菜单按钮
- (void)hiddenEditMenus:(BOOL)isHidden {
    [self hiddenView:self.topNavView hidden:isHidden isBottom:NO] ;
    [self hiddenView:self.cancelEditBtn hidden:isHidden isBottom:NO];
    [self hiddenView:self.editMenuView hidden:isHidden isBottom:YES];
}
- (void)hiddenView:(UIView *)view hidden:(BOOL)hidden isBottom:(BOOL)isBottom{
    if(view == nil || view.hidden == hidden){
//        NSLog(@"隐藏视图是%@",view);
        return;
    }
    if (hidden) {
        CGRect originalRect = view.frame;
        [UIView animateWithDuration:0.25 animations:^{
            if(isBottom){
                view.frame = CGRectMake(view.frame.origin.x, self.view.frame.size.height, view.frame.size.width, view.frame.size.height);
            }else {
                view.frame = CGRectMake(view.frame.origin.x, -self.view.frame.size.height, view.frame.size.width, view.frame.size.height);
            }
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            view.hidden = YES;
            view.frame = originalRect;
            [view removeFromSuperview];
        }];
        
    }else {
        view.hidden = NO;
        [self.view addSubview:view];
        CGRect originalRect = view.frame;
        if(isBottom){
            view.frame = CGRectMake(view.frame.origin.x, self.view.frame.size.height, view.frame.size.width, view.frame.size.height);
        }else {
            view.frame = CGRectMake(view.frame.origin.x, -self.view.frame.size.height, view.frame.size.width, view.frame.size.height);
        }
        [UIView animateWithDuration:0.25 animations:^{
            view.frame = originalRect;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            
        }];
    }
}
//改变
- (void)changeZoomViewRectWithIsEditing:(BOOL)isEditing {
    if(self.isEditing == isEditing){
        return;
    }
    self.zoomView.zoomScale = 1;
    self.isEditing = isEditing;
    if(isEditing){
        CGRect maxRect = CGRectMake(KImageLRMargin, KImageTopMargin, self.view.sl_width - KImageLRMargin * 2, self.view.sl_height - KImageTopMargin - KImageBottomMargin- KBottomMenuHeight);
        CGSize newSize = CGSizeMake(self.view.sl_width - 2 * KImageLRMargin, (self.view.sl_width - 2 * KImageLRMargin)*self.zoomView.imageView.image.size.height/self.zoomView.imageView.image.size.width);
        CGPoint newCenter;
        if (newSize.height > maxRect.size.height) {
            newSize = CGSizeMake(maxRect.size.height*self.zoomView.imageView.image.size.width/self.zoomView.imageView.image.size.height, maxRect.size.height);
            newCenter = CGPointMake(self.view.sl_width/2.0, KImageTopMargin +newSize.height/2.0);
        }else {
            newCenter =  CGPointMake(self.view.sl_width/2.0, (self.view.sl_height - KBottomMenuHeight)/2.0);
        }
        CGFloat scaleX = newSize.width/self.zoomView.imageView.frame.size.width;
        CGFloat scaleY = newSize.height/self.zoomView.imageView.frame.size.height;
        [UIView animateWithDuration:0.25 animations:^{
            self.zoomView.center = newCenter;
            self.zoomView.transform = CGAffineTransformScale(CGAffineTransformIdentity, scaleX, scaleY);
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            
        }];

    }else {
        [UIView animateWithDuration:0.25 animations:^{
            self.zoomView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
            self.zoomView.center = CGPointMake(self.zoomView.sl_width/2.0, self.zoomView.sl_height/2.0);
            [self reConfigZoomImageViewRect];
            [self.zoomView layoutIfNeeded];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            
        }];
    }
}
//重新设置图片视图frame
- (void)reConfigZoomImageViewRect{
    if (self.image.size.width > 0) {
        self.zoomView.imageView.frame = CGRectMake(0, 0, self.zoomView.sl_width, self.zoomView.sl_width * self.zoomView.imageView.image.size.height/self.zoomView.imageView.image.size.width);
    }
    if (self.zoomView.imageView.sl_height <= self.zoomView.sl_height) {
        self.zoomView.imageView.center = CGPointMake(self.zoomView.sl_width/2.0, self.zoomView.sl_height/2.0);
    }
    _drawView.frame = self.zoomView.imageView.bounds;
}
#pragma mark - Setter
- (void)setEditingMenuType:(SLEditMenuType)editingMenuType {
    _editingMenuType = editingMenuType;
    switch (_editingMenuType) {
        case SLEditMenuTypeUnknown:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.gestureView.userInteractionEnabled = YES;
            break;
        case SLEditMenuTypeGraffiti:
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.zoomView.scrollEnabled = NO;
            self.gestureView.userInteractionEnabled = NO;
            break;
        case SLEditMenuTypeText:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = NO;
            self.gestureView.userInteractionEnabled = YES;
            break;
        case SLEditMenuTypeSticking:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = NO;
            self.gestureView.userInteractionEnabled = YES;
            break;
        case SLEditMenuTypePictureMosaic:
            self.zoomView.scrollEnabled = NO;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.gestureView.userInteractionEnabled = NO;
            break;
        case SLEditMenuTypePictureClipping:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.gestureView.userInteractionEnabled = NO;
            break;
        default:
            break;
    }
}

#pragma mark - Getter
- (SLImageZoomView *)zoomView {
    if (_zoomView == nil) {
        _zoomView = [[SLImageZoomView alloc] initWithFrame:self.view.bounds];
        _zoomView.backgroundColor = [UIColor redColor];
        _zoomView.userInteractionEnabled = YES;
        _zoomView.maximumZoomScale = 4;
        _zoomView.zoomViewDelegate = self;
    }
    return _zoomView;
}
- (UIView *)topNavView {
    if(!_topNavView){
        _topNavView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kNavigationHeight)];
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
        _cancelEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(21, 19+kSafeAreaTopHeight, 26, 26)];
        [_cancelEditBtn setImage:[UIImage imageNamed:@"EditImageCancel"] forState:UIControlStateNormal];
        [_cancelEditBtn addTarget:self action:@selector(cancelEditBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelEditBtn;
}

- (SLEditMenuView *)editMenuView {
    if (!_editMenuView) {
        _editMenuView = [[SLEditMenuView alloc] initWithFrame:CGRectMake(0, self.view.sl_height - 144 - kSafeAreaBottomHeight, self.view.sl_width, 144 + kSafeAreaBottomHeight)];
        _editMenuView.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _editMenuView.editObject = SLEditObjectPicture;
        _editMenuView.doneBtnClickBlock = ^{
            [weakSelf doneEditBtnClicked:nil];
        };
        _editMenuView.hideSubMenuBlock = ^(SLEditMenuType menuType) {
            if(menuType == SLEditMenuTypeGraffiti || menuType == SLEditMenuTypePictureMosaic){
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
                if(setting[@"hidden"]){
                    weakSelf.drawView.enableDraw = ![setting[@"hidden"] boolValue];
                }
                if (setting[@"lineColor"]) {
                    weakSelf.drawView.brushTool.isErase = NO;
                    weakSelf.drawView.brushTool.lineColor = setting[@"lineColor"];
                }
                if(setting[@"squareWidth"]){
                    weakSelf.drawView.brushTool.isErase = NO;
                    weakSelf.drawView.brushTool.image = weakSelf.zoomView.imageView.image;
                    weakSelf.drawView.brushTool.squareWidth = [setting[@"squareWidth"] floatValue];
                }
                if([setting[@"erase"] boolValue]) {
                    weakSelf.drawView.brushTool.isErase = YES;
                    weakSelf.drawView.brushTool.image = weakSelf.zoomView.imageView.image;
                }
                if (setting[@"goBack"]) {
                    [weakSelf.drawView goBack];
                }
                if (setting[@"goForward"]) {
                    [weakSelf.drawView goForward];
                }
                if(setting[@"goBackToLast"]) {
                    [weakSelf.drawView goBackToLastDrawState];
                }
                if (setting[@"lineWidth"]) {
                    weakSelf.drawView.brushTool.lineWidth = [setting[@"lineWidth"] floatValue];
                }
                if(setting[@"shape"]){
                    weakSelf.drawView.brushTool.shapeType = [setting[@"shape"] integerValue];
                }
                //更新设置
                [weakSelf.menuSetting setValuesForKeysWithDictionary:setting];
            }else {
                weakSelf.drawView.userInteractionEnabled = NO;
            }
            if (editMenuType == SLEditMenuTypeSticking) {
                SLImage *image = setting[@"image"];
                if ([setting[@"hidden"] boolValue]) weakSelf.editingMenuType = SLEditMenuTypeUnknown;
                if (image) {
                    SLImageView *imageView = [[SLImageView alloc] initWithFrame:CGRectMake(0, 0, image.size.width/[UIScreen mainScreen].scale, image.size.height/[UIScreen mainScreen].scale)];
                    imageView.autoPlayAnimatedImage = NO;
                    imageView.userInteractionEnabled = YES;
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
                    [weakSelf.watermarkArray addObject:imageView];
                    [weakSelf.zoomView.imageView addSubview:imageView];
                    [weakSelf addRotateAndPinchGestureRecognizer:imageView];
                    [weakSelf topSelectedView:imageView];
                }
            }
            if (editMenuType == SLEditMenuTypeText) {
                SLEditTextView *editTextView = [[SLEditTextView alloc] initWithFrame:CGRectMake(0, kSafeAreaTopHeight, kScreenWidth, kScreenHeight - kSafeAreaTopHeight - kSafeAreaBottomHeight)];
                [weakSelf.view addSubview:editTextView];
                if ([setting[@"hidden"] boolValue]) weakSelf.editingMenuType = SLEditMenuTypeUnknown;
                editTextView.editTextCompleted = ^(UILabel * _Nullable label) {
                    weakSelf.topNavView.hidden = NO;
                    if (label.text.length == 0 || label == nil) {
                        return;
                    }
                    CGRect imageRect = [weakSelf.zoomView convertRect:weakSelf.zoomView.imageView.frame toView:weakSelf.view];
                    CGPoint center = CGPointZero;
                    center.x = fabs(imageRect.origin.x)+weakSelf.zoomView.sl_width/2.0;
                    center.y = 0;
                    if (imageRect.origin.y >= 0 && imageRect.size.height <= weakSelf.zoomView.sl_height) {
                        center.y = imageRect.size.height/2.0;
                    }else {
                        center.y = fabs(imageRect.origin.y) + weakSelf.zoomView.sl_height/2.0;
                    }
                    label.transform = CGAffineTransformMakeScale(1/weakSelf.zoomView.zoomScale, 1/weakSelf.zoomView.zoomScale);
                    center = CGPointMake(center.x/weakSelf.zoomView.zoomScale, center.y/weakSelf.zoomView.zoomScale);
                    label.center = center;
                    [weakSelf.zoomView.imageView addSubview:label];
                    [weakSelf.watermarkArray addObject:label];
                    [weakSelf addRotateAndPinchGestureRecognizer:label];
                    [weakSelf topSelectedView:label];
                };
                weakSelf.topNavView.hidden = YES;
            }else{
                weakSelf.topNavView.hidden = NO;
            }
//            if(editMenuType == SLEditMenuTypePictureMosaic) {
//                if (setting[@"mosaicType"]) {
//                    weakSelf.mosaicView.userInteractionEnabled = ![setting[@"hidden"] boolValue];
//                    if ([setting[@"hidden"] boolValue]) weakSelf.editingMenuType = SLEditMenuTypeUnknown;
//                    weakSelf.mosaicView.mosaicType = [setting[@"mosaicType"] integerValue];
//                    [weakSelf.zoomView.imageView insertSubview:weakSelf.mosaicView atIndex:0];
//                }
//                if (setting[@"goBack"]) {
//                    [weakSelf.mosaicView goBack];
//                }
//                //更新设置
//                [weakSelf.menuSetting setValuesForKeysWithDictionary:setting];
//            }else {
//                weakSelf.mosaicView.userInteractionEnabled = NO;
//            }
            if (editMenuType == SLEditMenuTypePictureClipping) {
                weakSelf.isEditing = YES;
                SLImageClipController *imageClipController = [[SLImageClipController alloc] init];
                imageClipController.modalPresentationStyle = UIModalPresentationFullScreen;
                UIImage *image = [weakSelf.zoomView.imageView sl_imageByViewInRect:weakSelf.zoomView.imageView.bounds shouldTranslateCTM:YES];
                imageClipController.image = image;
                [weakSelf presentViewController:imageClipController animated:NO completion:nil];
            }
            weakSelf.editingMenuType = ![setting[@"hidden"] boolValue] ? editMenuType : SLEditMenuTypeUnknown;

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
        _drawView.backgroundColor = [UIColor clearColor];
        WS(weakSelf);
        _drawView.lineCountChangedBlock = ^(BOOL canBack, BOOL canForward) {
            [weakSelf.editMenuView enableBackBtn:canBack forwardBtn:canForward];
        };
    }
    return _drawView;
}
- (SLTransformGestureView *)gestureView{
    if(!_gestureView){
        _gestureView = [[SLTransformGestureView alloc] initWithFrame:self.zoomView.imageView.bounds];
        _gestureView.watermarkArray = self.watermarkArray;
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
//- (SLDrawBrushTool *)currentDrawBrushTool{
//    if(self.editingMenuType == SLEditMenuTypeGraffiti){
//        return self.drawGraffitiBrushTool;
//    }
//    if(self.editingMenuType  == SLEditMenuTypePictureMosaic){
//        return self.drawMosicBrushTool;
//    }
//    return nil;
//
//}
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
        _menuSetting[@"lineColor"] = kColorWithHex(0xF2F2F2);
    }
    return _menuSetting;
}
#pragma mark - Events Handle
//取消编辑
- (void)cancelEditBtnClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];
}
//完成编辑 导出编辑后的对象
- (void)doneEditBtnClicked:(id)sender {
    self.image = [self.zoomView.imageView sl_imageByViewInRect:self.zoomView.imageView.bounds shouldTranslateCTM:YES];
    if(self.editFinishedBlock){
        self.editFinishedBlock(self.image);
    }
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];

}
//双击 文本水印 开始编辑文本
- (void)doubleTapAction:(UITapGestureRecognizer *)doubleTap withView:(UIView *)view {
    view.hidden = YES;
    SLPaddingLabel *tapLabel = (SLPaddingLabel *)view;
    SLEditTextView *editTextView = [[SLEditTextView alloc] initWithFrame:CGRectMake(0, kSafeAreaTopHeight, kScreenWidth, kScreenHeight - kSafeAreaTopHeight - kSafeAreaBottomHeight)];
    editTextView.configureEditParameters(@{@"textColor":tapLabel.textColor, @"backgroundColor":tapLabel.sl_backgroundColor, @"text":tapLabel.text, @"textAlignment":@(tapLabel.textAlignment)});
    editTextView.editTextCompleted = ^(UILabel * _Nullable label) {
        view.hidden = NO;
        if (label == nil) {
            return;
        }
        label.transform = tapLabel.transform;
        label.center = tapLabel.center;
        [tapLabel removeFromSuperview];
        [self.watermarkArray removeObject:tapLabel];
        [self.watermarkArray addObject:label];
        [self.zoomView.imageView addSubview:label];
        [self addRotateAndPinchGestureRecognizer:label];
        [self topSelectedView:label];
    };
    [self.view addSubview:editTextView];
}
// 拖拽 水印视图
- (void)dragAction:(UIPanGestureRecognizer *)pan withView:(UIView *)view{
    // 返回的是相对于最原始的手指的偏移量
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.zoomView.imageView.clipsToBounds = NO;
        [self hiddenEditMenus:YES];
        [self hiddenView:self.trashTips hidden:NO isBottom:YES];
    } else if (pan.state == UIGestureRecognizerStateChanged ) {
        [self hiddenEditMenus:YES];
        [self hiddenView:self.trashTips hidden:NO isBottom:YES];
        
        //获取拖拽的视图在屏幕上的位置
        CGRect rect = [view convertRect: view.bounds toView:self.view];
        //是否删除 删除视图Y < 视图中心点Y坐标
        if (self.trashTips.center.y < rect.origin.y+rect.size.height/2.0) {
            [self.trashTips setTitle:kNSLocalizedString(@"松手即可删除") forState:UIControlStateNormal];
            [self.trashTips setImage:[UIImage imageNamed:@"EditTrashOpen"] forState:UIControlStateNormal];;
            [self.trashTips setBackgroundColor:kColorWithHex(0xDC4747)];
        }else {
            [self.trashTips setTitle:kNSLocalizedString(@"拖动到此处删除") forState:UIControlStateNormal];
            [self.trashTips setImage:[UIImage imageNamed:@"EditTrash"] forState:UIControlStateNormal];;
            [self.trashTips setBackgroundColor:kColorWithHex(0x151515)];
        }

    } else if (pan.state == UIGestureRecognizerStateFailed || pan.state == UIGestureRecognizerStateEnded) {
        [self hiddenEditMenus:NO];
        self.zoomView.imageView.clipsToBounds = YES;
        //获取拖拽的视图在屏幕上的位置
        CGRect rect = [view convertRect: view.bounds toView:self.view];
        CGRect imageRect = [self.zoomView convertRect:self.zoomView.imageView.frame toView:self.view];
        //删除拖拽的视图
        if (self.trashTips.center.y < rect.origin.y+rect.size.height/2.0) {
            [view  removeFromSuperview];
            [self.watermarkArray removeObject:view];
        }else if (!CGRectIntersectsRect(imageRect, rect)) {
            //如果出了父视图zoomView的范围，则置于父视图中心
            CGPoint center = CGPointZero;
            center.x = fabs(imageRect.origin.x)+self.zoomView.sl_width/2.0;
            center.y = 0;
            if (imageRect.origin.y >= 0 && imageRect.size.height <= self.zoomView.sl_height) {
                center.y = imageRect.size.height/2.0;
            }else {
                center.y = fabs(imageRect.origin.y) + self.zoomView.sl_height/2.0;
            }
            center = CGPointMake(center.x/self.zoomView.zoomScale, center.y/self.zoomView.zoomScale);
            view.center = center;
        }
        [self hiddenView:self.trashTips hidden:YES isBottom:YES];
    }
}

// 图片裁剪完成
- (void)imageClippingComplete:(NSNotification *)notification {
    UIImage *clipImage = notification.userInfo[@"image"];
    self.zoomView.zoomScale = 1;
    self.zoomView.image = clipImage;
    [self changeZoomViewRectWithIsEditing:NO];
    [_drawView clear];
    for (UIView *view in self.watermarkArray) {
        [view removeFromSuperview];
    }
    [self.watermarkArray removeAllObjects];
}
#pragma mark - UIGestureRecognizerDelegate
// 该方法返回的BOOL值决定了view是否能够同时响应多个手势
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    //     NSLog(@"%@ - %@", gestureRecognizer.class, otherGestureRecognizer.class);
    return YES;
}

#pragma mark - SLZoomViewDelegate
- (void)zoomViewDidEndMoveImage:(SLImageZoomView *)zoomView {
//    self.drawView.lineWidth = [self.menuSetting[@"lineWidth"] floatValue]/self.zoomView.zoomScale;
//    self.mosaicView.squareWidth = 15/self.zoomView.zoomScale;
//    self.mosaicView.paintSize = CGSizeMake(40/self.zoomView.zoomScale, 40/self.zoomView.zoomScale);
}
- (void)zoomViewDidEndZoom:(SLImageZoomView *)zoomView {
    _gestureView.frame = zoomView.imageView.frame;
    CGRect rect = [zoomView.imageView convertRect:zoomView.imageView.frame toView:self.zoomView];

}

@end
