//
//  SLEditMenuView.m
//  DarkMode
//
//  Created by wsl on 2019/10/9.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditMenuView.h"
#import "SLImageView.h"
#import "SLImage.h"
#import "SLUtilsMacro.h"
#import "SLSubmenuGraffitiView.h"
#import "SLSubmenuMosaicView.h"
#import "NSString+SLLocalizable.h"

//贴画CollectionViewCell
@interface SLSubmenuStickingCell : UICollectionViewCell
@property (nonatomic, strong) SLImageView *imageView;
@end
@implementation SLSubmenuStickingCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    _imageView = [[SLImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:_imageView];
}
- (void)setImage:(NSString *)imageName {
    _imageView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    _imageView.image = [SLImage imageNamed:imageName];
}
@end
/// 贴画子菜单
@interface SLSubmenuStickingView : UIView <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) NSMutableArray *dataSource;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, copy) void(^selectedImage)(SLImage *image); //选中的图片 贴画
@end
@implementation SLSubmenuStickingView
- (instancetype)init {
    self = [super init];
    if (self) {
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self createSubmenu];
}
- (void)createSubmenu {
    [self addSubview:self.collectionView];
}
#pragma mark - Getter
- (UICollectionView *)collectionView {
    if (_collectionView == nil) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        [_collectionView registerClass:[SLSubmenuStickingCell class] forCellWithReuseIdentifier:@"ItemId"];
    }
    return _collectionView;
}
- (NSMutableArray *)dataSource {
    if (_dataSource == nil) {
        _dataSource = [NSMutableArray array];
        for (int i = 0; i < 20; i++) {
            [_dataSource addObject:[NSString stringWithFormat:@"Resources.bundle/StickingImages/stickers_%d",i]];
        }
    }
    return _dataSource;
}
#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataSource.count;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SLSubmenuStickingCell * item = [collectionView dequeueReusableCellWithReuseIdentifier:@"ItemId" forIndexPath:indexPath];
    [item setImage:self.dataSource[indexPath.row]];
    return item;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    self.selectedImage([SLImage imageNamed:self.dataSource[indexPath.row]]);
}
#pragma mark -  UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((self.frame.size.width - 5*10)/4.0, self.frame.size.height);
}
//列间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 10;
}
//行间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 10;
}
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 10, 0, 10);
}
@end

/// 编辑主菜单
@interface SLEditMenuView ()
@property (nonatomic, strong) NSArray *menuTypes; //编辑类型集合
@property (nonatomic, strong) NSArray *imageNames; //编辑图标名称
@property (nonatomic, strong) NSArray *imageNamesSelected; //选中的 编辑图标名称
@property (nonatomic, strong) NSMutableArray *menuBtns; //编辑菜单按钮集合
@property (nonatomic, assign) SLEditMenuType currentMenuType; //当前编辑类型

@property (nonatomic, strong) UIView *currentSubmenu; //当前显示的子菜单
@property (nonatomic, strong) SLSubmenuGraffitiView *submenuGraffiti; //涂鸦子菜单
@property (nonatomic, strong) SLSubmenuStickingView *submenuSticking; //贴图子菜单
@property (nonatomic, strong) SLSubmenuMosaicView *submenuMosaic;  //图片马赛克
@property (nonatomic, strong) UIButton *doneBtn;//完成按钮
@property (nonatomic, strong) UILabel *tipLabel;

@end
@implementation SLEditMenuView
#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}
//不影响别的视图的手势
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if(view == self){
        return nil;
    }
    return view;
}
#pragma mark - UI
///设置back按钮是否可点
///设置前进后退按钮是否可点
- (void)enableBackBtn:(BOOL)enableBack forwardBtn:(BOOL)enableForward;
 {
    if(self.currentMenuType == SLEditMenuTypeGraffiti) {
        if(enableBack || enableForward){
            [self.submenuGraffiti showBackAndForwardBtn];
        }
        self.submenuGraffiti.backBtnEnable = enableBack;
        self.submenuGraffiti.forwardBtnEnable = enableForward;
    }
    if(self.currentMenuType == SLEditMenuTypePictureMosaic) {
        if(enableBack || enableForward){
            [self.submenuMosaic showBackAndForwardBtn];
        }
        self.submenuMosaic.backBtnEnable = enableBack;
        self.submenuMosaic.forwardBtnEnable = enableForward;
        return;
    }
}
///选中线条颜色
- (void)selectLineColor:(UIColor *)color {
    _submenuGraffiti.currentColor = color;
}

