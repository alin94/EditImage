//
//  SLSubmenuGraffitiView.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/8.
//  Copyright © 2020 alin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SLGraffitiShapeType) {
    SLGraffitiShapeRandom = 0,//自由
    SLGraffitiShapeEllipse = 1,//椭圆
    SLGraffitiShapeRect = 2,//矩形
    SLGraffitiShapeArrow = 3//箭头
};

/// 涂鸦子菜单 画笔颜色形状选择
@interface SLSubmenuGraffitiView : UIView
@property (nonatomic, strong) UIColor *currentColor; // 当前画笔颜色
@property (nonatomic, copy) void(^selectedLineColor)(UIColor *lineColor); //选中颜色的回调
@property (nonatomic, copy) void (^selectEraseBlock)(void);//选中橡皮檫
@property (nonatomic, copy) void(^goBackBlock)(void); //返回上一步
@property (nonatomic, copy) void (^goForwardBlock)(void);//上一步
@property (nonatomic, copy) void (^cancelBlock)(void);//取消
@property (nonatomic, copy) void (^doneBlock)(void);//完成
@property (nonatomic, copy) void (^lineWidthChangedBlock)(CGFloat lineWidth);//画笔宽度改变
@property (nonatomic, copy) void (^brushShapeChangedBlock)(SLGraffitiShapeType shapeType);//画笔类型改变
@property (nonatomic, assign) BOOL backBtnEnable;
@property (nonatomic, assign) BOOL forwardBtnEnable;

- (void)showBackAndForwardBtn;
@end

