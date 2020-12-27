//
//  SLImageClipController.h
//  DarkMode
//
//  Created by wsl on 2019/11/2.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SLImageZoomView;

NS_ASSUME_NONNULL_BEGIN

@interface SLImageClipController : UIViewController
@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) void (^clipFinishedBlock)(SLImageZoomView *zoomImage);
@end

NS_ASSUME_NONNULL_END
