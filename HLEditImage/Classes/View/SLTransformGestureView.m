/*****头文件*********/

#import <UIKit/UIKit.h>


/*****实现文件*********/

#import "SLTransformGestureView.h"



@interface SLTransformGestureView ()<UIGestureRecognizerDelegate>
{
    
    UIImageView *_imageView;
    
}
// 编辑水平图片的数组
@property (nonatomic, strong) NSMutableArray *imageViews;
// 当前正在编辑的水印图片
@property (nonatomic, weak) UIView *currentEditintImageView;
// 删除按钮
@property (nonatomic, weak) UIButton *deleteBtn;
// 旋转缩放按钮
@property (nonatomic, weak) UIImageView *editBtn;
// 记录上一个触摸点
@property (nonatomic, assign) CGPoint previousPoint;
// 记录是否触发旋转缩放按钮
@property (nonatomic, assign, getter=isEditGusture) BOOL editGusture;
@property (nonatomic, strong) CAShapeLayer *dotBoarderLayer;

@end



@implementation SLTransformGestureView
#pragma mark - Getter

- (CAShapeLayer *)dotBoarderLayer {
    if(!_dotBoarderLayer){
        CAShapeLayer *layer = [[CAShapeLayer alloc] init];
        layer.lineWidth = 1;
        layer.strokeColor = [UIColor greenColor].CGColor;
        layer.fillColor = [UIColor clearColor].CGColor;
        layer.lineCap = kCALineCapRound;
        layer.lineJoin = kCALineJoinRound;
        layer.lineDashPattern = @[@4, @4];
        _dotBoarderLayer = layer;
    }
    return _dotBoarderLayer;
}
- (UIImageView *)imageView
{
    if (!_imageView) {
        UIImageView *imageView = [[UIImageView alloc] init];
        _imageView = imageView;
        [self insertSubview:imageView atIndex:0];
    }
    return _imageView;
}



- (UIButton *)deleteBtn
{
    if (!_deleteBtn) {
        UIButton *deleteBtn = [[UIButton alloc] init];
        [deleteBtn addTarget:self action:@selector(deleteBtnClick:) forControlEvents:UIControlEventTouchUpInside];
        [deleteBtn setImage:[UIImage imageNamed:@"icon_delete"] forState:UIControlStateNormal];
        deleteBtn.hidden = YES;
        [self addSubview:deleteBtn];
        _deleteBtn = deleteBtn;
    }
    return _deleteBtn;
}
- (UIImageView *)editBtn
{
    if (!_editBtn) {
        UIImageView *editBtn = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"EditDragRotate"]];
        editBtn.contentMode = UIViewContentModeCenter;
        editBtn.userInteractionEnabled = NO;
        editBtn.hidden = YES;
        editBtn.layer.zPosition = 10;
        [self addSubview:editBtn];
        _editBtn = editBtn;
    }
    return _editBtn;
}
- (NSMutableArray *)imageViews
{
    if (!_imageViews) {
        _imageViews = [NSMutableArray array];
    }
    return _imageViews;
    
}

#pragma mark - override

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

#pragma mark -UI
- (void)setup
{
    self.clipsToBounds = YES;
    // 添加手势
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:pan];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    pinch.delegate = self;
    [self addGestureRecognizer:pinch];
    
    UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotate:)];
    rotate.delegate = self;
    [self addGestureRecognizer:rotate];
    
}

#pragma mark -Gesture Handle
// 双指旋转
- (void)rotate:(UIRotationGestureRecognizer *)rotate
{
    if (!self.currentEditintImageView) {
        // 判断触摸点是否在水平图片上
        self.currentEditintImageView = [self imageViewInLocation:[rotate locationInView:self]];
        if (!self.currentEditintImageView) return; // 不在就直接return
    }
    //触摸点在水印图片上
    if (rotate.state == UIGestureRecognizerStateBegan) {
        // 正在编辑，先隐藏两个编辑按钮
        [self hideEditingBtn:YES];
        
    }else if (rotate.state == UIGestureRecognizerStateEnded) {
        if (!self.currentEditintImageView) return;
        // 结束编辑，显示两个编辑按钮
        [self hideEditingBtn:NO];
        
    }else {
        // 做旋转处理
        self.currentEditintImageView.transform = CGAffineTransformRotate(self.currentEditintImageView.transform, rotate.rotation);
        [rotate setRotation:0];
    }
    
    //    [self resetBorder];
    
}
- (void)pinch:(UIPinchGestureRecognizer *)pinch

