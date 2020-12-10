//
//  UIButton+SLButton.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/9.
//  Copyright © 2020 alin. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SLButtonType) {
    SLButtonTypeDefault,
    SLButtonTypeTopImageBottomText
    
};

//改变按钮布局
@interface UIButton (SLButton)
- (void)sl_changeButtonType:(SLButtonType)type withImageMaxSize:(CGSize)imageSize space:(CGFloat)space;
@end

