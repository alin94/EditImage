//
//  SLDrawView.m
//  DarkMode
//
//  Created by wsl on 2019/10/12.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLDrawView.h"
#import "UIImage+SLCommon.h"
#import "UIView+SLFrame.h"
#import "SLMaskLayer.h"


@interface SLShapelayer : CAShapeLayer
@property (nonatomic, assign) SLDrawShapeType shapeType;//类型
@property (nonatomic, assign) BOOL isErase;//是否是橡皮檫
@property (nonatomic, assign) CGPoint beginPoint;
@property (nonatomic, assign) CGPoint endPoint;


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

@end
@implementation SLDrawBrushTool
- (instancetype)initWithDrawBounds:(CGRect)bounds {
    self = [self init];
    if(self){
        self.drawBounds = bounds;
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
        _lineWidthIndex = 2;
        _lineColor = [UIColor blackColor];
        _shapeType = SLDrawShapeRandom;
    }
    return self;
}
///设置画笔图案
- (void)setPatternImage:(UIImage *)image drawRect:(CGRect)rect {
    UIGraphicsBeginImageContextWithOptions(self.viewBounds.size, NO, [UIScreen mainScreen].scale);
    //获得当前Context
    CGContextRef context = UIGraphicsGetCurrentContext();
    //CTM变换，调整坐标系，*重要*，否则橡皮擦使用的背景图片会发生翻转。
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -self.viewBounds.size.height);
    [image drawInRect:rect];
    //获取拉伸并翻转后的图片
    UIImage *stretchedImg = UIGraphicsGetImageFromCurrentImageContext();
    _image = stretchedImg;
    UIGraphicsEndImageContext();
}

- (void)setSquareWidth:(CGFloat)squareWidth {
    if(_squareWidth != squareWidth){
        _squareWidth = squareWidth;
        if (_image){
            _mosicImage = [_image sl_transToMosaicImageWithBlockLevel:squareWidth*4];
        }
    }
}

@end