{
    if (pinch.state == UIGestureRecognizerStateBegan) {
        UIImageView *imgView = [self imageViewInLocation:[pinch locationInView:self]];
        if (!self.currentEditintImageView && !imgView) return;
        if (imgView) {
            self.currentEditintImageView = imgView;
        }
        [self hideEditingBtn:YES];
    }else if (pinch.state == UIGestureRecognizerStateEnded) {
        if (!self.currentEditintImageView) return;
        [self hideEditingBtn:NO];
    }else {
        self.currentEditintImageView.transform = CGAffineTransformScale(self.currentEditintImageView.transform, pinch.scale, pinch.scale);
        [pinch setScale:1];
    }
    //    [self resetBorder];
}


- (void)tap:(UITapGestureRecognizer *)tap

{
    UIImageView *imgView = [self imageViewInLocation:[tap locationInView:self]];
    self.currentEditintImageView = imgView;
    [self hideEditingBtn:!imgView];
    //    [self resetBorder];
}



// 重点来了，此处涉及一些反三角函数计算，感觉又回到高中时代了。。。

- (void)pan:(UIPanGestureRecognizer *)pan
{
    //此处注意了，若要使用单指做旋转缩放，就必须要添加平移的手势了，通过平移手势偏移量计算对应的缩放比例以及旋转角度。。。。
    // 开始和结束处理跟上面手势一样。。
    if (pan.state == UIGestureRecognizerStateBegan) {
        UIImageView *imgView = [self imageViewInLocation:[pan locationInView:self]];
        if (!self.currentEditintImageView && !imgView) return;
        if (imgView) {
            self.currentEditintImageView = imgView;
        }
        CGPoint loc = [pan locationInView:self];
        self.editGusture = CGRectContainsPoint(self.editBtn.frame, loc);
        [self hideEditingBtn:YES];
        self.previousPoint = loc;
    }else if (pan.state == UIGestureRecognizerStateEnded) {
        if (!self.currentEditintImageView) return;
        [self hideEditingBtn:NO];
        self.previousPoint = [pan locationInView:self];
    }else {
        /***********此处是处理平移手势过程*********/
        if (self.isEditGusture) { // 由开始的触摸点判断是否触发旋转缩放按钮。。
            // 拖拽编辑按钮处理
            // 获得当前点
            CGPoint currentTouchPoint = [pan locationInView:self];
            // 当前编辑水印图片的中心点
            CGPoint center = self.currentEditintImageView.center;
            // 这句由当前点到中心点连成的线段跟上一个点到中心店连成的线段反算出偏移角度
            CGFloat angleInRadians = atan2f(currentTouchPoint.y - center.y, currentTouchPoint.x - center.x) - atan2f(self.previousPoint.y - center.y, self.previousPoint.x - center.x);
            // 计算出偏移角度之后就可以做对应的旋转角度啦
            CGAffineTransform t = CGAffineTransformRotate(self.currentEditintImageView.transform, angleInRadians);
            // 下面是计算缩放比例
            //1. 先计算两线段的长度。
            CGFloat previousDistance = [self distanceWithPoint:center otherPoint:self.previousPoint];
            CGFloat currentDistance = [self distanceWithPoint:center otherPoint:currentTouchPoint];
            //2.然后两长度的比值就是缩放比例啦，
            CGFloat scale = currentDistance / previousDistance;
            // 然后设置两者结合后的transform赋值给当前水平图片即可
            t = CGAffineTransformScale(t, scale, scale);
            self.currentEditintImageView.transform = t;
        }else {
            // 此处触发的是平移手势。。。
            if (!self.currentEditintImageView) return;
            CGPoint t = [pan translationInView:self.currentEditintImageView];
            self.currentEditintImageView.transform = CGAffineTransformTranslate(self.currentEditintImageView.transform, t.x, t.y);
            [pan setTranslation:CGPointZero inView:self.currentEditintImageView];
        }
        self.previousPoint = [pan locationInView:self];
        
        
        
    }
    
    //    [self resetBorder];
    
    
    
    //    CGRect rect = CGRectApplyAffineTransform(self.currentEditintImageView.frame, self.currentEditintImageView.transform);
    
    //    NSLog(@"%@", NSStringFromCGRect(rect));
    
}
#pragma mark -私有方法

