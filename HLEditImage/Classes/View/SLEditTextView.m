//
//  SLEditTextView.m
//  DarkMode
//
//  Created by wsl on 2019/10/17.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditTextView.h"
#import "UIView+SLFrame.h"
#import "SLUtilsMacro.h"
#import "SLPaddingLabel.h"
#import "NSString+SLLocalizable.h"

@interface SLEditTextViewMenuView: UIView
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, assign) NSInteger currentIndex; // 当前颜色索引
@property (nonatomic, strong) UIColor *currentColor; // 当前颜色
@property (nonatomic, assign) BOOL colorSwitch;  // 颜色开关 0：默认设置文本颜色  1：背景颜色
@property (nonatomic, strong) UIColor *currentTextColor;//当前文字颜色
@property (nonatomic, strong) UIColor *currentTextBgColor;//当前文字背景色
@property (nonatomic, assign) NSTextAlignment currentTextAlign;//当前文字布局
@property (nonatomic, strong) UIButton *textAlignBtn;//对齐按钮
@property (nonatomic, strong) UIButton *switchColorBtn;//切换颜色按钮

@property (nonatomic, copy) void (^colorChangedBlock)(UIColor *currentTextColor,UIColor *currentTextBgColor);
@property (nonatomic, copy) void (^textAlignChangedBlock)(NSTextAlignment textAlign);

