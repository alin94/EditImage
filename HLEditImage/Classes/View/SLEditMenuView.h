//
//  SLEditMenuView.h
//  DarkMode
//
//  Created by wsl on 2019/10/9.
//  Copyright © 2019 wsl. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
///编辑对象类型 视频 Or  图片
typedef NS_ENUM(NSUInteger, SLEditObject) {
    ///没有编辑对象
    SLEditObjectUnknow = 0,
    /// 图片编辑
    SLEditObjectPicture = 1,
    /// 视频编辑
    SLEditObjectVideo
};
///视频和图片的编辑类型
typedef NS_ENUM(NSUInteger, SLEditMenuType) {
    /// 无类型
    SLEditMenuTypeUnknown = 0,
    /// 涂鸦
    SLEditMenuTypeGraffiti = 1,
    /// 文字
    SLEditMenuTypeText,
    /// 贴画
    SLEditMenuTypeSticking,
    /// 视频裁剪
    SLEditMenuTypeVideoClipping,
    /// 图片马赛克
    SLEditMenuTypePictureMosaic,
    /// 图片裁剪
    SLEditMenuTypePictureClipping,
};
/// 底部音视频、图片编辑主菜单栏
@interface SLEditMenuView : UIView
/// 编辑对象
@property (nonatomic, assign) SLEditObject editObject;
///提示文字
@property (nonatomic, copy) NSString *tipText;
///完成按钮文字
@property (nonatomic, copy) NSString *doneBtnTitle;
/// 选择编辑的子菜单回调
@property (nonatomic, copy) void(^selectEditMenu)(SLEditMenuType editMenuType,  NSDictionary * _Nullable setting);
//隐藏子菜单
@property (nonatomic, copy) void(^hideSubMenuBlock)(SLEditMenuType menuType);
@property (nonatomic, copy) void (^doneBtnClickBlock)(void);
///设置前进后退按钮是否可点
- (void)enableBackBtn:(BOOL)enableBack forwardBtn:(BOOL)enableForward;
@end

NS_ASSUME_NONNULL_END
