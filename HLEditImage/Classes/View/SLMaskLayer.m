//
//  SLMaskLayer.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/24.
//  Copyright © 2020 alin. All rights reserved.
//

#import "SLMaskLayer.h"

@implementation SLMaskLayer
#pragma mark - Override
- (instancetype)init {
    self = [super init];
    if (self) {
        self.contentsScale = [[UIScreen mainScreen] scale];
    }
    return self;
}
- (void)setMaskColor:(CGColorRef)maskColor {
    self.fillColor = maskColor;
    // 填充规则  maskRect和bounds的非交集
    self.fillRule = kCAFillRuleEvenOdd;
}
- (void)setMaskRect:(CGRect)maskRect {
    _maskRect = maskRect;
    [self setMaskRect:maskRect animated:NO];
}
- (CGColorRef)maskColor {
    return self.fillColor;
}
- (void)setMaskRect:(CGRect)maskRect animated:(BOOL)animated {
    CGMutablePathRef mPath = CGPathCreateMutable();
    CGPathAddRect(mPath, NULL, self.bounds);
    CGPathAddRect(mPath, NULL, maskRect);
    [self removeAnimationForKey:@"SL_maskLayer_opacityAnimate"];
    if (animated) {
        CABasicAnimation *animate = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animate.duration = 0.25f;
        animate.fromValue = @(0.0);
        animate.toValue = @(1.0);
        self.path = mPath;
        [self addAnimation:animate forKey:@"SL_maskLayer_opacityAnimate"];
    } else {
        self.path = mPath;
    }
}

@end
