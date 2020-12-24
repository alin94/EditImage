//
//  SLImageClipView.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/21.
//  Copyright © 2020 alin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLImageZoomView.h"

//裁剪图片视图
@interface SLImageClipView : UIView
@property (nonatomic, copy) void (^doneBtnClickBlock)(void);
@property (nonatomic, copy) void (^cancelBtnClickBlock)(void);
@property (nonatomic, assign) CGAffineTransform scaleTrans;
@property (nonatomic, assign) NSInteger rotateAngle;
// 缩放视图
@property (nonatomic, weak) SLImageZoomView *zoomView;
- (void)startEditWithZoomView:(SLImageZoomView *)zoomView;
- (void)showMaskLayer:(BOOL)show;
- (void)endEdit;
@end


