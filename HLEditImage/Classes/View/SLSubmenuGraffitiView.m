//
//  SLSubmenuGraffitiView.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/8.
//  Copyright © 2020 alin. All rights reserved.
//

#import "SLSubmenuGraffitiView.h"
#import "SLUtilsMacro.h"
#import "UIButton+SLButton.h"
#import "NSString+SLLocalizable.h"
#import "UIImage+SLCommon.h"

@interface SLSubmenuGraffitiView ()
@property (nonatomic, strong) UIView *menuContainerView;

@property (nonatomic, strong) UIScrollView *colorsContainerView;//颜色按钮滚动容器
@property (nonatomic, strong) UIView *footerView;//底部操作栏
@property (nonatomic, strong) UIView *selectedColorCircleView;//选中颜色的圈圈
@property (nonatomic, strong) UILabel *titleLabel;//下标题
@property (nonatomic, strong) UIButton *backBtn;//撤销按钮
@property (nonatomic, strong) UIButton *forwardBtn;//前进按钮
@property (nonatomic, strong) UIButton *eraserBtn;//橡皮檫按钮


@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) int currentColorIndex; // 当前画笔颜色索引

@end
@implementation  SLSubmenuGraffitiView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _currentColorIndex = 0;
        _currentColor = [UIColor whiteColor];
        _backBtnEnable = YES;
        [self setupUI];
    }
    return self;
}
#pragma mark - UI
- (void)setupUI {
    [self addSubview:self.menuContainerView];
    [self addSubview:self.footerView];
}
- (void)createSubmenu {
    NSArray *imageNames = @[@"EditMenuEraser",@"EditMenuShape",@"EditBrushSize1"];
    NSArray *imageNamesSelected = @[@"EditMenuEraserSelected",@"EditMenuShapeSelected",@"EditBrushSize1Selected"];
    NSArray *imageNamesDisable = @[@"EditMenuEraserDisable",@"",@""];
    NSArray *titles = @[kNSLocalizedString(@"擦除"),kNSLocalizedString(@"形状"),kNSLocalizedString(@"大小")];
    int count = (int)imageNames.count;
    CGSize itemSize = CGSizeMake(48, 51);
    CGFloat x = 5;
    for (int i = 0; i < count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.menuContainerView addSubview:btn];
        btn.tag = 100 + i;
        btn.frame = CGRectMake(x+i*itemSize.width, (self.menuContainerView.frame.size.height - itemSize.height)/2, itemSize.width, itemSize.height);
        [btn setImage:[UIImage imageNamed:imageNames[i]] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:imageNamesSelected[i]] forState:UIControlStateSelected];
        if([imageNamesDisable[i] length]){
            [btn setImage:[UIImage imageNamed:imageNamesDisable[i]] forState:UIControlStateDisabled];
        }
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:10]];
        [btn setTitleColor:kColorWithHex(0x666666) forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(menuBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(28, 28) space:9];
        if(i == 0) {
            self.eraserBtn = btn;
        }
    }
    //分割线
    UIView * lineView = [[UIView alloc] initWithFrame:CGRectMake(159, (self.menuContainerView.frame.size.height - 18)/2, 0.7, 18)];
    lineView.backgroundColor = kColorWithHex(0xd8d8d8);
    [self.menuContainerView addSubview:lineView];
}
- (void)createBrushColorMenu {
    _colorsContainerView = [[UIScrollView alloc] initWithFrame:CGRectMake(170, 0, self.frame.size.width - 170, 60)];
    _colorsContainerView.alwaysBounceHorizontal = YES;
    _colorsContainerView.showsVerticalScrollIndicator = NO;
    _colorsContainerView.showsHorizontalScrollIndicator = NO;
    [self.menuContainerView addSubview:_colorsContainerView];
    NSArray *colors = @[kColorWithHex(0xF2F2F2), kColorWithHex(0x2B2B2B), kColorWithHex(0xFA5051), kColorWithHex(0xFFC300), kColorWithHex(0x04C160), kColorWithHex(0x11AEFF)];
    self.colors = colors;
    NSArray *titles = @[kNSLocalizedString(@"浅灰"),kNSLocalizedString(@"黑色"),kNSLocalizedString(@"红色"),kNSLocalizedString(@"黄色"),kNSLocalizedString(@"绿色"),kNSLocalizedString(@"蓝色")];
    int count = (int)colors.count;
    CGSize itemSize = CGSizeMake(48, 51);
    CGFloat x = 10;
    for (int i = 0; i < count; i++) {
        UIButton * colorBtn = [[UIButton alloc] initWithFrame:CGRectMake(x+i*itemSize.width, (self.colorsContainerView.frame.size.height - itemSize.height)/2, itemSize.width, itemSize.height)];
        [self.colorsContainerView addSubview:colorBtn];
        colorBtn.tag = 10 + i;
        UIImage * image = [UIImage sl_imageWithColor:colors[i] size:CGSizeMake(18, 18)];
        UIImage *selectedImage = [UIImage sl_imageWithColor:colors[i] size:CGSizeMake(24, 24)];
        [colorBtn setImage:image forState:UIControlStateNormal];
        [colorBtn setImage:selectedImage forState:UIControlStateSelected];
        [colorBtn setTitle:titles[i] forState:UIControlStateNormal];
        [colorBtn.titleLabel setFont:[UIFont systemFontOfSize:10]];
        [colorBtn setTitleColor:kColorWithHex(0x666666) forState:UIControlStateNormal];
        [colorBtn addTarget:self action:@selector(colorBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [colorBtn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(28, 28) space:9];

        if (i != _currentColorIndex) {
            colorBtn.imageView.layer.cornerRadius = 9;
        }else {
                [self colorBtnClicked:colorBtn];
        }
    }
    _colorsContainerView.contentSize = CGSizeMake(itemSize.width*count+20, 60);

}
- (void)createFooterItems {
    //关闭按钮
    UIButton * closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(0, 0, 54, self.footerView.frame.size.height);
    [closeBtn setImage:[UIImage imageNamed:@"EditMenuClose"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:closeBtn];
    //完成按钮
    UIButton * doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame = CGRectMake(self.footerView.frame.size.width - 58, 0, 58, self.footerView.frame.size.height);
    [doneBtn setImage:[UIImage imageNamed:@"EditMenuDone"] forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(doneBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:doneBtn];

    //title
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.textColor = kColorWithHex(0x333333);
    titleLabel.text = kNSLocalizedString(@"涂鸦");
    [titleLabel sizeToFit];
    titleLabel.center = CGPointMake(self.footerView.frame.size.width/2, self.footerView.frame.size.height/2);
    [self.footerView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    //后退按钮
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(self.footerView.frame.size.width/2 - 40 -12, 0, 40, self.footerView.frame.size.height);
    [backBtn setImage:[UIImage imageNamed:@"EditMenuBack"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"EditMenuBackDisable"] forState:UIControlStateDisabled];
    [backBtn addTarget:self action:@selector(backBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:backBtn];
    self.backBtn = backBtn;
    self.backBtn.hidden = YES;

    //前进按钮
    UIButton *forwardBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    forwardBtn.frame = CGRectMake(self.footerView.frame.size.width/2 + 12, 0, 40, self.footerView.frame.size.height);
    [forwardBtn setImage:[UIImage imageNamed:@"EditMenuNext"] forState:UIControlStateNormal];
    [forwardBtn setImage:[UIImage imageNamed:@"EditMenuNextDisable"] forState:UIControlStateDisabled];
    [forwardBtn addTarget:self action:@selector(forwardBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.footerView addSubview:forwardBtn];
    self.forwardBtn = forwardBtn;
    self.forwardBtn.hidden = YES;
}

#pragma mark - Help Method
- (void)showBackAndForwardBtn {
    self.backBtn.hidden = NO;
    self.forwardBtn.hidden = NO;
    self.titleLabel.hidden = YES;
}

#pragma mark - Events Handle
- (void)closeBtnClicked:(UIButton *)btn {
    
}
- (void)doneBtnClicked:(UIButton *)btn {
    
}
- (void)menuBtnClicked:(UIButton *)btn {
    NSInteger index = btn.tag - 100;
    if(index == 0){
        if(btn.selected){
            return;
        }
        //橡皮檫
        //取消选中之前的颜色按钮
        UIButton *previousBtn = (UIButton *)[self viewWithTag:(10 + _currentColorIndex)];
        previousBtn.selected = NO;
        previousBtn.imageView.layer.cornerRadius = 9;
        [previousBtn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(28, 28) space:9];
        [self.selectedColorCircleView removeFromSuperview];
        //选中橡皮檫按钮
        btn.selected = YES;
        if(self.selectEraseBlock){
            self.selectEraseBlock();
        }
    }else if (index == 1){
        //形状
        
    }
    
}
// 选中当前画笔颜色
- (void)colorBtnClicked:(UIButton *)colorBtn {
    //取消选中橡皮檫按钮
    self.eraserBtn.selected = NO;
    if(colorBtn.isSelected){
        return;
    }
    //前一个选中的按钮
    UIButton *previousBtn = (UIButton *)[self viewWithTag:(10 + _currentColorIndex)];
    previousBtn.selected = NO;
    previousBtn.imageView.layer.cornerRadius = 9;
    [previousBtn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(28, 28) space:9];

    //当前选中的按钮
    colorBtn.selected = YES;
    colorBtn.imageView.layer.cornerRadius = 12;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [colorBtn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(28, 28) space:9];
    });
    _currentColorIndex = (int)colorBtn.tag - 10;
    _currentColor = self.colors[_currentColorIndex];
    [self.selectedColorCircleView removeFromSuperview];
    self.selectedColorCircleView.layer.borderColor = _currentColor.CGColor;
    [colorBtn insertSubview:self.selectedColorCircleView belowSubview:colorBtn.imageView];
    self.selectedColorCircleView.center = colorBtn.imageView.center;
    if(self.selectedLineColor){
        self.selectedLineColor(_currentColor);
    }
}
//返回上一步
- (void)backBtnClicked:(id)sender {
    if(self.goBackBlock){
        self.goBackBlock();
    }
}
- (void)forwardBtnClicked:(UIButton *)btn {
    if(self.goForwardBlock){
        self.goForwardBlock();
    }
}
#pragma mark - setter
- (void)setBackBtnEnable:(BOOL)backBtnEnable {
    _backBtnEnable = backBtnEnable;
    self.backBtn.enabled = backBtnEnable;
}


#pragma mark- getter
- (UIView *)menuContainerView {
    if(!_menuContainerView) {
        _menuContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 25, self.frame.size.width, 60)];
        //添加菜单
        [self createSubmenu];
        //添加颜色选择菜单
        [self createBrushColorMenu];
    }
    return _menuContainerView;
}
- (UIView *)footerView {
    if(!_footerView) {
        _footerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 60, self.frame.size.width, 60)];
        [self createFooterItems];
    }
    return _footerView;
}
- (UIView *)selectedColorCircleView {
    if(!_selectedColorCircleView){
        _selectedColorCircleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
        _selectedColorCircleView.layer.borderWidth = 1;
        _selectedColorCircleView.layer.cornerRadius = 14;
        _selectedColorCircleView.clipsToBounds = YES;
    }
    return _selectedColorCircleView;
}
@end