- (void)createGradientLayer {
    // Background Code
    CAGradientLayer *gl = [CAGradientLayer layer];
    gl.frame = self.bounds;
    gl.startPoint = CGPointMake(0.50, 0.00);
    gl.endPoint = CGPointMake(0.50, 1.73);
    gl.colors = @[
                  (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:0].CGColor,
                  (__bridge id)[[UIColor blackColor] colorWithAlphaComponent:1].CGColor,
                  ];
    gl.locations = @[@(0),@(1)];
    [self.layer addSublayer:gl];
}
- (void)createDoneBtn
{
    UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.backgroundColor = kColorWithHex(0xFE7B1A);
    [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    if(!self.doneBtnTitle.length){
        [doneBtn setTitle:kNSLocalizedString(@"完成") forState:UIControlStateNormal];
    }else {
        [doneBtn setTitle:self.doneBtnTitle forState:UIControlStateNormal];
    }
    doneBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    doneBtn.layer.cornerRadius = 3;
    doneBtn.clipsToBounds = YES;
    [doneBtn addTarget:self action:@selector(doneBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:doneBtn];
    doneBtn.frame =  CGRectMake(self.frame.size.width - 75, 70, 60, 30);
    self.doneBtn = doneBtn;
}
- (void)createTipLabel {
    CGFloat maxWidth = self.frame.size.width*156/414.f;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - maxWidth - 16, self.frame.size.height - kSafeAreaBottomHeight - 17 - 10, maxWidth, 17)];
    label.textAlignment = NSTextAlignmentRight;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:12];
    label.text = self.tipText;
    [self addSubview:label];
    self.tipLabel = label;
}
- (void)createEditMenus {
    for (UIView *subView in self.subviews) {
        if (subView == _submenuGraffiti || subView == _submenuSticking || subView == _submenuMosaic) {
            continue;
        }
        [subView removeFromSuperview];
    }
    int count = (int)_menuTypes.count;
    CGFloat w = (self.frame.size.width - 80 - 15*2)/count;
    CGSize itemSize = CGSizeMake(w, 24);
    CGFloat x = 15;
    _menuBtns = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        UIButton * menuBtn = [[UIButton alloc] initWithFrame:CGRectMake(x+w*i, 72, itemSize.width, itemSize.height)];
        menuBtn.tag = [_menuTypes[i] intValue];
        [menuBtn setImage:[UIImage imageNamed:_imageNames[i]] forState:UIControlStateNormal];
        [menuBtn setImage:[UIImage imageNamed:_imageNamesSelected[i]] forState:UIControlStateSelected];
        [menuBtn addTarget:self action:@selector(menuBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:menuBtn];
        [_menuBtns addObject:menuBtn];
    }
}

- (void)setEditObject:(SLEditObject)editObject {
    _editObject = editObject;
    if (editObject == SLEditObjectPicture) {
        _menuTypes = @[@(SLEditMenuTypeGraffiti),
                       @(SLEditMenuTypeText),
                       @(SLEditMenuTypePictureMosaic),
                       @(SLEditMenuTypePictureClipping)
                       ];
        _imageNames = @[@"EditMenuGraffiti", @"EditMenuText", @"EditMenuMosaic", @"EditMenuClipImage"];
        _imageNamesSelected = @[@"EditMenuGraffitiSelected", @"EditMenuText",@"EditMenuMosaicSelected",@"EditMenuClipImage"];
    }else if (editObject == SLEditObjectVideo) {
        _menuTypes = @[@(SLEditMenuTypeGraffiti), @(SLEditMenuTypeSticking), @(SLEditMenuTypeText), @(SLEditMenuTypeVideoClipping)
    ];
    _imageNames = @[@"EditMenuGraffiti", @"EditMenuSticker", @"EditMenuText", @"EditMenuCut"];
    _imageNamesSelected = @[@"EditMenuGraffitiSelected", @"EditMenuStickerSelected", @"EditMenuText", @"EditMenuCut"];
    }
    //添加渐变黑遮罩
    [self createGradientLayer];
    //添加菜单
    [self createEditMenus];
    //添加完成按钮
    [self createDoneBtn];
    //添加提示文字
    [self createTipLabel];
}
- (void)setTipText:(NSString *)tipText {
    _tipText = tipText;
    self.tipLabel.text = tipText;
}
- (void)setDoneBtnTitle:(NSString *)doneBtnTitle {
    _doneBtnTitle = doneBtnTitle;
    if(doneBtnTitle.length){
        [self.doneBtn setTitle:doneBtnTitle forState:UIControlStateNormal];
    }
}
#pragma mark - Getter
- (SLSubmenuGraffitiView *)submenuGraffiti {
    if (!_submenuGraffiti) {
        _submenuGraffiti = [[SLSubmenuGraffitiView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _submenuGraffiti.hidden = YES;
        _submenuGraffiti.backgroundColor = [UIColor whiteColor];
        __weak typeof(self) weakSelf = self;
        _submenuGraffiti.selectedLineColor = ^(UIColor *lineColor) {
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"lineColor":lineColor,@"erase":@(NO)});
        };
        _submenuGraffiti.selectEraseBlock = ^(BOOL isErase) {
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"erase":@(isErase)});
        };
        _submenuGraffiti.goBackBlock = ^{
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"goBack":@(YES)});
        };
        _submenuGraffiti.goForwardBlock  = ^{
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"goForward":@(YES)});
        };
        _submenuGraffiti.cancelBlock = ^{
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"goBackToLast":@(YES),@"hidden":@(YES)});
            [weakSelf hiddenView:weakSelf.submenuGraffiti];
        };
        _submenuGraffiti.doneBlock = ^{
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"hidden":@(YES)});
            [weakSelf hiddenView:weakSelf.submenuGraffiti];

        };
        _submenuGraffiti.brushShapeChangedBlock = ^(SLGraffitiShapeType shapeType) {
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"shape":[NSNumber numberWithInteger:shapeType]});

        };
        _submenuGraffiti.lineWidthChangedBlock = ^(CGFloat lineWidth, NSInteger lineWidthIndex) {
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"lineWidth":@(lineWidth),@"lineWidthIndex":@(lineWidthIndex)});
        };
    }
    return _submenuGraffiti;
}
- (SLSubmenuMosaicView *)submenuMosaic {
    if (!_submenuMosaic) {
        _submenuMosaic = [[SLSubmenuMosaicView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
        _submenuMosaic.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _submenuMosaic.selectEraseBlock = ^{
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"erase":@(YES)});
        };
        _submenuMosaic.lineWidthChangedBlock = ^(CGFloat lineWidth) {
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"lineWidth":@(lineWidth)});
        };
        _submenuMosaic.squareWidthChangedBlock = ^(CGFloat squareWidth) {
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"squareWidth":@(squareWidth),@"erase":@(NO)});
        };
        _submenuMosaic.selectEraseBlock = ^{
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"erase":@(YES)});
        };
        _submenuMosaic.goBackBlock = ^{
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"goBack":@(YES)});
        };
        _submenuMosaic.goForwardBlock  = ^{
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"goForward":@(YES)});
        };
        _submenuMosaic.cancelBlock = ^{
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"goBackToLast":@(YES),@"hidden":@(YES),@"erase":@(NO)});
            [weakSelf hiddenView:weakSelf.submenuMosaic];
        };
        _submenuMosaic.doneBlock = ^{
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"hidden":@(YES),@"erase":@(NO)});
            [weakSelf hiddenView:weakSelf.submenuMosaic];
            
        };
    }
    return _submenuMosaic;
}

