//
//  SLDrawView.m
//  DarkMode
//
//  Created by wsl on 2019/10/12.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLDrawView.h"
#import "UIImage+SLCommon.h"


@interface SLShapelayer : CAShapeLayer
@property (nonatomic, assign) SLDrawShapeType shapeType;//类型
@property (nonatomic, assign) BOOL isErase;//是否是橡皮檫
@end
@implementation SLShapelayer


@end

@interface SLDrawBezierPath : UIBezierPath
@property (nonatomic, strong) UIColor *color; //曲线颜色

@end
@implementation SLDrawBezierPath

@end


@interface SLDrawBrushTool ()
/// 笔画
@property (nonatomic, strong) NSMutableArray <SLDrawBezierPath *>*lineArray;
/// 图层
@property (nonatomic, strong) NSMutableArray <CAShapeLayer *>*layerArray;
/// 删除的笔画
@property (nonatomic, strong) NSMutableArray <SLDrawBezierPath *>*deleteLineArray;
/// 删除的图层
@property (nonatomic, strong) NSMutableArray <CAShapeLayer *>*deleteLayerArray;
@property (nonatomic, strong) UIImage *mosicImage;//马赛克图片
@property (nonatomic, assign) CGRect bounds;

@end
@implementation SLDrawBrushTool
- (instancetype)initWithDrawBounds:(CGRect)bounds {
    self = [self init];
    if(self){
        self.bounds = bounds;
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if(self){
        _layerArray = [NSMutableArray array];
        _lineArray = [NSMutableArray array];
        _deleteLineArray = [NSMutableArray array];
        _deleteLayerArray = [NSMutableArray array];
        _lineWidth = 8.f;
        _lineColor = [UIColor blackColor];
        _shapeType = SLDrawShapeRandom;

    }
    return self;
}
- (void)setImage:(UIImage *)image {
    _image = image;
    [self createPatternImage];
}
- (void)setSquareWidth:(CGFloat)squareWidth {
    if(_squareWidth != squareWidth){
        _squareWidth = squareWidth;
        if (_image){
            _mosicImage = [_image sl_transToMosaicImageWithBlockLevel:squareWidth*4];
        }
    }
    
}

- (void)createPatternImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    //获得当前Context
    CGContextRef context = UIGraphicsGetCurrentContext();
    //CTM变换，调整坐标系，*重要*，否则橡皮擦使用的背景图片会发生翻转。
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -self.bounds.size.height);
    //图片适配到当前View的矩形区域，会有拉伸
    [self.image drawInRect:self.bounds];
    //获取拉伸并翻转后的图片
    UIImage *stretchedImg = UIGraphicsGetImageFromCurrentImageContext();
    _image = stretchedImg;
    UIGraphicsEndImageContext();
}


@end

@interface SLDrawView ()
{
    BOOL _isWork;
    BOOL _isBegan;
}
@property (nonatomic, assign) CGPoint beginPoint;
@property (nonatomic, assign) NSInteger lastLinePathCount;//之前的路径总数

@end

