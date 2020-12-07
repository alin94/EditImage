//
//  SLEditTextView.m
//  DarkMode
//
//  Created by wsl on 2019/10/17.
//  Copyright © 2019 wsl. All rights reserved.
//

#import "SLEditTextView.h"
#import "UIView+SLFrame.h"
#import "SLRoundCornerTextView.h"
#import "SLRoundCornerLabel.h"
#import "SLUtilsMacro.h"

@interface SLEditTextView ()<UITextViewDelegate>
{
    CGFloat _keyboardHeight;
}
@property (nonatomic, strong) UIButton *cancelEditBtn; //取消编辑
@property (nonatomic, strong) UIButton *doneEditBtn; //完成编辑
@property (nonatomic, strong) SLRoundCornerTextView *textView;  //文本输入
@property (nonatomic, strong) NSArray *colors;  //颜色集合

@property (nonatomic, assign) NSInteger currentIndex; // 当前颜色索引
@property (nonatomic, strong) UIColor *currentColor; // 当前颜色
@property (nonatomic, assign) BOOL colorSwitch;  // 颜色开关 0：默认设置文本颜色  1：背景颜色
@property (nonatomic, strong) UIColor *currentTextColor;//当前文字颜色
@property (nonatomic, strong) UIColor *currentTextBgColor;//当前文字背景色
@property (nonatomic, strong) NSParagraphStyle *textStyle;

@end

@implementation SLEditTextView

