//
//  ImageEditView.h
//  ScaleImageDemo
//
//  Created by zhangweiwei on 16/5/1.
//  Copyright © 2016年 Erica. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SLTransformGestureView : UIView
// 背景图片
@property (nonatomic, weak, readonly) UIImageView *imageView;

// 添加水平图片（可旋转缩放）
- (void)addWatermarkImage:(UIImage *)watermarkImage;
// 结束编辑状态
- (void)endEditing;



@end
