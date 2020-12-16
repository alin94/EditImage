//
//  SLSubmenuMosaicView.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/14.
//  Copyright © 2020 alin. All rights reserved.
//

#import <UIKit/UIKit.h>
//马赛克菜单
@interface SLSubmenuMosaicView : UIView
@property (nonatomic, assign) CGFloat squareWidth;//马赛克块大小
@property (nonatomic, assign) CGFloat currentLineWidth;//当前画笔大小
@property (nonatomic, assign, readonly) BOOL isErase;//是否是橡皮檫
@property (nonatomic, copy) void (^selectEraseBlock)(void);//选中橡皮檫
@property (nonatomic, copy) void(^goBackBlock)(void); //返回上一步
@property (nonatomic, copy) void (^goForwardBlock)(void);//上一步
@property (nonatomic, copy) void (^cancelBlock)(void);//取消
@property (nonatomic, copy) void (^doneBlock)(void);//完成
@property (nonatomic, copy) void (^lineWidthChangedBlock)(CGFloat lineWidth);//画笔宽度改变
@property (nonatomic, copy) void (^squareWidthChangedBlock)(CGFloat squareWidth);//画笔类型改变
@property (nonatomic, assign) BOOL backBtnEnable;
@property (nonatomic, assign) BOOL forwardBtnEnable;
- (void)showBackAndForwardBtn;
@end