- (SLSubmenuStickingView *)submenuSticking {
    if (!_submenuSticking) {
        _submenuSticking = [[SLSubmenuStickingView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
        _submenuSticking.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _submenuSticking.selectedImage = ^(SLImage *image) {
            weakSelf.selectEditMenu(SLEditMenuTypeSticking, @{@"image":image});
        };
    }
    return _submenuSticking;
}

#pragma mark - Evenst Handle
- (void)doneBtnClick:(UIButton *)btn {
    if(self.doneBtnClickBlock){
        self.doneBtnClickBlock();
    }
}
- (void)menuBtnClicked:(UIButton *)menuBtn {
    SLEditMenuType editMenuType = menuBtn.tag;
    self.currentMenuType = editMenuType;
    switch (editMenuType) {
        case SLEditMenuTypeGraffiti:
            [self hiddenView:self.submenuGraffiti];
            if(!self.submenuGraffiti.hidden){
                self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuGraffiti.hidden),@"lineWidth":@(self.submenuGraffiti.currentLineWidth),@"shape":@(self.submenuGraffiti.currentShapeType),@"lineColor":self.submenuGraffiti.currentColor,@"erase":@(self.submenuGraffiti.isErase)});
            }else {
                self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuGraffiti.hidden)});
            }
            break;
        case SLEditMenuTypeSticking:
            [self hiddenView:self.submenuSticking];
            self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuSticking.hidden)});
            break;
        case SLEditMenuTypeText:
            [self hiddenView:self.currentSubmenu hidden:YES];
            self.selectEditMenu(editMenuType, @{@"hidden":@(NO)});
            break;
        case SLEditMenuTypeVideoClipping:
            [self hiddenView:self.currentSubmenu hidden:YES];
            self.selectEditMenu(editMenuType, nil);
            break;
        case SLEditMenuTypePictureMosaic:
            [self hiddenView:self.submenuMosaic];
            if(!self.submenuMosaic.hidden){
                self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuMosaic.hidden),@"lineWidth":@(self.submenuMosaic.currentLineWidth),@"squareWidth":@(self.submenuMosaic.squareWidth),@"shape":[NSNumber numberWithInteger:4]});
                [self.submenuMosaic showUp];
            }else {
                self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuMosaic.hidden)});
            }
            break;
        case SLEditMenuTypePictureClipping:
            [self hiddenView:self.currentSubmenu hidden:YES];
            self.selectEditMenu(editMenuType, @{@"hidden":@(NO)});
            break;
        default:
            break;
    }
}
#pragma mark - Help Methods
- (void)hiddenView:(UIView *)view {
    [self hiddenView:view hidden:!view.hidden];
}
- (void)hiddenView:(UIView *)view hidden:(BOOL)hidden{
    if(view == nil || view.hidden == hidden) return;
    if (hidden) {
        self.hideSubMenuBlock(self.currentMenuType);
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
            
        }];
    }
}

@end