@interface SLDrawView ()
{
    BOOL _isWork;
    BOOL _isBegan;
}
@property (nonatomic, assign) CGPoint beginPoint;
@property (nonatomic, assign) NSInteger lastLinePathCount;//之前的路径总数
@property (nonatomic, strong) SLMaskLayer *maskLayer;//遮挡住不需要显示的区域
@end
@implementation SLDrawView

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _enableDraw = YES;
        _superViewZoomScale = 1;
        _shapeViewSuperView = self;
        self.backgroundColor = [UIColor whiteColor];
        self.clipsToBounds = YES;
        self.exclusiveTouch = YES;
        self.userInteractionEnabled = YES;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _maskLayer.frame = self.bounds;
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self checkLineCount];
}
#pragma mark - setter
///是否在画图形
- (BOOL)isDrawingShapeView {
    if(self.brushTool.shapeType == SLDrawShapeRandom || self.brushTool.shapeType == SLDrawShapeMosic || self.brushTool.isErase){
        return NO;
    }
    return YES;
}
- (void)setEnableDraw:(BOOL)enableDraw {
    if(_enableDraw != enableDraw){
        _enableDraw = enableDraw;
        if(enableDraw){
            self.lastLinePathCount = self.brushTool.lineArray.count;
            [self.tempShapeViewArray removeAllObjects];
        }
        self.userInteractionEnabled = enableDraw;
    }
}
- (void)setDisplayRect:(CGRect)displayRect {
    _displayRect = displayRect;
    if(!self.maskLayer.superlayer){
        [self.layer insertSublayer:self.maskLayer atIndex:1000];
    }
    self.maskLayer.maskRect = displayRect;
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
        if(![self isDrawingShapeView]){
            [path moveToPoint:point];
        }
        //清理已删除的笔画
        [self.brushTool.deleteLayerArray removeAllObjects];
        [self.brushTool.deleteLineArray removeAllObjects];
        SLShapelayer *slayer = [self createShapeLayer:path];
        if([self isDrawingShapeView]){
            //画图形
            slayer.endPoint = slayer.beginPoint;
            UIView *shapeView = [self createViewWithShapeLayer:slayer];
            [self.shapeViewSuperView addSubview:shapeView];
            [self.tempShapeViewArray addObject:shapeView];
        }else {
            [self.brushTool.lineArray addObject:path];
            [self.layer insertSublayer:slayer below:self.maskLayer];
            [self.brushTool.layerArray addObject:slayer];
        }
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
            if(![self isDrawingShapeView]){
                [path addLineToPoint:point];
            }else{
                //图形
                UIView *lastShapeView = self.tempShapeViewArray.lastObject;
                SLShapelayer *slayer = (SLShapelayer *)                lastShapeView.layer.sublayers.firstObject;
                slayer.endPoint = point;
                [self layoutShapeView:lastShapeView withShapeLayer:slayer];

                if (self.brushTool.shapeType == SLDrawShapeEllipse){
                    path = [SLDrawBezierPath bezierPathWithOvalInRect:lastShapeView.bounds];
                }
                else if (self.brushTool.shapeType == SLDrawShapeRect){
                    path = [SLDrawBezierPath bezierPathWithRect:lastShapeView.bounds];
                }else if (self.brushTool.shapeType == SLDrawShapeArrow){
                    path = [[SLDrawBezierPath alloc] init];
                    CGPoint newBeginPoint = [self convertPoint:self.beginPoint toView:lastShapeView];
                    CGPoint newEndPoint = [self convertPoint:point toView:lastShapeView];
                    [path appendPath:[self createArrowWithBeginPoint:newBeginPoint endPoint:newEndPoint]];
                    [path closePath];
                }
            }
            //重新设置属性
            if(self.brushTool.shapeType != SLDrawShapeRandom){
                path.color = self.brushTool.lineColor;//保存线条当前颜色
                path.lineWidth = self.brushTool.lineWidth;
                if(![self isDrawingShapeView]) {
                    [self.brushTool.lineArray replaceObjectAtIndex:self.brushTool.lineArray.count - 1 withObject:path];
                }
            }
            if([self isDrawingShapeView]){
                UIView *lastShapeView = self.tempShapeViewArray.lastObject;
                SLShapelayer *slayer = (SLShapelayer *)                lastShapeView.layer.sublayers.firstObject;
                slayer.path = path.CGPath;
            }else {
                SLShapelayer *slayer = (SLShapelayer *)self.brushTool.layerArray.lastObject;
                slayer.path = path.CGPath;
            }
        }
    }
    [super touchesMoved:touches withEvent:event];
}
//结束绘画
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    if (_isWork) {
        if(self.drawShapeViewFinishedBlock && [self isDrawingShapeView]){
            UIView *shapeView = self.tempShapeViewArray.lastObject;
            if(shapeView){
                self.drawShapeViewFinishedBlock(shapeView,shapeView.layer.sublayers.firstObject);
            }
        }
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
- (UIView *)createViewWithShapeLayer:(SLShapelayer *)slayer{
    if(slayer.shapeType != SLDrawShapeRandom && slayer.shapeType != SLDrawShapeMosic && !self.brushTool.isErase){
        CGRect rect =  [self getRectWithStartPoint:slayer.beginPoint endPoint:slayer.endPoint];
        slayer.backgroundColor = [UIColor clearColor].CGColor;
        UIView *view = [[UIView alloc] initWithFrame:rect];
        [view.layer addSublayer:slayer];
        return view;
    }
    return nil;
}
- (void)layoutShapeView:(UIView *)view withShapeLayer:(SLShapelayer *)slayer {
    CGRect rect = [self getRectWithStartPoint:slayer.beginPoint endPoint:slayer.endPoint];
    view.frame = rect;
}
//创建线条图层
- (SLShapelayer *)createShapeLayer:(SLDrawBezierPath *)path {
    /** 1、渲染快速。CAShapeLayer使用了硬件加速，绘制同一图形会比用Core Graphics快很多。Core Graphics实现示例： https://github.com/wsl2ls/Draw.git
     2、高效使用内存。一个CAShapeLayer不需要像普通CALayer一样创建一个寄宿图形，所以无论有多大，都不会占用太多的内存。
     3、不会被图层边界剪裁掉。
     4、不会出现像素化。 */
    SLShapelayer *slayer = [SLShapelayer layer];
    slayer.path = path.CGPath;
    slayer.backgroundColor = [UIColor clearColor].CGColor;
    if(self.brushTool.shapeType == SLDrawShapeArrow && !self.brushTool.isErase){
        slayer.fillColor = path.color.CGColor;
        slayer.lineWidth = 0.1;
    }else {
        slayer.fillColor = [UIColor clearColor].CGColor;
        slayer.lineCap = kCALineCapRound;
        slayer.lineJoin = kCALineJoinRound;
        //缩放画笔大小
        CGFloat transScale = self.sl_scaleX*self.superViewZoomScale;
        slayer.lineWidth = path.lineWidth/transScale;
    }
    slayer.strokeColor = path.color.CGColor;
    
    //自定义路径的描述
    slayer.shapeType = self.brushTool.shapeType;
    slayer.isErase = self.brushTool.isErase;
    slayer.beginPoint = self.beginPoint;
    return slayer;
}
- (CGRect)getRectWithStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGRect rect = CGRectMake(MIN(startPoint.x, endPoint.x), MIN(startPoint.y, endPoint.y), fabs(startPoint.x - endPoint.x), fabs(startPoint.y - endPoint.y));
    return rect;
}
- (CGFloat)distanceBetweenStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint
{
    CGFloat xDist = (endPoint.x - startPoint.x);
    CGFloat yDist = (endPoint.y - startPoint.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}
- (CGFloat)angleBetweenStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint{
    CGFloat height = endPoint.y - startPoint.y;
    CGFloat width = startPoint.x - endPoint.x;
    CGFloat rads = atan(height/width);
    return rads;
}
//创建箭头
- (UIBezierPath *)createArrowWithBeginPoint:(CGPoint)beginPoint endPoint:(CGPoint)endPoint {
    //箭头的角度
    CGFloat arrowAngle = 70*M_PI/180.f;
    //箭头腰长
    CGFloat arrowWaistLength = 34.f;
    //箭头空白地儿宽度
    CGFloat arrowGapWidth = 10.f;
    //起点圆角半径
    CGFloat radius = 1.7;
    //当前画笔大小索引
    NSInteger arrowSizeIndex = self.brushTool.lineWidthIndex;
    if(arrowSizeIndex == 0){
        arrowWaistLength = 20.f;
        arrowGapWidth = 6.f;
        radius = 1.f;
    }else if (arrowSizeIndex == 1){
        arrowWaistLength = 26.f;
        arrowGapWidth = 8.f;
        radius = 1.4;
    }else if (arrowSizeIndex == 2){
        arrowWaistLength = 34.f;
        arrowGapWidth = 10.f;
        radius = 1.7;
    }else if (arrowSizeIndex == 3){
        arrowWaistLength = 48.f;
        arrowGapWidth = 14.f;
        radius = 2.4f;
    }else if (arrowSizeIndex == 4){
        arrowWaistLength = 66.f;
        arrowGapWidth = 20.f;
        radius = 3.5f;
    }
    //缩放箭头大小
    CGFloat zoomScale = self.sl_scaleX*self.superViewZoomScale;
    arrowWaistLength = arrowWaistLength/zoomScale;
    arrowGapWidth = arrowGapWidth/zoomScale;
    radius = radius/zoomScale;
    
    CGPoint point2 = CGPointZero;//左边内角
    CGPoint point3 = CGPointZero;//左边外角
    CGPoint point4 = endPoint;//终点
    CGPoint point5 = CGPointZero;//右边外角
    CGPoint point6 = CGPointZero;//右边内角
    //水平夹角
    CGFloat lineAngle = [self angleBetweenStartPoint:beginPoint endPoint:endPoint];
    //箭头底边长
    CGFloat arrowBottomLength = arrowWaistLength*sin(arrowAngle/2.f)*2;
    
    //箭头垂直高度
    CGFloat arrowVerticalLenght = arrowWaistLength *cos(arrowAngle/2.f);
    
    //图形最小长度
    CGFloat minLength = 12/zoomScale + arrowVerticalLenght;
    
    if([self distanceBetweenStartPoint:beginPoint endPoint:endPoint] < minLength){
        //尾巴长度小于这个长度
        if(endPoint.x > beginPoint.x){
            endPoint = CGPointMake(beginPoint.x + minLength* cos(lineAngle) , beginPoint.y - minLength*sin(lineAngle));
        }else {
            endPoint = CGPointMake(beginPoint.x - minLength* cos(lineAngle) , beginPoint.y + minLength*sin(lineAngle));
        }
        point4 = endPoint;
    }

    //箭头垂直中心点
    CGPoint arrowGapCenter = CGPointZero;
    if(endPoint.x > beginPoint.x){
        arrowGapCenter = CGPointMake(endPoint.x - arrowVerticalLenght*cos(lineAngle), endPoint.y + arrowVerticalLenght*sin(lineAngle));
    }else {
        arrowGapCenter = CGPointMake(endPoint.x + arrowVerticalLenght*cos(lineAngle), endPoint.y - arrowVerticalLenght*sin(lineAngle));
    }
    //两个箭头左右尖端
    point5 = CGPointMake(arrowGapCenter.x+ arrowBottomLength/2.f*sin(lineAngle), arrowGapCenter.y + arrowBottomLength/2.f*cos(lineAngle));
    point3 = CGPointMake(arrowGapCenter.x- arrowBottomLength/2.f*sin(lineAngle), arrowGapCenter.y - arrowBottomLength/2.f*cos(lineAngle));
    
    //两个箭头内角
    point6 = CGPointMake(arrowGapCenter.x+ arrowGapWidth/2.f*sin(lineAngle), arrowGapCenter.y + arrowGapWidth/2.f*cos(lineAngle));
    point2 = CGPointMake(arrowGapCenter.x- arrowGapWidth/2.f*sin(lineAngle), arrowGapCenter.y - arrowGapWidth/2.f*cos(lineAngle));
    
    UIBezierPath *path = [[UIBezierPath alloc] init];
    path.lineWidth = 1;
    //底部半圆弧形
    if(endPoint.x > beginPoint.x){
        CGPoint arcCenter = CGPointMake(beginPoint.x + radius*cos(lineAngle), beginPoint.y - radius*sin(lineAngle));
        [path addArcWithCenter:arcCenter radius:radius startAngle:M_PI_2 - lineAngle endAngle:M_PI_2 - lineAngle + M_PI clockwise:YES];
    }else {
        CGPoint arcCenter = CGPointMake(beginPoint.x - radius*cos(lineAngle), beginPoint.y + radius*sin(lineAngle));
        [path addArcWithCenter:arcCenter radius:radius startAngle:M_PI_2 - lineAngle endAngle:M_PI_2 - lineAngle + M_PI clockwise:NO];
    }
    [path addLineToPoint:point2];
    [path addLineToPoint:point3];
    [path addLineToPoint:point4];
    [path addLineToPoint:point5];
    [path addLineToPoint:point6];
    [path closePath];
    return path;
}
//检查线条数量
- (void)checkLineCount {
    if(self.lineCountChangedBlock){
        self.lineCountChangedBlock(self.canBack, self.canForward);
    }
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
- (SLMaskLayer *)maskLayer {
    if(!_maskLayer){
        _maskLayer = [[SLMaskLayer alloc] init];
        _maskLayer.frame = self.bounds;
        _maskLayer.maskColor = [UIColor blackColor].CGColor;
    }
    return _maskLayer;
}
- (NSMutableArray *)tempShapeViewArray {
    if(!_tempShapeViewArray){
        _tempShapeViewArray = [NSMutableArray array];
    }
    return _tempShapeViewArray;
}
#pragma mark - Event Handle
//前进
- (void)goForward {
    if ([self canForward]) {
        //添加刚删除的线条
        [self.layer insertSublayer:self.brushTool.deleteLayerArray.lastObject below:self.maskLayer];
//        [self.layer addSublayer:self.brushTool.deleteLayerArray.lastObject];
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
- (void)hideMaskLayer:(BOOL)hide {
    self.maskLayer.hidden = hide;
}
///获取画板视图图片
- (UIImage *)getDrawViewRenderImage {
    CGRect viewBounds = self.bounds;
    //先转换坐标系 绘制成一张倒立的图片
    UIGraphicsBeginImageContextWithOptions(viewBounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -viewBounds.size.height);
    //防止留黑边
    self.maskLayer.hidden = YES;
    [self.layer renderInContext:context];
    self.maskLayer.hidden = NO;
    UIImage *stretchedImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //再转换回来重新绘制成正常
    UIGraphicsBeginImageContextWithOptions(viewBounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context1 = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context1, 1, -1);
    CGContextTranslateCTM(context1, 0, -viewBounds.size.height);
    [stretchedImg drawInRect:viewBounds];
    stretchedImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return stretchedImg;
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
//            [self.layer addSublayer:slayer];
            [self.layer insertSublayer:slayer below:self.maskLayer];
            [self.brushTool.layerArray addObject:slayer];
        }
        [self.brushTool.lineArray addObjectsFromArray:lineArray];
    }
}
@end
