//
//  SLRoundCornerTextView.h
//  joywok
//
//  Created by alin on 2020/12/2.
//  Copyright © 2020 Dogesoft. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLRoundCornerTextView : UITextView
@property (nonatomic, strong) NSAttributedString *attributedString;
@property (nonatomic, strong) UIColor *fillColor;
- (void)configAttributedString:(NSAttributedString *)attributedString fillColor:(UIColor *)fillColor;

@end

NS_ASSUME_NONNULL_END
