//
//  SLRoundCornerTextView.m
//  joywok
//
//  Created by alin on 2020/12/2.
//  Copyright © 2020 Dogesoft. All rights reserved.
//

#import "SLRoundCornerTextView.h"
#import <CoreText/CoreText.h>
#define kTextMargin 10

@implementation SLRoundCornerTextView

//初始化设置
- (void)initConfig {
    self.contentInset = UIEdgeInsetsZero;
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0.0;
    _fillColor = [UIColor clearColor];
}
- (BOOL)rect1:(CGRect)rect1 isLongerThanRect2:(CGRect)rect2{
    if(rect1.size.width > rect2.size.width){
        return YES;
    }
    return NO;
}
- (void)configAttributedString:(NSAttributedString *)attributedString fillColor:(UIColor *)fillColor;
{
    _attributedString  =attributedString;
    _fillColor = fillColor;
    [self setNeedsDisplay];
}
#pragma mark - Setter

- (void)setAttributedString:(NSAttributedString *)attributedString
{
    _attributedString = attributedString;
    [self setNeedsDisplay];
}
- (void)setFillColor:(UIColor *)fillColor {
    _fillColor = fillColor;
    [self setNeedsDisplay];
}
#pragma mark  - Override

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        [self initConfig];
    }
    return self;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    [self initConfig];
}

