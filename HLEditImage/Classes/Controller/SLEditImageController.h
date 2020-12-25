//
//  SLEditImageController.h
//  DarkMode
//
//  Created by wsl on 2019/10/31.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLEditImageController : UIViewController
@property (nonatomic, strong) UIImage *image; //当前拍摄的照片
@property (nonatomic, copy) NSString *tipText;//底部提示文字
@property (nonatomic, copy) void (^editFinishedBlock)(UIImage *image);
- (instancetype)initWithImage:(UIImage *)image tipText:(NSString *)tipText;
@end

NS_ASSUME_NONNULL_END