@implementation SLDrawView

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _enableDraw = YES;
        self.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        self.exclusiveTouch = YES;
        self.userInteractionEnabled = YES;
    }
    return self;
}
- (void)setEnableDraw:(BOOL)enableDraw {
    if(_enableDraw != enableDraw){
        _enableDraw = enableDraw;
        if(enableDraw){
            self.lastLinePathCount = self.brushTool.lineArray.count;
        }
        self.userInteractionEnabled = enableDraw;
    }
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self checkLineCount];
}
//开始绘画
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if ([event allTouches].count == 1) {
        _isWork = NO;
        _isBegan = YES;
        //1、每次触摸的时候都应该去创建一条贝塞尔曲线
        SLDrawBezierPath *path = [SLDrawBezierPath new];
        //设置颜色
        if(self.brushTool.isErase){
            path.color = [[UIColor alloc]initWithPatternImage:self.brushTool.image];
            [path strokeWithBlendMode:kCGBlendModeClear alpha:1.0f];
            [path fillWithBlendMode:kCGBlendModeClear alpha:1.0];
        }else {
            path.color = self.brushTool.lineColor;//保存线条当前颜色
            if(self.brushTool.shapeType == SLDrawShapeMosic){
                path.color = [[UIColor alloc]initWithPatternImage:self.brushTool.mosicImage];
                [path strokeWithBlendMode:kCGBlendModeClear alpha:1.0f];
                [path fillWithBlendMode:kCGBlendModeClear alpha:1.0];
            }
        }
        path.lineWidth = self.brushTool.lineWidth;
        //2、移动画笔
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        self.beginPoint = point;
        if(self.brushTool.shapeType == SLDrawShapeRandom || self.brushTool.shapeType == SLDrawShapeMosic || self.brushTool.isErase){
            [path moveToPoint:point];
        }
        [self.brushTool.lineArray addObject:path];
        //清理已删除的笔画
        [self.brushTool.deleteLayerArray removeAllObjects];
        [self.brushTool.deleteLineArray removeAllObjects];
        CAShapeLayer *slayer = [self createShapeLayer:path];
        [self.layer addSublayer:slayer];
        [self.brushTool.layerArray addObject:slayer];
    }
    [super touchesBegan:touches withEvent:event];
}
//绘画中
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (_isBegan || _isWork) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self];
        SLDrawBezierPath *path = self.brushTool.lineArray.lastObject;
        if (!CGPointEqualToPoint(path.currentPoint, point)) {
            if (_isBegan && self.drawBegan) self.drawBegan();
            _isBegan = NO;
            _isWork = YES;
            if(self.brushTool.shapeType == SLDrawShapeRandom || self.brushTool.shapeType == SLDrawShapeMosic|| self.brushTool.isErase ){
                [path addLineToPoint:point];
            }else if (self.brushTool.shapeType == SLDrawShapeEllipse){
                path = [SLDrawBezierPath bezierPathWithOvalInRect:[self getRectWithStartPoint:self.beginPoint endPoint:point]];
            }
            else if (self.brushTool.shapeType == SLDrawShapeRect){
                path = [SLDrawBezierPath bezierPathWithRect:[self getRectWithStartPoint:self.beginPoint endPoint:point]];
            }else if (self.brushTool.shapeType == SLDrawShapeArrow){
                path = [[SLDrawBezierPath alloc] init];
                [path moveToPoint:self.beginPoint];;
                [path addLineToPoint:point];
                [path appendPath:[self createArrowWithStartPoint:self.beginPoint endPoint:point]];
            }
            //重新设置属性
            if(self.brushTool.shapeType != SLDrawShapeRandom){
                path.color = self.brushTool.lineColor;//保存线条当前颜色
                path.lineWidth = self.brushTool.lineWidth;
                [self.brushTool.lineArray replaceObjectAtIndex:self.brushTool.lineArray.count - 1 withObject:path];
            }
            CAShapeLayer *slayer = self.brushTool.layerArray.lastObject;
            slayer.path = path.CGPath;
        }
    }
    [super touchesMoved:touches withEvent:event];
}
//结束绘画
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if (_isWork) {
        if (self.drawEnded) self.drawEnded();
    } else {
        if ((_isBegan)) {
            [self goBack];
        }
    }
    _isBegan = NO;
    _isWork = NO;
    [self checkLineCount];
    [super touchesEnded:touches withEvent:event];
}
//取消绘画
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (_isWork) {
        if (self.drawEnded) self.drawEnded();
    } else {
        if ((_isBegan)) {
            [self goBack];
        }
    }
    _isBegan = NO;
    _isWork = NO;
    [super touchesCancelled:touches withEvent:event];
}

#pragma mark - Help Methods
//创建线条图层
- (CAShapeLayer *)createShapeLayer:(SLDrawBezierPath *)path {
    /** 1、渲染快速。CAShapeLayer使用了硬件加速，绘制同一图形会比用Core Graphics快很多。Core Graphics实现示例： https://github.com/wsl2ls/Draw.git
     2、高效使用内存。一个CAShapeLayer不需要像普通CALayer一样创建一个寄宿图形，所以无论有多大，都不会占用太多的内存。
     3、不会被图层边界剪裁掉。
     4、不会出现像素化。 */
    SLShapelayer *slayer = [SLShapelayer layer];
    slayer.path = path.CGPath;
    slayer.backgroundColor = [UIColor clearColor].CGColor;
    slayer.fillColor = [UIColor clearColor].CGColor;
    if(self.brushTool.shapeType != SLDrawShapeArrow){
        slayer.lineCap = kCALineCapRound;
        slayer.lineJoin = kCALineJoinRound;
    }
    slayer.strokeColor = path.color.CGColor;
    slayer.lineWidth = path.lineWidth;
    
    //自定义路径的描述
    slayer.shapeType = self.brushTool.shapeType;
    slayer.isErase = self.brushTool.isErase;
    return slayer;
}
- (void)checkLineCount {
    if(self.lineCountChangedBlock){
        self.lineCountChangedBlock(self.canBack, self.canForward);
    }
}
- (CGRect)getRectWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGPoint orignal = startPoint;
    if (startPoint.x > endPoint.x) {
        orignal = endPoint;
    }
    CGFloat width = fabs(startPoint.x - endPoint.x);
    CGFloat height = fabs(startPoint.y - endPoint.y);
    return CGRectMake(orignal.x , orignal.y , width, height);
}
- (CGFloat)distanceBetweenStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGFloat xDist = (endPoint.x - startPoint.x);
    CGFloat yDist = (endPoint.y - startPoint.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}
