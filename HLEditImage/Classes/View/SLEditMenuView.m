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
#import "SLEditImage.h"
/// 涂鸦子菜单 画笔颜色选择
@interface SLSubmenuGraffitiView : UIView
@property (nonatomic, assign) int currentColorIndex; // 当前画笔颜色索引
@property (nonatomic, strong) UIColor *currentColor; // 当前画笔颜色
@property (nonatomic, copy) void(^selectedLineColor)(UIColor *lineColor); //选中颜色的回调
@property (nonatomic, copy) void(^goBack)(void); //返回上一步
@property (nonatomic, strong) UIButton *backBtn; //返回按钮
@property (nonatomic, assign) BOOL backBtnEnable;

@end
@implementation  SLSubmenuGraffitiView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentColorIndex = 0;
        _currentColor = [UIColor whiteColor];
        _backBtnEnable = YES;
    }
    return self;
}
- (void)setBackBtnEnable:(BOOL)backBtnEnable {
    _backBtnEnable = backBtnEnable;
    _backBtn.enabled = backBtnEnable;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        _currentColorIndex = 0;
        _currentColor = [UIColor whiteColor];
        _backBtnEnable = YES;
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self createSubmenu];
}
- (void)createSubmenu {
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
        
    NSArray *colors = @[kColorWithHex(0xF2F2F2), kColorWithHex(0x2B2B2B), kColorWithHex(0xFA5051), kColorWithHex(0xFFC300), kColorWithHex(0x04C160), kColorWithHex(0x11AEFF), kColorWithHex(0x6467F0), [UIColor clearColor]];
    int count = (int)colors.count;
    CGSize itemSize = CGSizeMake(24, 24);
    CGFloat space = (self.frame.size.width - count * itemSize.width)/(count + 1);
    for (int i = 0; i < count; i++) {
        UIButton * colorBtn = [[UIButton alloc] initWithFrame:CGRectMake(space + (itemSize.width + space)*i, (self.frame.size.height - itemSize.height)/2.0, itemSize.width, itemSize.height)];
        colorBtn.backgroundColor = colors[i];
        colorBtn.tag = 10 + i;
        [self addSubview:colorBtn];
        if (i == count - 1) {
            [colorBtn addTarget:self action:@selector(backToPreviousStep:) forControlEvents:UIControlEventTouchUpInside];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuGraffitiBack"] forState:UIControlStateNormal];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuGraffitiBackDisable"] forState:UIControlStateDisabled];
            self.backBtn = colorBtn;
            self.backBtn.enabled = self.backBtnEnable;
        }else {
            [colorBtn addTarget:self action:@selector(colorBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            colorBtn.layer.cornerRadius = itemSize.width/2.0;
            colorBtn.layer.borderColor = [UIColor whiteColor].CGColor;
            colorBtn.layer.borderWidth = 3;
            if (i != _currentColorIndex) {
                colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
                colorBtn.layer.borderWidth = 2;
            }else {
                colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 1.0f);
                colorBtn.layer.borderWidth = 3;
                _currentColor = colors[i];
                self.selectedLineColor(colors[i]);
            }
        }
    }
}
// 选中当前画笔颜色
- (void)colorBtnClicked:(UIButton *)colorBtn {
    UIButton *previousBtn = (UIButton *)[self viewWithTag:(10 + _currentColorIndex)];
    previousBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
    previousBtn.layer.borderWidth = 2;
    colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    colorBtn.layer.borderWidth = 3;
    _currentColorIndex = (int)colorBtn.tag- 10;
    _currentColor = colorBtn.backgroundColor;
    self.selectedLineColor(colorBtn.backgroundColor);
}
//返回上一步
- (void)backToPreviousStep:(id)sender {
    self.goBack();
}
@end

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

/// 图片马赛克 子菜单  马赛克类型选择
@interface SLSubmenuMosaicView : UIView
@property (nonatomic, assign) NSInteger currentTypeIndex; //当前马赛克类型索引 默认0
@property (nonatomic, copy) void(^goBack)(void); //返回上一步
@property (nonatomic, copy) void(^selectedMosaicType)(NSInteger currentTypeIndex); // 选择马赛克类型 0：小方块 1：毛笔涂抹
@property (nonatomic, strong) UIButton *backBtn; //返回按钮
@property (nonatomic, assign) BOOL backBtnEnable;