//重新设置光标大小
- (CGRect)caretRectForPosition:(UITextPosition *)position {
    CGRect originalRect = [super caretRectForPosition:position];
    CGFloat originalHeight = originalRect.size.height;
    originalRect.size.height = self.font.lineHeight;
    originalRect.origin.y -= (self.font.lineHeight - originalHeight)/2.0;
    return originalRect;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if(!self.attributedString){
        return;
    }
    // 步骤1：得到当前用于绘制画布的上下文，用于后续将内容绘制在画布上
    // 因为Core Text要配合Core Graphic 配合使用的，如Core Graphic一样，绘图的时候需要获得当前的上下文进行绘制
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSLog(@"当前context的变换矩阵 %@", NSStringFromCGAffineTransform(CGContextGetCTM(context)));
    // 步骤2：翻转当前的坐标系（因为对于底层绘制引擎来说，屏幕左下角为（0，0））
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);//设置字形变换矩阵为CGAffineTransformIdentity，也就是说每一个字形都不做图形变换
    CGAffineTransform flipVertical = CGAffineTransformMake(1,0,0,-1,0,self.bounds.size.height);
    CGContextConcatCTM(context, flipVertical);//将当前context的坐标系进行flip
    NSLog(@"翻转后context的变换矩阵 %@", NSStringFromCGAffineTransform(CGContextGetCTM(context)));
    
    // 步骤3：创建绘制区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    // 步骤4：创建需要绘制的文字与计算需要绘制的区域
    NSAttributedString * attrString = self.attributedString;
    // 步骤5：根据AttributedString生成CTFramesetterRef
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, [attrString length]), path, NULL);
    
    //获取frame中CTLineRef数组
    CFArrayRef Lines = CTFrameGetLines(frame);
    //获取数组Lines中的个数
    CFIndex lineCount = CFArrayGetCount(Lines);
    
    //获取基线原点
    CGPoint origins[lineCount];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
    
    //获取所以的frame信息
    NSMutableArray *lineBoundsArray = [NSMutableArray array];
    //最宽的那个
    CGFloat maxLineW = 0;
    for (CFIndex i = 0; i < lineCount; i ++) {
        CTLineRef line = CFArrayGetValueAtIndex(Lines, i);
        //相对于每一行基线原点的偏移量和宽高（例如：{{1.2， -2.57227}, {208.025, 19.2523}}，就是相对于本身的基线原点向右偏移1.2个单位，向下偏移2.57227个单位，后面是宽高）
        CGRect lineBounds = CTLineGetImageBounds((CTLineRef)line, context);
        lineBounds.origin.x += origins[i].x;
        lineBounds.origin.y += origins[i].y;
        
        if(lineBounds.size.width > maxLineW){
            maxLineW = lineBounds.size.width;
        }
        [lineBoundsArray addObject:NSStringFromCGRect(lineBounds)];
    }
    
    UIColor *color = self.fillColor;
    if(!color){
        color = [UIColor greenColor];
    }
    [color set];  //设置线条颜色
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    bezierPath.lineWidth = 1;
    bezierPath.lineCapStyle = kCGLineCapRound;  //线条拐角
    bezierPath.lineJoinStyle = kCGLineCapRound;  //终点处理
    //调整宽度
    CGFloat tolerant = 20;//容差
    for(int i = 0; i < lineBoundsArray.count ; i++){
        CGRect lineBounds = CGRectFromString(lineBoundsArray[i]);
        if(i >= 1){
            //对比上一个
            CGRect preBounds = CGRectFromString(lineBoundsArray[i - 1]);
            if(fabs(preBounds.size.width - lineBounds.size.width) < tolerant){
                if(preBounds.size.width > lineBounds.size.width){
                    lineBounds.size.width = preBounds.size.width;
                }else{
                    preBounds.size.width = lineBounds.size.width;
                }
                if(maxLineW - preBounds.size.width < tolerant){
                    preBounds.size.width = maxLineW;
                }
                NSString *newPreRect = NSStringFromCGRect(preBounds);
                [lineBoundsArray replaceObjectAtIndex:i-1 withObject:newPreRect];
                
            }
            
        }
        if(maxLineW - lineBounds.size.width < tolerant){
            //适当调整成最大宽度
            lineBounds.size.width = maxLineW;
        }
        NSString *newRect = NSStringFromCGRect(lineBounds);
        [lineBoundsArray replaceObjectAtIndex:i withObject:newRect];
    }
    CGFloat startX = 0;
    for(int i = 0; i < lineBoundsArray.count ; i++){
        CGRect lineBounds =CGRectFromString(lineBoundsArray[i]);
        NSLog(@"i ==== %d w === %f",i,lineBounds.size.width);
        CGFloat topY = lineBounds.origin.y + lineBounds.size.height;
        if(topY + kTextMargin > self.frame.size.height){
            topY = self.frame.size.height - kTextMargin - 1;
        }
        
        //左上角
        if(i == 0){
            startX = lineBounds.origin.x;
            [bezierPath addArcWithCenter:CGPointMake(lineBounds.origin.x,topY) radius:kTextMargin startAngle:M_PI endAngle:M_PI*0.5 clockwise:NO];
        }else {
            //改成统一的x
            lineBounds.origin.x = startX;
        }
        //右上角
        if(i == 0){
            [bezierPath addArcWithCenter:CGPointMake(lineBounds.origin.x + lineBounds.size.width, topY) radius:kTextMargin startAngle:0.5*M_PI endAngle:2*M_PI clockwise:NO];
        }else{
            CGRect preBounds = CGRectFromString(lineBoundsArray[i-1]);
            //右上角
            if(preBounds.size.width == lineBounds.size.width){
                //上面的跟现在的一样长什么都不画
                
            }else if([self rect1:preBounds isLongerThanRect2:lineBounds]){
                //上面比现在长
                [bezierPath addArcWithCenter:CGPointMake(lineBounds.origin.x + lineBounds.size.width + kTextMargin*2 , preBounds.origin.y - kTextMargin*2) radius:kTextMargin startAngle:0.5*M_PI endAngle:M_PI clockwise:YES];
            }else{
                //上面比现在短
                [bezierPath addArcWithCenter:CGPointMake(lineBounds.origin.x + lineBounds.size.width , preBounds.origin.y - kTextMargin) radius:kTextMargin startAngle:0.5*M_PI endAngle:2*M_PI clockwise:NO];
            }
        }
        //右下角
        if(i == lineBoundsArray.count - 1){
            [bezierPath addArcWithCenter:CGPointMake(lineBounds.origin.x + lineBounds.size.width , lineBounds.origin.y) radius:kTextMargin startAngle:0 endAngle:1.5*M_PI clockwise:NO];
        }else{
            CGRect nextBounds = CGRectFromString(lineBoundsArray[i+1]);
            //右下角
            if(nextBounds.size.width == lineBounds.size.width){
                //上面的跟现在的一样长
                [bezierPath addLineToPoint:CGPointMake(lineBounds.origin.x + lineBounds.size.width + kTextMargin, lineBounds.origin.y - kTextMargin)];
            }else if([self rect1:lineBounds isLongerThanRect2:nextBounds]){
                //比下面长
                [bezierPath addArcWithCenter:CGPointMake(lineBounds.origin.x + lineBounds.size.width , lineBounds.origin.y) radius:kTextMargin startAngle:0 endAngle:1.5*M_PI clockwise:NO];
                
            }else{
                //比下面短
                [bezierPath addArcWithCenter:CGPointMake(lineBounds.origin.x + lineBounds.size.width + kTextMargin*2 , lineBounds.origin.y + kTextMargin) radius:kTextMargin startAngle:M_PI endAngle:1.5*M_PI clockwise:YES];
                
            }
        }
        //左下角
        if(i == lineBoundsArray.count - 1){
            //添加左下角圆角
            [bezierPath addArcWithCenter:CGPointMake(startX, lineBounds.origin.y) radius:kTextMargin startAngle:1.5*M_PI endAngle:M_PI clockwise:NO];
        }
    }
    [bezierPath closePath];
    [bezierPath fill]; //Draws line 根据坐标点连线
    
    // 步骤6：进行绘制
    CTFrameDraw(frame, context);
    
    // 步骤7.内存管理
    CFRelease(frame);
    CFRelease(path);
    CFRelease(frameSetter);
}

@end
