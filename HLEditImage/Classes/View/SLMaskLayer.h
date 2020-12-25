//
//  SLMaskLayer.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/24.
//  Copyright © 2020 alin. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLMaskLayer : CAShapeLayer
/// 遮罩颜色
@property (nonatomic, assign) CGColorRef maskColor;
/// 遮罩区域的非交集区域
@property (nonatomic, setter=setMaskRect:) CGRect maskRect;

- (void)setMaskRect:(CGRect)maskRect animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