@end
@implementation SLSubmenuMosaicView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backBtnEnable = YES;
    }
    return self;
}
- (instancetype)init {
    self = [super init];
    if (self) {
        self.backBtnEnable = YES;
    }
    return self;
}
- (void)setBackBtnEnable:(BOOL)backBtnEnable {
    _backBtnEnable = backBtnEnable;
    _backBtn.enabled = backBtnEnable;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    [self createSubmenu];
}
- (void)createSubmenu {
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
    NSArray *imageNames = @[@"EditTraditionalMosaic", @"EditBrushMosaic", @"EditMenuGraffitiBack"];
    NSArray *imageNamesSelected = @[@"EditTraditionalMosaicSelected", @"EditBrushMosaicSelected", @"EditMenuGraffitiBack"];
    int count = (int)imageNames.count;
    CGSize itemSize = CGSizeMake(18, 18);
    CGFloat x = 40;
    CGFloat space = (self.frame.size.width  - x- count * itemSize.width)/(count + 1);
    for (int i = 0; i < count; i++) {
        UIButton * colorBtn = [[UIButton alloc] initWithFrame:CGRectMake(x+space + (itemSize.width + space)*i, (self.frame.size.height - itemSize.height)/2.0, itemSize.width, itemSize.height)];
        colorBtn.tag = 10 + i;
        [self addSubview:colorBtn];
        if (i == count - 1) {
            colorBtn.frame = CGRectMake(self.frame.size.width - 54, 18, 26, 20);
            [colorBtn addTarget:self action:@selector(backToPreviousStep:) forControlEvents:UIControlEventTouchUpInside];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuGraffitiBack"] forState:UIControlStateNormal];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuGraffitiBackDisable"] forState:UIControlStateDisabled];
            self.backBtn = colorBtn;
            self.backBtn.enabled = self.backBtnEnable;
        }else {
            [colorBtn addTarget:self action:@selector(mosaicTypeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        }
        if(i == _currentTypeIndex) {
            colorBtn.selected = YES;
        }
        [colorBtn setImage:[UIImage imageNamed:imageNames[i]] forState:UIControlStateNormal];
        [colorBtn setImage:[UIImage imageNamed:imageNamesSelected[i]] forState:UIControlStateSelected];
    }
}
- (void)backToPreviousStep:(id)sender {
    self.goBack();
}
//马赛克类型
- (void)mosaicTypeBtnClicked:(UIButton *)btn {
    btn.selected = !btn.selected;
    UIButton *currentView = [self viewWithTag:(_currentTypeIndex + 10)];
    currentView.selected = !currentView.selected;
    _currentTypeIndex = btn.tag - 10;
    self.selectedMosaicType(_currentTypeIndex);
}
@end

/// 编辑主菜单
@interface SLEditMenuView ()
@property (nonatomic, strong) NSArray *menuTypes; //编辑类型集合
@property (nonatomic, strong) NSArray *imageNames; //编辑图标名称
@property (nonatomic, strong) NSArray *imageNamesSelected; //选中的 编辑图标名称
@property (nonatomic, strong) NSMutableArray *menuBtns; //编辑菜单按钮集合

@property (nonatomic, strong) UIView *currentSubmenu; //当前显示的子菜单
@property (nonatomic, strong) SLSubmenuGraffitiView *submenuGraffiti; //涂鸦子菜单
@property (nonatomic, strong) SLSubmenuStickingView *submenuSticking; //贴图子菜单
@property (nonatomic, strong) SLSubmenuMosaicView *submenuMosaic;  //图片马赛克
@property (nonatomic, strong) UIButton *doneBtn;//完成按钮
@property (nonatomic, assign) SLEditMenuType currentMenuType; //当前编辑类型

