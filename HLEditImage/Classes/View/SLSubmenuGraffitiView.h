//
//  SLSubmenuGraffitiView.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/8.
//  Copyright © 2020 alin. All rights reserved.
//

#import <UIKit/UIKit.h>

/// 涂鸦子菜单 画笔颜色形状选择
@interface SLSubmenuGraffitiView : UIView
@property (nonatomic, assign) int currentColorIndex; // 当前画笔颜色索引
@property (nonatomic, strong) UIColor *currentColor; // 当前画笔颜色
@property (nonatomic, copy) void(^selectedLineColor)(UIColor *lineColor); //选中颜色的回调
@property (nonatomic, copy) void(^goBack)(void); //返回上一步
@property (nonatomic, strong) UIButton *backBtn; //返回按钮
@property (nonatomic, assign) BOOL backBtnEnable;

@end

