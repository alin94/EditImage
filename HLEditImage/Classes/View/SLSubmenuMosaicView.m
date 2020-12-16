//
//  SLSubmenuMosaicView.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/14.
//  Copyright © 2020 alin. All rights reserved.
//

#import "SLSubmenuMosaicView.h"
#import "SLUtilsMacro.h"
#import "UIButton+SLButton.h"
#import "NSString+SLLocalizable.h"
#import "SLSubmenuLineWidthView.h"


@interface SLSubmenuMosaicView ()



@property (nonatomic, strong) SLSubmenuLineWidthView *lineWidthView;//线条宽度菜单
@property (nonatomic, strong) UIView *topContainerView;

@property (nonatomic, strong) UILabel *titleLabel;//下标题
@property (nonatomic, strong) UIButton *backBtn;//撤销按钮
@property (nonatomic, strong) UIButton *forwardBtn;//前进按钮
@property (nonatomic, strong) UIButton *eraserBtn;//橡皮檫按钮
@property (nonatomic, strong) UIButton *lineWidthBtn;//大小按钮
@property (nonatomic, assign) NSInteger currentSelectIndex;


@end

@implementation SLSubmenuMosaicView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _squareWidth = 8;
        _currentLineWidth = 4*_squareWidth;
        _currentSelectIndex = 2;
        self.backgroundColor = [UIColor whiteColor];
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    UIView *topContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 25, self.frame.size.width, 60)];
    [self addSubview:topContainer];
    [self createSubMenusOnView:topContainer];
    self.topContainerView = topContainer;
    UIView *footerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 60, self.frame.size.width, 60)];
    [self addSubview:footerContainer];
    [self createFooterMenusOnView:footerContainer];

}
- (void)createSubMenusOnView:(UIView *)view {
    NSArray *imageNames = @[@"EditMenuEraser",@"EditBrushSize3",@"EditTraditionalMosaic",@"EditBrushMosaic"];
    NSArray *imageNamesSelected = @[@"EditMenuEraserSelected",@"EditBrushSize3Selected",@"EditTraditionalMosaicSelected",@"EditBrushMosaicSelected"];
    NSArray *imageNamesDisable = @[@"EditMenuEraserDisable",@"",@"",@""];
    NSArray *titles = @[kNSLocalizedString(@"擦除"),kNSLocalizedString(@"大小"),kNSLocalizedString(@"粗粒度"),kNSLocalizedString(@"细粒度")];
    int count = (int)imageNames.count;
    CGSize itemSize = CGSizeMake(48, 51);
    CGFloat space = (self.frame.size.width - itemSize.width*count)/(count+1);
    for (int i = 0; i < count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [view addSubview:btn];
        btn.tag = 10 + i;
        btn.frame = CGRectMake(space+i*(itemSize.width + space), (view.frame.size.height - itemSize.height)/2, itemSize.width, itemSize.height);
        [btn setImage:[UIImage imageNamed:imageNames[i]] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:imageNamesSelected[i]] forState:UIControlStateSelected];
        if([imageNamesDisable[i] length]){
            [btn setImage:[UIImage imageNamed:imageNamesDisable[i]] forState:UIControlStateDisabled];
        }
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:10]];
        [btn setTitleColor:kColorWithHex(0x666666) forState:UIControlStateNormal];
        [btn setTitleColor:kColorWithHex(0xFE7B1A) forState:UIControlStateSelected];
        [btn addTarget:self action:@selector(menuBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(28, 28) space:9];
        if(i == 0) {
            self.eraserBtn = btn;
            self.eraserBtn.enabled = NO;
        }else if (i == 1){
            self.lineWidthBtn = btn;
        }
        if (i == self.currentSelectIndex){
            btn.selected = YES;
        }
    }
}
- (void)createFooterMenusOnView:(UIView *)view {
    //关闭按钮
    UIButton * closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(0, 0, 54, view.frame.size.height);
    [closeBtn setImage:[UIImage imageNamed:@"EditMenuClose"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:closeBtn];
    //完成按钮
    UIButton * doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    doneBtn.frame = CGRectMake(view.frame.size.width - 58, 0, 58, view.frame.size.height);
    [doneBtn setImage:[UIImage imageNamed:@"EditMenuDone"] forState:UIControlStateNormal];
    [doneBtn addTarget:self action:@selector(doneBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:doneBtn];
    
    //title
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.textColor = kColorWithHex(0x333333);
    titleLabel.text = kNSLocalizedString(@"马赛克");
    [titleLabel sizeToFit];
    titleLabel.center = CGPointMake(view.frame.size.width/2, view.frame.size.height/2);
    [view addSubview:titleLabel];
    self.titleLabel = titleLabel;
    //后退按钮
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(view.frame.size.width/2 - 40 -12, 0, 40, view.frame.size.height);
    [backBtn setImage:[UIImage imageNamed:@"EditMenuBack"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"EditMenuBackDisable"] forState:UIControlStateDisabled];
    [backBtn addTarget:self action:@selector(backBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:backBtn];
    self.backBtn = backBtn;
    self.backBtn.hidden = YES;
    self.backBtn.enabled = NO;
    
    //前进按钮
    UIButton *forwardBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    forwardBtn.frame = CGRectMake(view.frame.size.width/2 + 12, 0, 40, view.frame.size.height);
    [forwardBtn setImage:[UIImage imageNamed:@"EditMenuNext"] forState:UIControlStateNormal];
    [forwardBtn setImage:[UIImage imageNamed:@"EditMenuNextDisable"] forState:UIControlStateDisabled];
    [forwardBtn addTarget:self action:@selector(forwardBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:forwardBtn];
    self.forwardBtn = forwardBtn;
    self.forwardBtn.hidden = YES;
    self.forwardBtn.enabled = NO;

}
#pragma mark - Help Method
- (void)showBackAndForwardBtn {
    self.backBtn.hidden = NO;
    self.forwardBtn.hidden = NO;
    self.titleLabel.hidden = YES;
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
            
        }];
    }
}


#pragma mark - Events Handle
- (void)menuBtnClicked:(UIButton *)btn {
    NSInteger index = btn.tag - 10;
    if(index == 1){
        [self hiddenView:self.lineWidthView];
    }else {
        if(self.currentSelectIndex == index){
            return;
        }
        UIButton *preBtn = [self.topContainerView viewWithTag:self.currentSelectIndex+10];
        preBtn.selected = NO;
        self.currentSelectIndex = index;
        btn.selected = YES;
        if(index == 0){
            if(self.selectEraseBlock){
                self.selectEraseBlock();
            }
        }else if (index == 2 || index == 3){
            if(index == 2){
                self.squareWidth = 8;
            }else{
                self.squareWidth = 4;
            }
            if(self.squareWidthChangedBlock){
                self.squareWidthChangedBlock(self.squareWidth);
            }
            NSArray *lineWidths = @[@(1),@(2),@(3),@(5),@(6)];
            if(self.lineWidthChangedBlock){
                self.lineWidthChangedBlock([lineWidths[self.lineWidthView.currentSelectIndex] intValue]*self.squareWidth);
            }
        }
            
    }
}
- (void)closeBtnClicked:(UIButton *)btn {
    if(self.cancelBlock){
        self.cancelBlock();
    }
}
- (void)doneBtnClicked:(UIButton *)btn {
    if(self.doneBlock){
        self.doneBlock();
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
    self.eraserBtn.enabled = backBtnEnable;
}
- (void)setForwardBtnEnable:(BOOL)forwardBtnEnable {
    _forwardBtnEnable = forwardBtnEnable;
    self.forwardBtn.enabled = forwardBtnEnable;
}

#pragma mark- getter

- (SLSubmenuLineWidthView *)lineWidthView {
    if(!_lineWidthView) {
        _lineWidthView = [[SLSubmenuLineWidthView alloc] initWithFrame:self.bounds];
        _lineWidthView.hidden = YES;
        WS(weakSelf);
        __block NSArray *lineWidths = @[@(1),@(2),@(3),@(5),@(6)];
        _lineWidthView.selectItemBlock = ^(NSInteger selectIndex, UIImage * _Nonnull selectIconImage) {
            CGFloat selectlineWidth = [lineWidths[selectIndex] floatValue]*weakSelf.squareWidth;
            if(weakSelf.currentLineWidth != selectlineWidth){
                weakSelf.currentLineWidth = selectlineWidth;
                if(weakSelf.lineWidthChangedBlock){
                    weakSelf.lineWidthChangedBlock(selectlineWidth);
                }
                [weakSelf.lineWidthBtn setImage:selectIconImage forState:UIControlStateNormal];
            }
            
        };
        _lineWidthView.closeBlock = ^{
            [weakSelf hiddenView:weakSelf.lineWidthView];
        };
    }
    return _lineWidthView;
}
- (BOOL)isErase {
    return self.eraserBtn.isSelected;
}


@end