@end
@implementation SLEditMenuView
#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}
#pragma mark - UI
///设置back按钮是否可点
- (void)enableBackBtn:(BOOL)enable {
    if(self.currentMenuType == SLEditMenuTypeGraffiti) {
        self.submenuGraffiti.backBtnEnable = enable;
        return;
    }
    if(self.currentMenuType == SLEditMenuTypePictureMosaic) {
        self.submenuMosaic.backBtnEnable = enable;
        return;
    }
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
    [doneBtn setTitle:NSLocalizedString(@"完成", @"") forState:UIControlStateNormal];
    doneBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    doneBtn.layer.cornerRadius = 3;
    doneBtn.clipsToBounds = YES;
    [doneBtn addTarget:self action:@selector(doneBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:doneBtn];
    doneBtn.frame =  CGRectMake(self.frame.size.width - 75, 70, 60, 30);
    self.doneBtn = doneBtn;
}
- (void)createEditMenus {
    for (UIView *subView in self.subviews) {
        if (subView == _submenuGraffiti || subView == _submenuSticking || subView == _submenuMosaic) {
            continue;
        }
        [subView removeFromSuperview];
    }
    int count = (int)_menuTypes.count;
    CGSize itemSize = CGSizeMake(23, 23);
    CGFloat x = 15;
    CGFloat space = (self.frame.size.width - 80 - count * itemSize.width - x)/count;
    _menuBtns = [NSMutableArray array];
    for (int i = 0; i < count; i++) {
        UIButton * menuBtn = [[UIButton alloc] initWithFrame:CGRectMake(x+space/2.0 + (itemSize.width + space)*i, 72, itemSize.width, itemSize.height)];
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
    [self createGradientLayer];
    [self createEditMenus];
    [self createDoneBtn];
}
#pragma mark - Getter
- (SLSubmenuGraffitiView *)submenuGraffiti {
    if (!_submenuGraffiti) {
        _submenuGraffiti = [[SLSubmenuGraffitiView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
        _submenuGraffiti.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _submenuGraffiti.selectedLineColor = ^(UIColor *lineColor) {
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"lineColor":lineColor});
        };
        _submenuGraffiti.goBack = ^{
            weakSelf.selectEditMenu(SLEditMenuTypeGraffiti, @{@"goBack":@(YES)});
        };
    }
    return _submenuGraffiti;
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
- (SLSubmenuMosaicView *)submenuMosaic {
    if (!_submenuMosaic) {
        _submenuMosaic = [[SLSubmenuMosaicView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 60)];
        _submenuMosaic.hidden = YES;
        __weak typeof(self) weakSelf = self;
        _submenuMosaic.selectedMosaicType = ^(NSInteger currentTypeIndex) {
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"mosaicType":@(currentTypeIndex)});
        };
        _submenuMosaic.goBack = ^{
            weakSelf.selectEditMenu(SLEditMenuTypePictureMosaic, @{@"goBack":@(YES)});
        };
    }
    return _submenuMosaic;
}
#pragma mark - Evenst Handle
- (void)doneBtnClick:(UIButton *)btn {
    if(self.doneBtnClickBlock){
        self.doneBtnClickBlock();
    }
}
- (void)menuBtnClicked:(UIButton *)menuBtn {
    for (UIButton *subView in self.menuBtns) {
        if (subView == menuBtn) {
            subView.selected = !subView.selected;
        } else {
            subView.selected = NO;
        }
    }
    SLEditMenuType editMenuType = menuBtn.tag;
    self.currentMenuType = editMenuType;
    switch (editMenuType) {
        case SLEditMenuTypeGraffiti:
            [self hiddenView:self.submenuGraffiti];
            self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuGraffiti.hidden), @"lineColor": self.submenuGraffiti.currentColor});
            break;
        case SLEditMenuTypeSticking:
            [self hiddenView:self.submenuSticking];
            self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuSticking.hidden)});
            break;
        case SLEditMenuTypeText:
            [self hiddenView:self.currentSubmenu hidden:YES];
            self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuSticking.hidden)});
            break;
        case SLEditMenuTypeVideoClipping:
            [self hiddenView:self.currentSubmenu hidden:YES];
            self.selectEditMenu(editMenuType, nil);
            break;
        case SLEditMenuTypePictureMosaic:
            [self hiddenView:self.submenuMosaic];
            self.selectEditMenu(editMenuType, @{@"hidden":@(self.submenuMosaic.hidden), @"mosaicType":@(self.submenuMosaic.currentTypeIndex)});
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
    if (self.currentSubmenu == view || self.currentSubmenu == nil) {
        [self hiddenView:view hidden:!view.hidden];
    }else {
        [self hiddenView:self.currentSubmenu hidden:YES];
        [self hiddenView:view hidden:NO];
    }
}
- (void)hiddenView:(UIView *)view hidden:(BOOL)hidden{
    if(view == nil || view.hidden == hidden) return;
    if (hidden) {
        view.hidden = YES;
        [view removeFromSuperview];
    }else {
        view.hidden = NO;
        self.currentSubmenu = view;
        [self addSubview:view];
    }
}
@end