- (UIBezierPath *)createArrowWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint {
    CGPoint controllPoint = CGPointZero;
    CGPoint pointUp = CGPointZero;
    CGPoint pointDown = CGPointZero;
    CGFloat distance = [self distanceBetweenStartPoint:startPoint endPoint:endPoint];
    CGFloat distanceX = self.brushTool.lineWidth*2 * (ABS(endPoint.x - startPoint.x) / distance);
    CGFloat distanceY = self.brushTool.lineWidth*2 * (ABS(endPoint.y - startPoint.y) / distance);
    CGFloat distX = self.brushTool.lineWidth * (ABS(endPoint.y - startPoint.y) / distance);
    CGFloat distY = self.brushTool.lineWidth * (ABS(endPoint.x - startPoint.x) / distance);
    if (endPoint.x >= startPoint.x)
    {
        if (endPoint.y >= startPoint.y)
        {
            controllPoint = CGPointMake(endPoint.x - distanceX, endPoint.y - distanceY);
            pointUp = CGPointMake(controllPoint.x + distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x - distX, controllPoint.y + distY);
        }
        else
        {
            controllPoint = CGPointMake(endPoint.x - distanceX, endPoint.y + distanceY);
            pointUp = CGPointMake(controllPoint.x - distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x + distX, controllPoint.y + distY);
        }
    }
    else
    {
        if (endPoint.y >= startPoint.y)
        {
            controllPoint = CGPointMake(endPoint.x + distanceX, endPoint.y - distanceY);
            pointUp = CGPointMake(controllPoint.x - distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x + distX, controllPoint.y + distY);
        }
        else
        {
            controllPoint = CGPointMake(endPoint.x + distanceX, endPoint.y + distanceY);
            pointUp = CGPointMake(controllPoint.x + distX, controllPoint.y - distY);
            pointDown = CGPointMake(controllPoint.x - distX, controllPoint.y + distY);
        }
    }
    NSLog(@"control %@",NSStringFromCGPoint(controllPoint));
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    [arrowPath moveToPoint:endPoint];
    [arrowPath addLineToPoint:pointDown];
    [arrowPath addLineToPoint:pointUp];
    [arrowPath addLineToPoint:endPoint];
    return arrowPath;
}



#pragma mark - Getter
- (BOOL)isDrawing {
    return _isWork;
}
- (BOOL)canForward {
    return self.brushTool.deleteLineArray.count;
}
- (BOOL)canBack {
    return self.brushTool.lineArray.count;
}
- (SLDrawBrushTool *)brushTool {
    if(!_brushTool){
        _brushTool = [[SLDrawBrushTool alloc] initWithDrawBounds:self.bounds];
    }
    return _brushTool;
}
#pragma mark - Event Handle
//前进
- (void)goForward {
    if ([self canForward]) {
        //添加刚删除的线条
        [self.layer addSublayer:self.brushTool.deleteLayerArray.lastObject];
        [self.brushTool.lineArray addObject:self.brushTool.deleteLineArray.lastObject];
        [self.brushTool.layerArray addObject:self.brushTool.deleteLayerArray.lastObject];
        //从删除池中除去
        [self.brushTool.deleteLayerArray removeLastObject];
        [self.brushTool.deleteLineArray removeLastObject];
        [self checkLineCount];
    }
}
//返回
- (void)goBack {
    if ([self canBack]) {
        //保存上一步删除的线条
        [self.brushTool.deleteLineArray addObject:self.brushTool.lineArray.lastObject];
        [self.brushTool.deleteLayerArray addObject:self.brushTool.layerArray.lastObject];
        //删除上一步
        [self.brushTool.layerArray.lastObject removeFromSuperlayer];
        [self.brushTool.layerArray removeLastObject];
        [self.brushTool.lineArray removeLastObject];
        [self checkLineCount];
    }
}
- (void)clear {
    [self.brushTool.layerArray removeAllObjects];
    [self.brushTool.lineArray removeAllObjects];
    [self.brushTool.deleteLayerArray removeAllObjects];
    [self.brushTool.deleteLineArray removeAllObjects];
    [self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
    [self checkLineCount];
}
///返回上一次画画的状态
- (void)goBackToLastDrawState {
    if(self.brushTool.lineArray.count == self.lastLinePathCount){
        return;
    }
    NSMutableArray * tempArr = [NSMutableArray arrayWithArray:self.brushTool.lineArray];
    [tempArr enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(SLDrawBezierPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.brushTool.layerArray.lastObject removeFromSuperlayer];
        [self.brushTool.layerArray removeLastObject];
        [self.brushTool.lineArray removeLastObject];
        if(self.brushTool.lineArray.count == self.lastLinePathCount){
            *stop = YES;
        }
    }];
    [self checkLineCount];
}

#pragma mark  - 数据
- (NSDictionary *)data {
    if (self.brushTool.lineArray.count) {
        return @{@"kSLDrawViewData":[self.brushTool.lineArray copy]};
    }
    return nil;
}
- (void)setData:(NSDictionary *)data {
    NSArray *lineArray = data[@"kSLDrawViewData"];
    if (lineArray.count) {
        for (SLDrawBezierPath *path in lineArray) {
            CAShapeLayer *slayer = [self createShapeLayer:path];
            [self.layer addSublayer:slayer];
            [self.brushTool.layerArray addObject:slayer];
        }
        [self.brushTool.lineArray addObjectsFromArray:lineArray];
    }
}
@end
