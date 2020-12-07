//
//  AppDelegate.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/4.
//  Copyright © 2020 alin. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] init];
    self.window.backgroundColor = [UIColor whiteColor];
    self.window.frame = [UIScreen mainScreen].bounds;
    UIViewController *vc = [UIStoryboard storyboardWithName:@"Main" bundle:nil].instantiateInitialViewController;
    self.window.rootViewController = vc;
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



@end
