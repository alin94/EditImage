//
//  NSString+SLLocalizable.h
//  HLEditImageDemo
//
//  Created by alin on 2020/12/9.
//  Copyright © 2020 alin. All rights reserved.
//

#import <Foundation/Foundation.h>
#define kNSLocalizedString(key) key.sl_localizable
@interface NSString (SLLocalizable)
@property (nonatomic, copy, readonly) NSString *sl_localizable;
@end

