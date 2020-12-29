//
//  ImageEditView.h
//  ScaleImageDemo
//
//  Created by zhangweiwei on 16/5/1.
//  Copyright © 2016年 Erica. All rights reserved.
//

#import <UIKit/UIKit.h>

//管理视图的缩放、旋转、拖动的view
@interface SLTransformGestureView : UIView
/// 编辑的视图数组
@property (nonatomic, strong) NSMutableArray *watermarkArray;
///背景图片
@property (nonatomic, weak, readonly) UIImageView *imageView;
///是否在编辑
@property (nonatomic, assign, readonly) BOOL isEditing;

///手势回调
@property (nonatomic, copy) void (^gestureActionBlock)(UIGestureRecognizer *gesture, UIView *currentSelectView);
///编辑状态改变回调
@property (nonatomic, copy) void (^editingStateChangedBlock)(BOOL isEditing);

// 添加水平图片（可旋转缩放）
- (void)addWatermarkView:(UIView *)watermarkView;
- (void)addWatermarkImage:(UIImage *)watermarkImage;
// 结束编辑状态
- (void)endEditing;
- (void)changeEditingViewCenter:(CGPoint)point;
- (void)removeEditingView:(UIView *)view;
- (void)changeEditBtnSuperView:(UIView *)view;

@end
