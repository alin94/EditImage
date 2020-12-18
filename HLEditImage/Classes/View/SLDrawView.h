//
//  SLDrawView.h
//  DarkMode
//
//  Created by wsl on 2019/10/12.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SLDrawShapeType) {
    SLDrawShapeRandom = 0,//自由
    SLDrawShapeEllipse = 1,//椭圆
    SLDrawShapeRect = 2,//矩形
    SLDrawShapeArrow = 3,//箭头
    SLDrawShapeMosic = 4//马赛克
};

//管理画笔数据的
@interface SLDrawBrushTool : NSObject
@property (nonatomic, strong) UIImage *image;
/// 线粗 默认5.0
@property (nonatomic, assign) CGFloat lineWidth;
/// 线颜色  默认 黑色
@property (nonatomic, strong) UIColor *lineColor;
///是否是橡皮檫
@property (nonatomic, assign) BOOL isErase;
///马赛克方块大小
@property (nonatomic, assign) CGFloat squareWidth;

///画笔形状 默认 自由模式
@property (nonatomic, assign) SLDrawShapeType shapeType;

- (instancetype)initWithDrawBounds:(CGRect)bounds;

@end

/// 涂鸦视图 画板   默认白底
@interface SLDrawView : UIView
@property (nonatomic, strong) SLDrawBrushTool *brushTool;
///是否可以画画
@property (nonatomic, assign) BOOL enableDraw;
/// 正在绘画 
@property (nonatomic, readonly) BOOL isDrawing;
/// 能否返回
@property (nonatomic, readonly) BOOL canBack;
/// 能否前进
@property (nonatomic, readonly) BOOL canForward;
/// 开始绘画
@property (nonatomic, copy) void(^drawBegan)(void);
/// 结束绘画
@property (nonatomic, copy) void(^drawEnded)(void);
/// 可撤销状态改变
@property (nonatomic, copy) void (^lineCountChangedBlock)(BOOL canBack,BOOL canForward);
/// 数据  笔画数据
@property (nonatomic, strong) NSDictionary *data;


/// 前进一步
- (void)goForward;
/// 返回一步
- (void)goBack;
/// 清空画板 不可恢复
- (void)clear;
///返回上一次画画的状态
- (void)goBackToLastDrawState;
@end