#pragma mark - Override
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        _currentColor = [UIColor whiteColor];
        _currentTextColor = [UIColor whiteColor];
        _currentTextBgColor = [UIColor clearColor];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = -15;
        style.firstLineHeadIndent = 10;
        style.headIndent = 10;
        style.tailIndent = -10;
        style.minimumLineHeight = 50;
        _textStyle = style;
        _currentIndex = 0;
        _colors = @[kColorWithHex(0xF2F2F2), kColorWithHex(0x2B2B2B), kColorWithHex(0xFA5051), kColorWithHex(0xFFC300), kColorWithHex(0x04C160), kColorWithHex(0x11AEFF), kColorWithHex(0x6467F0), [UIColor clearColor]];
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
        weakSelf.currentTextColor = parameters[@"textColor"];
        weakSelf.currentTextBgColor = parameters[@"backgroundColor"];
        weakSelf.textView.text = parameters[@"text"];
        weakSelf.currentColor = weakSelf.textView.textColor;
        for (UIColor *color in weakSelf.colors) {
            if (CGColorEqualToColor(color.CGColor, weakSelf.currentColor.CGColor)) {
                weakSelf.currentIndex = (NSInteger)[weakSelf.colors indexOfObject:color];
            }
        }
        [weakSelf textViewDidChange:weakSelf.textView];
    };
    [self addSubview:self.cancelEditBtn];
    [self addSubview:self.doneEditBtn];
    //监听键盘frame改变
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    //添加键盘消失监听事件
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
//颜色选择菜单视图
- (void)colorSelectionView:(CGFloat)keyboardHeight {
    for (UIView *subView in self.subviews) {
        if (subView != self.doneEditBtn || subView != self.cancelEditBtn || subView != self.textView) {
            continue;
        }
        [subView removeFromSuperview];
    }
    NSInteger count = _colors.count + 1;
    CGSize itemSize = CGSizeMake(24, 24);
    CGFloat space = (self.frame.size.width - count * itemSize.width)/(count + 1);
    for (NSInteger i = 0; i < count; i++) {
        UIButton * colorBtn = [[UIButton alloc] initWithFrame:CGRectMake(space + (itemSize.width + space)*i, self.sl_height - keyboardHeight - 20 - 20, itemSize.width, itemSize.height)];
        [self addSubview:colorBtn];
        if (i == 0) {
            [colorBtn addTarget:self action:@selector(colorSwitchBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuTextColor"] forState:UIControlStateNormal];
            [colorBtn setImage:[UIImage imageNamed:@"EditMenuTextBackgroundColor"] forState:UIControlStateSelected];
        }else {
            colorBtn.backgroundColor = _colors[(i - 1)];
            colorBtn.tag = 10 + (i - 1);
            [colorBtn addTarget:self action:@selector(textColorBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
            colorBtn.layer.cornerRadius = itemSize.width/2.0;
            colorBtn.layer.borderColor = [UIColor whiteColor].CGColor;
            if(_currentIndex == (i - 1)) {
                colorBtn.layer.borderWidth = 4;
                colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0f, 1.0f);
            }else {
                colorBtn.layer.borderWidth = 2;
                colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
            }
        }
    }
}
- (NSAttributedString *)getAttStr {
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString: self.textView.text attributes:@{NSForegroundColorAttributeName:self.currentTextColor,NSFontAttributeName:[UIFont systemFontOfSize:32],NSParagraphStyleAttributeName:self.textStyle}];
    return attr;
}
- (void)configTextViewFrame {
    CGFloat maxHeight = self.sl_height - 64 - _keyboardHeight -  50;
    CGFloat maxW = self.sl_width - 5*2;
    CGSize contentSize = [self.textView sizeThatFits:CGSizeMake(maxW, CGFLOAT_MAX)];
    CGFloat height = contentSize.height + 16;
    CGFloat w = contentSize.width + 10*2 + 10*2;
    if(w > maxW){
        w = maxW;
    }
    if(height > maxHeight){
        height = maxHeight;
    }else if ( height < 56){
        height = 56;
    }
    CGPoint center = CGPointMake( 5 + w/2.f, (self.sl_height - 64 - _keyboardHeight -  50)/2.f + 64);
    CGRect newFrame = CGRectMake(5, 0, w, height);
    self.textView.frame = newFrame;
    self.textView.center = center;
}
#pragma mark - Getter
- (UIButton *)cancelEditBtn {
    if (_cancelEditBtn == nil) {
        _cancelEditBtn = [[UIButton alloc] initWithFrame:CGRectMake(15, 20, 50, 22)];
        [_cancelEditBtn setTitle:@"取消" forState:UIControlStateNormal];
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
        [doneBtn setTitle:NSLocalizedString(@"完成", @"") forState:UIControlStateNormal];
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
- (SLRoundCornerTextView *)textView {
    if (!_textView) {
        _textView = [[SLRoundCornerTextView alloc] initWithFrame:CGRectMake(5, 130, self.frame.size.width - 5*2, 56)];
        CGPoint center = CGPointMake(self.sl_width/2.f, (self.sl_height - 64 - _keyboardHeight -  50)/2.f + 64);
        _textView.center = center;
        _textView.backgroundColor = [UIColor clearColor];
        _textView.scrollEnabled = NO;
        _textView.delegate = self;
        _textView.clipsToBounds = NO;
        _textView.keyboardAppearance = UIKeyboardAppearanceDark;
        _textView.tintColor = kColorWithHex(0x3297FC);
        _textView.returnKeyType = UIReturnKeyDone;
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        style.lineSpacing = -15;
        style.firstLineHeadIndent = 10;
        style.headIndent = 10;
        style.tailIndent = -10;
        style.minimumLineHeight = 50;
        _textView.typingAttributes = @{NSForegroundColorAttributeName:[UIColor clearColor],NSFontAttributeName:[UIFont systemFontOfSize:32],NSParagraphStyleAttributeName:style};

    }
    return _textView;
}

#pragma mark - Help Methods
// 返回一个文本水印视图
- (SLRoundCornerLabel *)copyTextView:(SLRoundCornerTextView *)textView {
    if(![textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length){
        //只有空格时候不显示
        return nil;
    }
    SLRoundCornerLabel *label = [[SLRoundCornerLabel alloc] initWithFrame:textView.bounds];
    label.userInteractionEnabled = YES;
    label.lineBreakMode = NSLineBreakByCharWrapping;
    label.numberOfLines = 0;
    [label configAttributedString:textView.attributedString fillColor:textView.fillColor];
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
//选中的当前颜色
- (void)textColorBtnClicked:(UIButton *)colorBtn {
    UIButton *previousBtn = (UIButton *)[self viewWithTag:(10 + _currentIndex)];
    previousBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8f, 0.8f);
    previousBtn.layer.borderWidth = 2;
    colorBtn.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
    colorBtn.layer.borderWidth = 3;
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
    [self.textView configAttributedString:[self getAttStr] fillColor:self.currentTextBgColor];
    
}
//选择当前是文本颜色菜单还是背景颜色菜单
- (void)colorSwitchBtnClicked:(UIButton *)colorSwitch {
    _colorSwitch = !_colorSwitch;
    colorSwitch.selected = _colorSwitch;
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
    [self.textView configAttributedString:[self getAttStr] fillColor:self.currentTextBgColor];
}
//键盘即将弹出
- (void)keyboardWillShow:(NSNotification *)notification {
    //获取键盘高度 keyboardHeight
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    _keyboardHeight = keyboardRect.size.height;
    [self colorSelectionView:_keyboardHeight];
    [self configTextViewFrame];
}
//键盘即将消失
- (void)keyboardWillHide:(NSNotification *)notification{
    [self.textView resignFirstResponder];
    if (self.editTextCompleted) {
        self.editTextCompleted(nil);
    }
    [self removeFromSuperview];
}
#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString * string = [textView.text stringByReplacingCharactersInRange:range withString:text];
    CGFloat maxHeight = self.sl_height - 64 - _keyboardHeight -  50;
    ;
    
    CGFloat height = [string boundingRectWithSize:CGSizeMake(textView.sl_width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:32],NSParagraphStyleAttributeName:_textStyle} context:nil].size.height + 16;
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
    [self.textView configAttributedString:[self getAttStr] fillColor:self.currentTextBgColor];
    [self configTextViewFrame];
}
@end