// 传入一个点，判断点是否在水平图片上

- (UIImageView *)imageViewInLocation:(CGPoint)loc
{
    for (UIImageView *imgView in self.imageViews) {
        if (CGRectContainsPoint(imgView.frame, loc)) {
            [self bringSubviewToFront:imgView];
            return imgView;
        }
    }
    return nil;
}


- (void)hideEditingBtn:(BOOL)hidden

{
    self.deleteBtn.hidden = hidden;
    self.editBtn.hidden = hidden;
    self.dotBoarderLayer.hidden = hidden;
    if (!hidden) {
        self.dotBoarderLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.currentEditintImageView.bounds cornerRadius:0].CGPath;
        if(!self.dotBoarderLayer.superlayer || ![self.currentEditintImageView.layer.sublayers containsObject:self.dotBoarderLayer]){
            [self.currentEditintImageView.layer addSublayer:self.dotBoarderLayer];
        }
        self.editBtn.center = [self.currentEditintImageView convertPoint:CGPointMake(self.currentEditintImageView.bounds.size.width, self.currentEditintImageView.bounds.size.height) toView:self];
         self.deleteBtn.center = [self.currentEditintImageView convertPoint:CGPointMake(self.currentEditintImageView.bounds.size.width,0) toView:self];
    }
}

- (CGFloat)distanceWithPoint:(CGPoint)point otherPoint:(CGPoint)otherPoint
{
    return sqrt(pow(point.x - otherPoint.x, 2) + pow(point.y - otherPoint.y, 2));
}
#pragma mark -系统方法

- (void)layoutSubviews

{
    [super layoutSubviews];
    
    CGFloat btnWH = 40;
    
    self.deleteBtn.bounds = CGRectMake(0, 0, btnWH, btnWH);
    self.editBtn.bounds = CGRectMake(0, 0, btnWH, btnWH);
    if (self.imageView.image.size.width < self.frame.size.width && self.imageView.image.size.height < self.frame.size.height) {
        
        CGRect frame =  self.imageView.frame;
        frame.size = self.imageView.image.size;
        self.imageView.frame = frame;
        self.imageView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
        
    }else {
        CGFloat w = 0;
        
        CGFloat h = 0;
        if (self.imageView.image.size.width < self.imageView.image.size.height) {
            h = self.frame.size.height;
            w = h * self.imageView.image.size.width / self.imageView.image.size.height;
        }else {
            w = self.frame.size.width;
            h = w * self.imageView.image.size.height / self.imageView.image.size.width;
        }
        CGRect frame =  self.imageView.frame;
        frame.size = CGSizeMake(w, h);
        self.imageView.frame = frame;
        self.imageView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    }

}

#pragma mark -公共方法
- (void)addWatermarkImage:(UIImage *)watermarkImage
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:watermarkImage];
    imageView.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height * 0.5);
    [self addSubview:imageView];
    [self.imageViews addObject:imageView];
}
- (void)endEditing
{
    self.currentEditintImageView = nil;
    [self hideEditingBtn:YES];
    //    [self resetBorder];
}

#pragma mark- Event Handle
// 删除按钮点击
- (void)deleteBtnClick:(UIButton *)sender
{
    [self.currentEditintImageView removeFromSuperview];
    [self.imageViews removeObject:self.currentEditintImageView];
    self.currentEditintImageView = nil;
    [self hideEditingBtn:YES];
}


#pragma mark -UIGestureDelegate
//这个是手势代理，允许同时响应多个手势。。。这个不多说了。

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer

{
    return YES;
}


@end

