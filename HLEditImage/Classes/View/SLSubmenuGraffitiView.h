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
@property (nonatomic, strong) UIColor *currentColor; // 当前画笔颜色
@property (nonatomic, copy) void(^selectedLineColor)(UIColor *lineColor); //选中颜色的回调
@property (nonatomic, copy) void (^selectEraseBlock)(void);//选中橡皮檫

@property (nonatomic, copy) void(^goBackBlock)(void); //返回上一步
@property (nonatomic, copy) void (^goForwardBlock)(void);//上一步

@property (nonatomic, assign) BOOL backBtnEnable;
- (void)showBackAndForwardBtn;
@end

