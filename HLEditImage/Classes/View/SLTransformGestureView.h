//
//  ImageEditView.h
//  ScaleImageDemo
//
//  Created by zhangweiwei on 16/5/1.
//  Copyright © 2016年 Erica. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SLTransformGestureView : UIView
// 编辑的视图数组
@property (nonatomic, strong) NSMutableArray *watermarkArray;
// 背景图片
@property (nonatomic, weak, readonly) UIImageView *imageView;
@property (nonatomic, copy) void (^gestureActionBlock)(UIGestureRecognizer *gesture, UIView *currentSelectView);

// 添加水平图片（可旋转缩放）
- (void)addWatermarkView:(UIView *)watermarkView;
- (void)addWatermarkImage:(UIImage *)watermarkImage;
// 结束编辑状态
- (void)endEditing;



@end
