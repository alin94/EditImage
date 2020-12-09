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
#import "SLImageZoomView.h"
#import "SLImageClipController.h"
#import "SLDelayPerform.h"
#import "SLRoundCornerLabel.h"
#import "SLUtilsMacro.h"
#define SL_DISPATCH_ON_MAIN_THREAD(mainQueueBlock) dispatch_async(dispatch_get_main_queue(),mainQueueBlock);

#define KBottomMenuHeight (144+kSafeAreaBottomHeight)  //底部菜单高度
#define KImageTopMargin (16+kSafeAreaTopHeight)  //顶部间距
#define KImageBottomMargin 10  //底部间距
#define KImageLRMargin 16   //左右边距

@interface SLEditImageController ()<UIGestureRecognizerDelegate, SLImageZoomViewDelegate>

@property (nonatomic, strong) SLImageZoomView *zoomView; // 预览视图 展示编辑的图片 可以缩放
@property (nonatomic, strong) UIView *topNavView;
@property (nonatomic, strong) UIButton *cancelEditBtn; //取消编辑
@property (nonatomic, strong) SLEditMenuView *editMenuView; //编辑菜单栏
@property (nonatomic, strong) UIButton *trashTips; //垃圾桶提示 拖拽删除 贴图或文字

@property (nonatomic, strong) SLDrawView *drawView; // 涂鸦视图
@property (nonatomic, strong) NSMutableArray *watermarkArray; // 水印层 所有的贴图和文本
@property (nonatomic, strong) SLEditSelectedBox *selectedBox; //水印选中框
@property (nonatomic, strong) SLMosaicView *mosaicView; //马赛克画板

