//
//  SLSubmenuGraffitiView.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/8.
//  Copyright © 2020 alin. All rights reserved.
//

#import "SLSubmenuGraffitiView.h"
#import "SLUtilsMacro.h"

@interface SLSubmenuGraffitiView ()

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
