//
//  SLSubmenuLineWidthView.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/14.
//  Copyright © 2020 alin. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
//画笔宽度选择菜单
@interface SLSubmenuLineWidthView : UIView
@property (nonatomic, copy) void (^selectItemBlock)(NSInteger selectIndex,UIImage *selectIconImage);
@property (nonatomic, copy) void (^closeBlock)(void);
@property (nonatomic, assign) NSInteger currentSelectIndex;
@property (nonatomic, strong) NSArray *imageNames;

@end

NS_ASSUME_NONNULL_END