@property (nonatomic, assign) SLEditMenuType editingMenuType; //当前正在编辑的菜单类型

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
    //单击手势选中
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapAction:)];
    singleTap.numberOfTapsRequired = 1;
    singleTap.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:singleTap];
    if ([view isKindOfClass:[UILabel class]]) {
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        doubleTap.numberOfTapsRequired = 2;
        doubleTap.numberOfTouchesRequired = 1;
        [singleTap requireGestureRecognizerToFail:doubleTap];
        [view addGestureRecognizer:doubleTap];
    }
    //拖拽手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dragAction:)];
    pan.minimumNumberOfTouches = 1;
    [view addGestureRecognizer:pan];
    //缩放手势
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(pinchAction:)];
    pinchGestureRecognizer.delegate = self;
    [view addGestureRecognizer:pinchGestureRecognizer];
    //旋转手势
    UIRotationGestureRecognizer *rotateRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(rotateAction:)];
    [view addGestureRecognizer:rotateRecognizer];
    rotateRecognizer.delegate = self;
}
//置顶视图
- (void)topSelectedView:(UIView *)topView {
    [self.zoomView.imageView bringSubviewToFront:topView];
    [self.watermarkArray removeObject:topView];
    [self.watermarkArray addObject:topView];
    [SLDelayPerform sl_cancelDelayPerform]; //取消延迟执行
    self.selectedBox.frame = topView.bounds;
    [topView addSubview:self.selectedBox];
}
// 隐藏编辑时菜单按钮
- (void)hiddenEditMenus:(BOOL)isHidden {
    self.cancelEditBtn.hidden = self.topNavView.hidden = isHidden;
    self.editMenuView.hidden = isHidden;
}
//改变
- (void)changeZoomViewRectWithIsEditing:(BOOL)isEditing {
    if(isEditing){
        CGRect maxRect = CGRectMake(KImageLRMargin, KImageTopMargin, self.view.sl_width - KImageLRMargin * 2, self.view.sl_height - KImageTopMargin - KImageBottomMargin- KBottomMenuHeight);
        CGSize newSize = CGSizeMake(self.view.sl_width - 2 * KImageLRMargin, (self.view.sl_width - 2 * KImageLRMargin)*self.image.size.height/self.image.size.width);
        if (newSize.height > maxRect.size.height) {
            newSize = CGSizeMake(maxRect.size.height*self.image.size.width/self.image.size.height, maxRect.size.height);
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.zoomView.sl_size = newSize;
                self.zoomView.sl_y = KImageTopMargin;
                self.zoomView.sl_centerX = self.view.sl_width/2.0;
                self.zoomView.imageView.frame = self.zoomView.bounds;
                [self.zoomView layoutIfNeeded];
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                
            }];
            
        }else {
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.zoomView.sl_size = newSize;
                self.zoomView.center = CGPointMake(self.view.sl_width/2.0, (self.view.sl_height - KBottomMenuHeight)/2.0);
                [self reConfigZoomImageViewRect];
                [self.zoomView layoutIfNeeded];
                [self.view layoutIfNeeded];
            } completion:^(BOOL finished) {
                
            }];
        }
    }else {
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.zoomView.frame = self.view.bounds;
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
        self.zoomView.imageView.frame = CGRectMake(0, 0, self.zoomView.sl_width, self.zoomView.sl_width * self.image.size.height/self.image.size.width);
    }
    if (self.zoomView.imageView.sl_height <= self.zoomView.sl_height) {
        self.zoomView.imageView.center = CGPointMake(self.zoomView.sl_width/2.0, self.zoomView.sl_height/2.0);
    }
}
- (void)enableEditMenusBackBtn:(BOOL)enable {
    [self.editMenuView enableBackBtn:enable];
}
#pragma mark - Setter
- (void)setEditingMenuType:(SLEditMenuType)editingMenuType {
    if(editingMenuType != _editingMenuType){
        [self changeZoomViewRectWithIsEditing:editingMenuType == SLEditMenuTypeUnknown?NO:YES];
    }
    _editingMenuType = editingMenuType;
    switch (_editingMenuType) {
        case SLEditMenuTypeUnknown:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            break;
        case SLEditMenuTypeGraffiti:
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            self.zoomView.scrollEnabled = NO;
            break;
        case SLEditMenuTypeText:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = NO;
            break;
        case SLEditMenuTypeSticking:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = NO;
            break;
        case SLEditMenuTypePictureMosaic:
            self.zoomView.scrollEnabled = NO;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
            break;
        case SLEditMenuTypePictureClipping:
            self.zoomView.scrollEnabled = YES;
            self.zoomView.pinchGestureRecognizer.enabled = YES;
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
        _editMenuView = [[SLEditMenuView alloc] initWithFrame:CGRectMake(0, self.view.sl_height - 130 - kSafeAreaBottomHeight, self.view.sl_width, 130 + kSafeAreaBottomHeight)];
        _editMenuView.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _editMenuView.editObject = SLEditObjectPicture;
        _editMenuView.doneBtnClickBlock = ^{
            [weakSelf doneEditBtnClicked:nil];
        };
        _editMenuView.selectEditMenu = ^(SLEditMenuType editMenuType, NSDictionary * _Nullable setting) {
            weakSelf.editingMenuType = ![setting[@"hidden"] boolValue] ? editMenuType : SLEditMenuTypeUnknown;
            if (editMenuType == SLEditMenuTypeGraffiti) {
                weakSelf.drawView.userInteractionEnabled = ![setting[@"hidden"] boolValue];
                if ([setting[@"hidden"] boolValue]) weakSelf.editingMenuType = SLEditMenuTypeUnknown;
                [weakSelf.zoomView.imageView insertSubview:weakSelf.drawView atIndex:([weakSelf.zoomView.imageView.subviews containsObject:weakSelf.mosaicView] ? 1: 0)];
                if (setting[@"lineColor"]) {
                    weakSelf.drawView.lineColor = setting[@"lineColor"];
                }
                if (setting[@"goBack"]) {
                    [weakSelf.drawView goBack];
                }
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
                    [SLDelayPerform sl_startDelayPerform:^{
                        [weakSelf.selectedBox removeFromSuperview];
                    } afterDelay:1.0];
                }
            }
            if (editMenuType == SLEditMenuTypeText) {
                SLEditTextView *editTextView = [[SLEditTextView alloc] initWithFrame:CGRectMake(0, kSafeAreaTopHeight, kScreenWidth, kScreenHeight - kSafeAreaTopHeight - kSafeAreaBottomHeight)];
                [weakSelf.view addSubview:editTextView];
                if ([setting[@"hidden"] boolValue]) weakSelf.editingMenuType = SLEditMenuTypeUnknown;
                editTextView.editTextCompleted = ^(SLRoundCornerLabel * _Nullable label) {
                    weakSelf.topNavView.hidden = NO;
                    if (label.attributedString.string.length == 0 || label == nil) {
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
                    [SLDelayPerform sl_startDelayPerform:^{
                        [weakSelf.selectedBox removeFromSuperview];
                    } afterDelay:1.0];
                };
                weakSelf.topNavView.hidden = YES;
            }else{
                weakSelf.topNavView.hidden = NO;
            }
            if(editMenuType == SLEditMenuTypePictureMosaic) {
                if (setting[@"mosaicType"]) {
                    weakSelf.mosaicView.userInteractionEnabled = ![setting[@"hidden"] boolValue];
                    if ([setting[@"hidden"] boolValue]) weakSelf.editingMenuType = SLEditMenuTypeUnknown;
                    weakSelf.mosaicView.mosaicType = [setting[@"mosaicType"] integerValue];
                    [weakSelf.zoomView.imageView insertSubview:weakSelf.mosaicView atIndex:0];
                }
                if (setting[@"goBack"]) {
                    [weakSelf.mosaicView goBack];
                }
            }else {
                weakSelf.mosaicView.userInteractionEnabled = NO;
            }
            if (editMenuType == SLEditMenuTypePictureClipping) {
                SLImageClipController *imageClipController = [[SLImageClipController alloc] init];
                imageClipController.modalPresentationStyle = UIModalPresentationFullScreen;
                [weakSelf.selectedBox removeFromSuperview];
                UIImage *image = [weakSelf.zoomView.imageView sl_imageByViewInRect:weakSelf.zoomView.imageView.bounds];
                imageClipController.image = image;
                [weakSelf presentViewController:imageClipController animated:NO completion:nil];
            }
        };
        [self.view addSubview:_editMenuView];
    }
    return _editMenuView;
}
- (UIButton *)trashTips {
    if (!_trashTips) {
        _trashTips = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
        _trashTips.center = CGPointMake(kScreenWidth/2.0, kScreenHeight - 60);
        [_trashTips setTitle:@"拖动到此处删除" forState:UIControlStateNormal];
        [_trashTips setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _trashTips.titleLabel.font = [UIFont systemFontOfSize:14];
    }
    return _trashTips;
}
- (SLDrawView *)drawView {
    if (!_drawView) {
        _drawView = [[SLDrawView alloc] initWithFrame:self.zoomView.imageView.bounds];
        _drawView.backgroundColor = [UIColor clearColor];
        _drawView.lineWidth = 5.0;
        __weak typeof(self) weakSelf = self;
        _drawView.drawBegan = ^{
            [weakSelf hiddenEditMenus:YES];
        };
        _drawView.drawEnded = ^{
            [weakSelf hiddenEditMenus:NO];
        };
        _drawView.canBackStatusChangedBlock = ^(BOOL enable) {
            [weakSelf enableEditMenusBackBtn:enable];
        };
    }
    return _drawView;
}
- (NSMutableArray *)watermarkArray {
    if (!_watermarkArray) {
        _watermarkArray = [NSMutableArray array];
    }
    return _watermarkArray;
}
- (SLEditSelectedBox *)selectedBox {
    if (!_selectedBox) {
        _selectedBox = [[SLEditSelectedBox alloc] init];
    }
    return _selectedBox;
}
- (SLMosaicView *)mosaicView {
    if (!_mosaicView) {
        _mosaicView = [[SLMosaicView alloc] initWithFrame:self.zoomView.imageView.bounds];
        __weak typeof(self) weakSelf = self;
        _mosaicView.squareWidth = 15;
        _mosaicView.paintSize = CGSizeMake(40, 40);
        _mosaicView.brushColor = ^UIColor *(CGPoint point) {
            point.x = point.x/weakSelf.view.frame.size.width*weakSelf.zoomView.image.size.width;
            point.y = point.y/weakSelf.view.frame.size.height*weakSelf.zoomView.image.size.height;
            point.x = point.x/self.zoomView.zoomScale;
            point.y = point.y/self.zoomView.zoomScale;
            return [weakSelf.zoomView.image sl_colorAtPixel:point];
        };
        _mosaicView.brushBegan = ^{
            [weakSelf hiddenEditMenus:YES];
        };
        _mosaicView.brushEnded = ^{
            [weakSelf hiddenEditMenus:NO];
        };
        _mosaicView.canBackStatusChangedBlock = ^(BOOL enable) {
            [weakSelf enableEditMenusBackBtn:enable];
        };
        _mosaicView.userInteractionEnabled = YES;
    }
    return _mosaicView;
}
#pragma mark - Events Handle
//取消编辑
- (void)cancelEditBtnClicked:(id)sender {
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];
}
//完成编辑 导出编辑后的对象
- (void)doneEditBtnClicked:(id)sender {
    [self.selectedBox removeFromSuperview];
    self.image = [self.zoomView.imageView sl_imageByViewInRect:self.zoomView.imageView.bounds];
    if(self.editFinishedBlock){
        self.editFinishedBlock(self.image);
    }
    [self dismissViewControllerAnimated:NO completion:^{
        
    }];

}
// 点击水印视图
- (void)singleTapAction:(UITapGestureRecognizer *)singleTap {
    [self topSelectedView:singleTap.view];
    if (singleTap.state == UIGestureRecognizerStateFailed || singleTap.state == UIGestureRecognizerStateEnded) {
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    }
}
//双击 文本水印 开始编辑文本
- (void)doubleTapAction:(UITapGestureRecognizer *)doubleTap {
    [self topSelectedView:doubleTap.view];
    doubleTap.view.hidden = YES;
    SLRoundCornerLabel *tapLabel = (SLRoundCornerLabel *)doubleTap.view;
    SLEditTextView *editTextView = [[SLEditTextView alloc] initWithFrame:CGRectMake(0, kSafeAreaTopHeight, kScreenWidth, kScreenHeight - kSafeAreaTopHeight - kSafeAreaBottomHeight)];
    NSAttributedString *att = tapLabel.attributedString;
    __block NSDictionary *attrDict = nil;
    [att enumerateAttributesInRange:NSMakeRange(0, att.length) options:1 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        if(attrs){
            attrDict = attrs;
            *stop = YES;
        }
    }];
    
    editTextView.configureEditParameters(@{@"textColor":[attrDict valueForKey:NSForegroundColorAttributeName], @"backgroundColor":tapLabel.fillColor, @"text":att.string});
    editTextView.editTextCompleted = ^(UILabel * _Nullable label) {
        doubleTap.view.hidden = NO;
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
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    };
    [self.view addSubview:editTextView];
}
// 拖拽 水印视图
- (void)dragAction:(UIPanGestureRecognizer *)pan {
    // 返回的是相对于最原始的手指的偏移量
    CGPoint transP = [pan translationInView:self.zoomView.imageView];
    if (pan.state == UIGestureRecognizerStateBegan) {
        self.zoomView.imageView.clipsToBounds = NO;
        [self hiddenEditMenus:YES];
        [self.view addSubview:self.trashTips];
        [self topSelectedView:pan.view];
    } else if (pan.state == UIGestureRecognizerStateChanged ) {
        pan.view.center = CGPointMake(pan.view.center.x + transP.x, pan.view.center.y + transP.y);
        [pan setTranslation:CGPointZero inView:self.zoomView.imageView];
        //获取拖拽的视图在屏幕上的位置
        CGRect rect = [pan.view convertRect: pan.view.bounds toView:self.view];
        //是否删除 删除视图Y < 视图中心点Y坐标
        if (self.trashTips.center.y < rect.origin.y+rect.size.height/2.0) {
            [self.trashTips setTitle:@"松手即可删除" forState:UIControlStateNormal];
            [self.trashTips setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        }else {
            [self.trashTips setTitle:@"拖动到此处删除" forState:UIControlStateNormal];
            [self.trashTips setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    } else if (pan.state == UIGestureRecognizerStateFailed || pan.state == UIGestureRecognizerStateEnded) {
        [self hiddenEditMenus:NO];
        self.zoomView.imageView.clipsToBounds = YES;
        //获取拖拽的视图在屏幕上的位置
        CGRect rect = [pan.view convertRect: pan.view.bounds toView:self.view];
        CGRect imageRect = [self.zoomView convertRect:self.zoomView.imageView.frame toView:self.view];
        //删除拖拽的视图
        if (self.trashTips.center.y < rect.origin.y+rect.size.height/2.0) {
            [pan.view  removeFromSuperview];
            [self.watermarkArray removeObject:(SLImageView *)pan.view];
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
            pan.view.center = center;
        }
        [self.trashTips removeFromSuperview];
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    }
}
//缩放 水印视图
- (void)pinchAction:(UIPinchGestureRecognizer *)pinch {
    if (pinch.state == UIGestureRecognizerStateBegan) {
        [self topSelectedView:pinch.view];
        self.zoomView.pinchGestureRecognizer.enabled = NO;
        self.zoomView.imageView.clipsToBounds = NO;
    }else if (pinch.state == UIGestureRecognizerStateFailed || pinch.state == UIGestureRecognizerStateEnded){
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
        self.zoomView.pinchGestureRecognizer.enabled = YES;
        self.zoomView.imageView.clipsToBounds = YES;
    }
    pinch.view.transform = CGAffineTransformScale(pinch.view.transform, pinch.scale, pinch.scale);
    pinch.scale = 1.0;
}
//旋转 水印视图 注意：旋转之后的frame会变！！！
- (void)rotateAction:(UIRotationGestureRecognizer *)rotation {
    if (rotation.state == UIGestureRecognizerStateBegan) {
        [self topSelectedView:rotation.view];
    }else if (rotation.state == UIGestureRecognizerStateFailed || rotation.state == UIGestureRecognizerStateEnded){
        [SLDelayPerform sl_startDelayPerform:^{
            [self.selectedBox removeFromSuperview];
        } afterDelay:1.0];
    }
    rotation.view.transform = CGAffineTransformRotate(rotation.view.transform, rotation.rotation);
    // 将旋转的弧度清零(注意不是将图片旋转的弧度清零, 而是将当前手指旋转的弧度清零)
    rotation.rotation = 0;
}
// 图片裁剪完成
- (void)imageClippingComplete:(NSNotification *)notification {
    UIImage *clipImage = notification.userInfo[@"image"];
    self.zoomView.zoomScale = 1;
    self.zoomView.image = clipImage;
    self.zoomView.imageView.frame = CGRectMake(0, 0, self.zoomView.sl_width, self.zoomView.sl_width * clipImage.size.height/clipImage.size.width);
    if (self.zoomView.imageView.sl_height <= self.zoomView.sl_height) {
        self.zoomView.imageView.center = CGPointMake(self.zoomView.sl_width/2.0, self.zoomView.sl_height/2.0);
    }
    self.zoomView.contentSize = CGSizeMake(self.zoomView.imageView.sl_width, self.zoomView.imageView.sl_height);
    
    _drawView.frame = self.zoomView.imageView.bounds;
    _mosaicView.frame = self.zoomView.imageView.bounds;
    [_drawView clear];
    [_mosaicView clear];
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
    self.drawView.lineWidth = 5.0/self.zoomView.zoomScale;
    self.mosaicView.squareWidth = 15/self.zoomView.zoomScale;
    self.mosaicView.paintSize = CGSizeMake(40/self.zoomView.zoomScale, 40/self.zoomView.zoomScale);
}

@end
