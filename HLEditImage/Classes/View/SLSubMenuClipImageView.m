//
//  SLSubMenuClipImageView.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/15.
//  Copyright © 2020 alin. All rights reserved.
//

#import "SLSubMenuClipImageView.h"
#import "SLUtilsMacro.h"
#import "UIButton+SLButton.h"
#import "NSString+SLLocalizable.h"

@interface SLSubMenuClipImageView ()
@property (nonatomic, strong) UIScrollView *scaleContainerView;
@property (nonatomic, strong) UIButton *recoverBtn;//撤销按钮
@property (nonatomic, strong) UIButton *rotateBtn;//旋转按钮

@end

@implementation SLSubMenuClipImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _currentSelectIndex = 1;
        self.backgroundColor = [UIColor whiteColor];
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
   
    UIView *topContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 25, self.frame.size.width, 60)];
    [self addSubview:topContainer];
    //旋转按钮
    UIButton * rotateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rotateBtn.frame = CGRectMake(0, 0, 60, 60);
    [rotateBtn setTitle:kNSLocalizedString(@"旋转") forState:UIControlStateNormal];
    [rotateBtn.titleLabel setFont:[UIFont systemFontOfSize:10]];
    [rotateBtn setTitleColor:kColorWithHex(0x666666) forState:UIControlStateNormal];
    [rotateBtn setImage:[UIImage imageNamed:@"EditMenuRotate"] forState:UIControlStateNormal];
    [rotateBtn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(27, 27) space:7];
    [rotateBtn addTarget:self action:@selector(rotateBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [topContainer addSubview:rotateBtn];
    
    //分割线
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(60, (60-18)/2, 1, 18)];
    lineView.backgroundColor = kColorWithHex(0xD8D8D8);
    [topContainer addSubview:lineView];
    //比例菜单
    UIScrollView *scaleContainerView = [[UIScrollView alloc] initWithFrame:CGRectMake(60+10+1, 0, self.frame.size.width - (60+10+1), topContainer.frame.size.height)];
    scaleContainerView.alwaysBounceHorizontal = YES;
    scaleContainerView.showsVerticalScrollIndicator = NO;
    scaleContainerView.showsHorizontalScrollIndicator = NO;
    [topContainer addSubview:scaleContainerView];
    self.scaleContainerView = scaleContainerView;
    [self createSubMenusOnView:scaleContainerView];
    //底部操作栏
    UIView *footerContainer = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 60, self.frame.size.width, 60)];
    [self addSubview:footerContainer];
    [self createFooterMenusOnView:footerContainer];
    
}
- (void)createSubMenusOnView:(UIView *)view {
    NSArray *imageNames = @[@"EditMenuClipScale_1:1",@"EditMenuClipScaleRam",@"EditMenuClipScale_1:1",@"EditMenuClipScale_3:4",@"EditMenuClipScale_4:3",@"EditMenuClipScale_9:16",@"EditMenuClipScale_16:9"];
    NSArray *imageNamesSelected = @[@"EditMenuClipScaleSelected_1:1",@"EditMenuClipScaleRamSelected",@"EditMenuClipScaleSelected_1:1",@"EditMenuClipScaleSelected_3:4",@"EditMenuClipScaleSelected_4:3",@"EditMenuClipScaleSelected_9:16",@"EditMenuClipScaleSelected_16:9"];
    NSArray *titles = @[kNSLocalizedString(@"原始"),kNSLocalizedString(@"自由"),@"1:1",@"3:4",@"4:3",@"9:16",@"16:9"];
    int count = (int)imageNames.count;
    CGSize itemSize = CGSizeMake(26+30, 51);
    for (int i = 0; i < count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [view addSubview:btn];
        btn.tag = 10 + i;
        btn.frame = CGRectMake(itemSize.width*i, (view.frame.size.height - itemSize.height)/2, itemSize.width, itemSize.height);
        [btn setImage:[UIImage imageNamed:imageNames[i]] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:imageNamesSelected[i]] forState:UIControlStateSelected];
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:10]];
        [btn setTitleColor:kColorWithHex(0x666666) forState:UIControlStateNormal];
        [btn setTitleColor:kColorWithHex(0xFE7B1A) forState:UIControlStateSelected];
        [btn addTarget:self action:@selector(scaleBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(27, 27) space:7];
        if (i == self.currentSelectIndex){
            btn.selected = YES;
        }
    }
    self.scaleContainerView.contentSize = CGSizeMake(count*itemSize.width, view.frame.size.height);
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
    //还原按钮
    UIButton *recoverBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [recoverBtn setTitle:kNSLocalizedString(@"裁切旋转") forState:UIControlStateDisabled];
    [recoverBtn setTitle:kNSLocalizedString(@"还原") forState:UIControlStateNormal];
    [recoverBtn setTitleColor:kColorWithHex(0x333333) forState:UIControlStateDisabled];
    [recoverBtn setTitleColor:kColorWithHex(0x333333) forState:UIControlStateNormal];
    [recoverBtn.titleLabel setFont:[UIFont systemFontOfSize:16]];
    recoverBtn.frame = CGRectMake((view.frame.size.width - 100)/2, 0, 100, view.frame.size.height);
    [recoverBtn addTarget:self action:@selector(recoverBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:recoverBtn];
    self.recoverBtn = recoverBtn;
    self.recoverBtn.enabled = NO;
}
#pragma mark - Help Method
- (void)enableRecoverBtn:(BOOL)enable {
    self.recoverBtn.enabled = enable;
}

#pragma mark - Events Handle
- (void)rotateBtnClicked:(UIButton *)btn {
    if(self.rotateBlock){
        self.rotateBlock();
    }
}
- (void)scaleBtnClicked:(UIButton *)btn {
    NSInteger index = btn.tag - 10;
    if(self.currentSelectIndex == index){
        return;
    }
    UIButton *preBtn = [self.scaleContainerView viewWithTag:self.currentSelectIndex+10];
    preBtn.selected = NO;
    self.currentSelectIndex = index;
    btn.selected = YES;
    if(self.selectScaleBlock){
        self.selectScaleBlock(index);
    }
}
- (void)selectIndex:(NSInteger)index {
    UIButton *preBtn = [self.scaleContainerView viewWithTag:self.currentSelectIndex+10];
    preBtn.selected = NO;
    self.currentSelectIndex = index;
    
    //选中当前按钮
    UIButton *currentBtn = [self.scaleContainerView viewWithTag:self.currentSelectIndex+10];
    currentBtn.selected = YES;
    
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
- (void)recoverBtnClicked:(id)sender {
    if(self.recoverBlock){
        self.recoverBlock();
    }
}

@end
