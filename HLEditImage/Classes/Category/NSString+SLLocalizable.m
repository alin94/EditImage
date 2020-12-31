//
//  NSString+SLLocalizable.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/9.
//  Copyright © 2020 alin. All rights reserved.
//

#import "NSString+SLLocalizable.h"

@implementation NSString (SLLocalizable)
-(NSString *)sl_localizable{
    NSArray *bundlePaths = [[NSBundle bundleForClass:NSClassFromString(@"SLEditImageController")] pathsForResourcesOfType:@"bundle" inDirectory:nil];
    if (bundlePaths.count < 1) {
        return self;
    }
    NSString *resourcePath = @"";
    for(NSString *path in bundlePaths){
        if([path containsString:@"HLEditImage.bundle"]){
            resourcePath = path;
            break;
        }
    }
    NSBundle *resourceBundle = [NSBundle bundleWithPath:resourcePath];
    NSString *ret = [resourceBundle localizedStringForKey:self value:@"" table:nil];
    return ret;
    
}

@end
