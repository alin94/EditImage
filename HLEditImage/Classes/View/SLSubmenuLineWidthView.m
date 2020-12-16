//
//  SLSubmenuLineWidthView.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/14.
//  Copyright © 2020 alin. All rights reserved.
//

#import "SLSubmenuLineWidthView.h"
#import "SLUtilsMacro.h"
#import "NSString+SLLocalizable.h"
#import "UIButton+SLButton.h"


@implementation SLSubmenuLineWidthView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _currentSelectIndex = 2;
        self.backgroundColor = [UIColor whiteColor];
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    [self createSubmenu];
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake((self.frame.size.width - 50)/2, self.frame.size.height - 50, 50, 50);
    [closeBtn setImage:[UIImage imageNamed:@"EditMenuArrowDown"] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(closeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:closeBtn];
}
- (void)createSubmenu {
    NSArray *imageNames = @[@"EditBrushSize1",@"EditBrushSize2",@"EditBrushSize3",@"EditBrushSize4",@"EditBrushSize5"];
    self.imageNames = imageNames;
    NSArray *imageNamesSelected = @[@"EditBrushSize1Selected",@"EditBrushSize2Selected",@"EditBrushSize3Selected",@"EditBrushSize4Selected",@"EditBrushSize5Selected"];
    NSArray *titles = @[kNSLocalizedString(@"超小"),kNSLocalizedString(@"小"),kNSLocalizedString(@"标准"),kNSLocalizedString(@"大"),kNSLocalizedString(@"超大")];
    int count = (int)imageNames.count;
    CGSize itemSize = CGSizeMake(48, 52);
    CGFloat space = (self.frame.size.width - itemSize.width*count)/(count+1);
    for (int i = 0; i < count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:btn];
        btn.tag = 10 + i;
        btn.frame = CGRectMake(space+i*(itemSize.width+space), 30, itemSize.width, itemSize.height);
        [btn setImage:[UIImage imageNamed:imageNames[i]] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:imageNamesSelected[i]] forState:UIControlStateSelected];
        [btn setTitle:titles[i] forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont systemFontOfSize:10]];
        [btn setTitleColor:kColorWithHex(0x666666) forState:UIControlStateNormal];
        [btn setTitleColor:kColorWithHex(0xFE7B1A) forState:UIControlStateSelected];
        [btn addTarget:self action:@selector(shapeBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [btn sl_changeButtonType:SLButtonTypeTopImageBottomText withImageMaxSize:CGSizeMake(28, 28) space:9];
        if(self.currentSelectIndex == i){
            btn.selected = YES;
        }
    }
    
}
- (void)shapeBtnClicked:(UIButton *)btn {
    if(btn.isSelected){
        return;
    }
    //取消前一个选中的按钮
    UIButton *preSelectedBtn = [self viewWithTag:self.currentSelectIndex+10];
    preSelectedBtn.selected = NO;
    
    btn.selected = YES;
    self.currentSelectIndex = btn.tag - 10;
    if(self.selectItemBlock){
        self.selectItemBlock(self.currentSelectIndex,[UIImage imageNamed:self.imageNames[self.currentSelectIndex]]);
    }
}
- (void)closeBtnClicked:(UIButton *)btn {
    if(self.closeBlock){
        self.closeBlock();
    }
}


@end
