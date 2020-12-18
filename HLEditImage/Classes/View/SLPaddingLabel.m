//
//  SLPaddingLabel.m
//  DarkMode
//
//  Created by wsl on 2019/10/19.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLPaddingLabel.h"

@interface SLPaddingLabel ()
@property (nonatomic, strong) UIView *colorView;

@end

@implementation SLPaddingLabel
- (UIView *)colorView {
    if(!_colorView){
        _colorView = [[UIView alloc] initWithFrame:self.bounds];
        [self addSubview:_colorView];
    }
    return _colorView;
}
- (void)drawTextInRect:(CGRect)rect {
  [super drawTextInRect:UIEdgeInsetsInsetRect(rect, _textPadding)];
}
- (void)setTextPadding:(UIEdgeInsets)textPadding {
    _textPadding = textPadding;
    [self setNeedsLayout];
}
- (void)setSl_backgroundColor:(UIColor *)sl_backgroundColor {
    _sl_backgroundColor = sl_backgroundColor;
    self.colorView.backgroundColor = sl_backgroundColor;
}
- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.colorView.layer.cornerRadius = cornerRadius;
    self.colorView.clipsToBounds = YES;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    _colorView.frame = self.bounds;
}
@end
