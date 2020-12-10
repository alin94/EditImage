//
//  UIButton+SLButton.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/9.
//  Copyright © 2020 alin. All rights reserved.
//

#import "UIButton+SLButton.h"

@implementation UIButton (SLButton)
- (void)sl_changeButtonType:(SLButtonType)type withImageMaxSize:(CGSize)imageSize space:(CGFloat)space{
    if(type == SLButtonTypeTopImageBottomText){//图片在上 文字在下
        CGSize realImageSize = self.imageView.frame.size;
        CGFloat labelWidth = self.titleLabel.intrinsicContentSize.width;
        CGFloat labelHeight = self.titleLabel.intrinsicContentSize.height;
        UIEdgeInsets imageEdgeInsets = UIEdgeInsetsMake(-labelHeight-space - (imageSize.height - realImageSize.height) + (imageSize.height-realImageSize.height), 0, 0, -labelWidth);
        UIEdgeInsets labelEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width + (imageSize.width-realImageSize.width), -imageSize.height-space, 0);
        self.titleEdgeInsets = labelEdgeInsets;
        self.imageEdgeInsets = imageEdgeInsets;
    }
}

@end
