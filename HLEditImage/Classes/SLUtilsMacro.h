//
//  SLUtilsMacro.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/4.
//  Copyright © 2020 alin. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#ifndef SLUtilsMacro_h
#define SLUtilsMacro_h

#define kColorWithHex(hexColor) [UIColor colorWithRed:((float)((hexColor & 0xFF0000) >> 16))/255.0 green:((float)((hexColor & 0xFF00) >> 8))/255.0 blue:((float)(hexColor & 0xFF))/255.0 alpha:1]

#define kColorWithHex_A(hexColor,alpha) [UIColor colorWithRed:((float)((hexColor & 0xFF0000) >> 16))/255.0 green:((float)((hexColor & 0xFF00) >> 8))/255.0 blue:((float)(hexColor & 0xFF))/255.0 alpha:alpha]

#define kSafeAreaTopHeight 0
#define kSafeAreaBottomHeight 0


#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height
#define kNavigationHeight (FuncIsIPhoneX?88:64)
//#define kSafeAreaBottomHeight (FuncIsIPhoneX ? 34 : 0)
//#define kSafeAreaTopHeight (FuncIsIPhoneX ? 24 : 0)

#define FuncIsIPhoneX (IS_IPHONE_X || IS_IPHONE_Xr || IS_IPHONE_Xs || IS_IPHONE_Xs_Max)

#define IS_IPad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
//判断iPhoneX
#define IS_IPHONE_X ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) && !IS_IPad : NO)
//判断iPHoneXr
#define IS_IPHONE_Xr ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) && !IS_IPad : NO)
//判断iPhoneXs
#define IS_IPHONE_Xs ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) && !IS_IPad : NO)
//判断iPhoneXs Max
#define IS_IPHONE_Xs_Max ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) && !IS_IPad : NO)

#define IS_IPHONE_SERIES (kStatusbarHeight == 44)
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;

#endif /* SLUtilsMacro_h */