@end
@implementation SLEditTextViewMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        _currentTextAlign = NSTextAlignmentLeft;
        NSArray *colors = @[kColorWithHex(0xF2F2F2), kColorWithHex(0x2B2B2B), kColorWithHex(0xFA5051), kColorWithHex(0xFFC300), kColorWithHex(0x04C160), kColorWithHex(0x11AEFF)];
        _colors = colors;
        _currentColor = _colors[0];
        _currentTextColor = _currentColor;
        _currentTextBgColor = [UIColor clearColor];
        [self setupUI];
    }
    return self;
}
- (void)setupUI {
    //对齐按钮
    UIButton * alignBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    alignBtn.frame = CGRectMake(0, 0, 50, self.frame.size.height);
    [alignBtn setImage:[UIImage imageNamed:@"EditTextAlignLeft"] forState:UIControlStateNormal];
    [alignBtn addTarget:self action:@selector(textAlignBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:alignBtn];
    self.textAlignBtn = alignBtn;
    //text按钮
    UIButton * switchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    switchBtn.frame = CGRectMake(50, 0, 50, self.frame.size.height);
    [switchBtn setImage:[UIImage imageNamed:@"EditMenuTextColor"] forState:UIControlStateNormal];
    [switchBtn setImage:[UIImage imageNamed:@"EditMenuTextBackgroundColor"] forState:UIControlStateSelected];
    [switchBtn addTarget:self action:@selector(colorSwitchBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:switchBtn];
    self.switchColorBtn = switchBtn;
    //分割线
    UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(120, (self.frame.size.height - 20)/2, 1, 20)];
    lineView.backgroundColor = [UIColor whiteColor];
    [self addSubview:lineView];
    
    //颜色按钮
    UIScrollView * scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(130, 0,self.frame.size.width - 130 , self.frame.size.height)];
    scrollView.alwaysBounceHorizontal = YES;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    [self addSubview:scrollView];
    [self addColorsBtnInView:scrollView];

}
- (void)reconfigUI {
    //对齐方式
    if(self.currentTextAlign == NSTextAlignmentCenter){
        [self.textAlignBtn setImage:[UIImage imageNamed:@"EditTextAlignCenter"] forState:UIControlStateNormal];
    }else if (self.currentTextAlign == NSTextAlignmentRight){
        [self.textAlignBtn setImage:[UIImage imageNamed:@"EditTextAlignRight"] forState:UIControlStateNormal];
    }else {
        [self.textAlignBtn setImage:[UIImage imageNamed:@"EditTextAlignLeft"] forState:UIControlStateNormal];
    }
    //颜色转换按钮
    if(CGColorEqualToColor(self.currentTextBgColor.CGColor, [UIColor clearColor].CGColor)){
        self.colorSwitch = NO;
        //背景色是透明的
        self.switchColorBtn.selected = NO;
        //颜色按钮
        for(UIColor *color in self.colors){
            if( CGColorEqualToColor(color.CGColor, self.currentTextColor.CGColor)){
                self.currentColor = color;
                NSInteger index = [self.colors indexOfObject:color];
                UIButton * colorBtn = [self viewWithTag:index+10];
                [self colorBtnClicked:colorBtn];
            }
        }

    }else {
        self.colorSwitch = YES;
        self.switchColorBtn.selected = YES;
        //有背景色
        //颜色按钮
        for(UIColor *color in self.colors){
            if( CGColorEqualToColor(color.CGColor, self.currentTextBgColor.CGColor)){
                self.currentColor = color;
                NSInteger index = [self.colors indexOfObject:color];
                UIButton * colorBtn = [self viewWithTag:index+10];
                [self colorBtnClicked:colorBtn];
            }
        }

    }
    
}
- (void)addColorsBtnInView:(UIScrollView *)view {
    NSInteger count = self.colors.count;
    CGSize itemSize = CGSizeMake(24, 24);
    CGFloat space = 22;
    for (NSInteger i = 0; i < count; i++) {
        UIButton * colorBtn = [[UIButton alloc] initWithFrame:CGRectMake(space + (itemSize.width + space)*i, (view.frame.size.height - itemSize.height)/2, itemSize.width, itemSize.height)];
        [view addSubview:colorBtn];
        colorBtn.backgroundColor = _colors[i];
        colorBtn.tag = 10 + i;
        [colorBtn addTarget:self action:@selector(colorBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        colorBtn.layer.cornerRadius = itemSize.width/2.0;
        colorBtn.layer.borderColor = [UIColor whiteColor].CGColor;
        if(_currentIndex == i) {
            colorBtn.layer.borderWidth = 2;
            colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 1.0f);
        }else {
            colorBtn.layer.borderWidth = 2;
            colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
        }
    }
    view.contentSize = CGSizeMake(count*(itemSize.width+space)+space, view.frame.size.height);

}

#pragma mark - Event Handle
- (void)textAlignBtnClicked:(UIButton *)btn {
    if(self.currentTextAlign == NSTextAlignmentLeft){
        self.currentTextAlign = NSTextAlignmentCenter;
        [btn setImage:[UIImage imageNamed:@"EditTextAlignCenter"] forState:UIControlStateNormal];
    }else if (self.currentTextAlign == NSTextAlignmentCenter){
        self.currentTextAlign = NSTextAlignmentRight;
        [btn setImage:[UIImage imageNamed:@"EditTextAlignRight"] forState:UIControlStateNormal];
    }else {
        self.currentTextAlign = NSTextAlignmentLeft;
        [btn setImage:[UIImage imageNamed:@"EditTextAlignLeft"] forState:UIControlStateNormal];
    }
    if(self.textAlignChangedBlock){
        self.textAlignChangedBlock(self.currentTextAlign);
    }
}
- (void)colorSwitchBtnClicked:(UIButton *)btn {
    _colorSwitch = !_colorSwitch;
    btn.selected = _colorSwitch;
    if (_colorSwitch) {
        if(_currentIndex == 0){//选中的白色
            self.currentTextColor = self.colors[1];
            self.currentTextBgColor = self.colors[0];
        }else {
            self.currentTextColor = self.colors[0];
            self.currentTextBgColor = _currentColor;
        }
    }else {
        self.currentTextColor = _currentColor;
        self.currentTextBgColor = [UIColor clearColor];
    }
    if(self.colorChangedBlock){
        self.colorChangedBlock(self.currentTextColor, self.currentTextBgColor);
    }
}
- (void)colorBtnClicked:(UIButton *)colorBtn {
    UIButton *previousBtn = (UIButton *)[self viewWithTag:(10 + _currentIndex)];
    previousBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
    previousBtn.layer.borderWidth = 2;
    colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    colorBtn.layer.borderWidth = 2;
    _currentIndex = (int)colorBtn.tag- 10;
    _currentColor = colorBtn.backgroundColor;
    if (_colorSwitch) {
        self.currentTextBgColor = colorBtn.backgroundColor;
        if(_currentIndex == 0){//选中的白色
            self.currentTextColor = self.colors[1];
        }else {
            self.currentTextColor = self.colors[0];
        }
    }else {
        self.currentTextBgColor = [UIColor clearColor];
        self.currentTextColor = colorBtn.backgroundColor;
    }
    if(self.colorChangedBlock){
        self.colorChangedBlock(self.currentTextColor, self.currentTextBgColor);
    }

}
@end

#define kTextViewPaddingleft 10
@interface SLEditTextView ()<UITextViewDelegate>
{
    CGFloat _keyboardHeight;
}
@property (nonatomic, strong) UIButton *cancelEditBtn; //取消编辑
@property (nonatomic, strong) UIButton *doneEditBtn; //完成编辑
@property (nonatomic, strong) UITextView *textView;  //文本输入
@property (nonatomic, strong) SLEditTextViewMenuView *menuView;//菜单栏
@end

@implementation SLEditTextView

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        [self setupUI];
    }
    return self;
}
- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (self.superview != nil) {
        [self.textView becomeFirstResponder];
    }
}
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - UI
- (void)setupUI {
    [self addSubview:self.textView];
    __weak typeof(self) weakSelf = self;
    self.configureEditParameters = ^(NSDictionary * _Nonnull parameters) {
        weakSelf.menuView.currentTextColor = parameters[@"textColor"];
        weakSelf.menuView.currentTextBgColor = parameters[@"backgroundColor"];
        weakSelf.menuView.currentTextAlign = [parameters[@"textAlignment"] integerValue];
        [weakSelf.menuView reconfigUI];
        weakSelf.textView.text = parameters[@"text"];
        weakSelf.textView.textAlignment = weakSelf.menuView.currentTextAlign;
        [weakSelf textViewDidChange:weakSelf.textView];
    };
    [self addSubview:self.cancelEditBtn];
    [self addSubview:self.doneEditBtn];
    //监听键盘frame改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    //添加键盘消失监听事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)configTextViewFrame {
    CGFloat maxHeight = self.sl_height - 64 - _keyboardHeight -  50;
    CGFloat maxW = self.sl_width - kTextViewPaddingleft*2;
    CGSize contentSize = [self.textView sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    CGFloat height = contentSize.height;
    if(height > maxHeight){
        height = maxHeight;
    }else if ( height < 45){
        height = 45;
    }
    CGPoint center = CGPointMake( self.frame.size.width/2.f ,(self.sl_height - 64 - _keyboardHeight -  50)/2.f + 64);
    CGRect newFrame = CGRectMake(kTextViewPaddingleft, 0, maxW, height);
    self.textView.frame = newFrame;
    self.textView.center = center;
}
#pragma mark - Getter
- (UIButton *)cancelEditBtn {
    if (_cancelEditBtn == nil) {
        _cancelEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 20, 50, 22)];
        [_cancelEditBtn setTitle:kNSLocalizedString(@"取消") forState:UIControlStateNormal];
        _cancelEditBtn.contentMode = UIViewContentModeLeft;
        [_cancelEditBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _cancelEditBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [_cancelEditBtn addTarget:self action:@selector(cancelEditBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelEditBtn;
}
- (UIButton *)doneEditBtn {
    if (_doneEditBtn == nil) {
        UIButton *doneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        doneBtn.backgroundColor = kColorWithHex(0xFE7B1A);
        [doneBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [doneBtn setTitle:kNSLocalizedString(@"完成") forState:UIControlStateNormal];
        doneBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        doneBtn.layer.cornerRadius = 3;
        doneBtn.clipsToBounds = YES;
        [doneBtn addTarget:self action:@selector(doneEditBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:doneBtn];
        doneBtn.frame =  CGRectMake(self.sl_width - 60 - 15, 17, 60, 30);
        _doneEditBtn = doneBtn;
    }
    return _doneEditBtn;
}
- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(kTextViewPaddingleft, 130, self.frame.size.width - kTextViewPaddingleft*2, 45)];
        CGPoint center = CGPointMake(self.sl_width/2.f, (self.sl_height - 64 - _keyboardHeight -  50)/2.f + 64);
        _textView.center = center;
        _textView.backgroundColor = self.menuView.currentTextBgColor;
        _textView.textColor = self.menuView.currentTextColor;
        _textView.textAlignment = self.menuView.currentTextAlign;
        _textView.scrollEnabled = NO;
        _textView.delegate = self;
        _textView.clipsToBounds = NO;
        _textView.keyboardAppearance = UIKeyboardAppearanceDark;
        _textView.tintColor = kColorWithHex(0x3297FC);
        _textView.returnKeyType = UIReturnKeyDone;
        _textView.font = [UIFont systemFontOfSize:32];
        _textView.textContainerInset = UIEdgeInsetsMake(5, 10, 5, 10);
        _textView.layer.cornerRadius = 10;

    }
    return _textView;
}
- (SLEditTextViewMenuView *)menuView {
    if(!_menuView) {
        _menuView = [[SLEditTextViewMenuView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 50)];
        WS(weakSelf);
        _menuView.colorChangedBlock = ^(UIColor *currentTextColor, UIColor *currentTextBgColor) {
            weakSelf.textView.textColor = currentTextColor;
            weakSelf.textView.backgroundColor = currentTextBgColor;
        };
        _menuView.textAlignChangedBlock = ^(NSTextAlignment textAlign) {
            weakSelf.textView.textAlignment = textAlign;
        };
    }
    return _menuView;
}
#pragma mark - Help Methods
// 返回一个文本水印视图
- (UILabel *)copyTextView:(UITextView *)textView {
    if(![textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length){
        //只有空格时候不显示
        return nil;
    }
    
    CGRect rect = textView.bounds;
    CGSize contentSize = [self.textView sizeThatFits:CGSizeMake(CGFLOAT_MAX, 50)];
    
    if(contentSize.width < rect.size.width){
        rect.size.width = contentSize.width;
    }
    SLPaddingLabel *label = [[SLPaddingLabel alloc] initWithFrame:rect];
//    label.scrollEnabled = NO;
//    label.editable = NO;
    label.userInteractionEnabled = YES;
    label.textAlignment = textView.textAlignment;
    label.font = textView.font;
    label.layer.backgroundColor = textView.backgroundColor.CGColor;
    label.layer.cornerRadius =textView.layer.cornerRadius;
    label.textPadding = textView.textContainerInset;
    label.numberOfLines = 0;
    label.text = textView.text;
    label.textColor = textView.textColor;

    return label;
}

#pragma mark - EventsHandle
//取消编辑
- (void)cancelEditBtnClicked:(id)sender {
    [self.textView resignFirstResponder];
    if (self.editTextCompleted) {
        self.editTextCompleted(nil);
    }
    [self removeFromSuperview];
}
//完成编辑
- (void)doneEditBtnClicked:(id)sender {
    [self.textView resignFirstResponder];
    if (self.editTextCompleted) {
        self.editTextCompleted([self copyTextView:self.textView]);
    }
    [self removeFromSuperview];
}
//键盘即将弹出
- (void)keyboardWillShow:(NSNotification *)notification {
    //获取键盘高度 keyboardHeight
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    _keyboardHeight = keyboardRect.size.height;
    self.menuView.sl_y = self.sl_height - _keyboardHeight - 50 - 10;
    if(!self.menuView.superview){
        [self addSubview:self.menuView];
    }
    [self configTextViewFrame];
}
//键盘即将消失
- (void)keyboardWillHide:(NSNotification *)notification{
    [self.textView resignFirstResponder];
    [self removeFromSuperview];
}
#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString * string = [textView.text stringByReplacingCharactersInRange:range withString:text];
    CGFloat maxHeight = self.sl_height - 64 - _keyboardHeight -  50;
    ;
    CGFloat height = [string boundingRectWithSize:CGSizeMake(textView.sl_width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : textView.font} context:nil].size.height + 12;
    if( height > maxHeight){
        //防止输入光标跳到起始位置
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            textView.selectedRange = NSMakeRange(textView.text.length, 0);
        });
        return NO;
    }
    if([text isEqualToString:@"\n"]){
        [self doneEditBtnClicked:nil];
        return NO;
    }
    return YES;
}
-(void)textViewDidChange:(UITextView *)textView{
    self.textView.textColor = self.menuView.currentTextColor;
    self.textView.backgroundColor = self.menuView.currentTextBgColor;
    [self configTextViewFrame];
}
@end
