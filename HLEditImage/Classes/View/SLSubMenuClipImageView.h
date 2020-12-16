//
//  SLSubMenuClipImageView.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/15.
//  Copyright © 2020 alin. All rights reserved.
//

#import <UIKit/UIKit.h>

//裁剪图片底部菜单
@interface SLSubMenuClipImageView : UIView
@property (nonatomic, copy) void (^rotateBlock)(void);//旋转
@property (nonatomic, copy) void (^recoverBlock)(void);//返回到原始值
@property (nonatomic, copy) void (^cancelBlock)(void);//取消
@property (nonatomic, copy) void (^doneBlock)(void);//完成
@property (nonatomic, copy) void (^selectScaleBlock)(NSInteger selectIndex);
@property (nonatomic, assign) NSInteger currentSelectIndex;
- (void)selectIndex:(NSInteger)index;
- (void)enableRecoverBtn:(BOOL)enable;
@end

