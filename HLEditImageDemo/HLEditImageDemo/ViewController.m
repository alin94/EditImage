//
//  ViewController.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/4.
//  Copyright © 2020 alin. All rights reserved.
//

#import "ViewController.h"
#import "SLEditImageController.h"
#import "SLUtilsMacro.h"
@interface ViewController () <UIImagePickerControllerDelegate,UINavigationBarDelegate>
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImagePickerController *pickVC;

@end

@implementation ViewController
- (UIImageView *)imageView {
    if(!_imageView){
        _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:_imageView];
        [self.view sendSubviewToBack:_imageView];
    }
    return _imageView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    btn.frame = CGRectMake(0, 0, 100, 40);
    btn.center = CGPointMake(self.view.center.x, self.view.center.y - 100);
    [btn setTitle:NSLocalizedString(@"选择照片", @"") forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(selectImage) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    saveBtn.backgroundColor = [UIColor greenColor];
    saveBtn.frame = CGRectMake(0, 0, 100, 40);
    saveBtn.center = self.view.center;
    [saveBtn setTitle:NSLocalizedString(@"保存照片", @"") forState:UIControlStateNormal];
    [self.view addSubview:saveBtn];
    [saveBtn addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];

}
- (void)showEditImageVCWithImage:(UIImage *)image {
    SLEditImageController *vc = [[SLEditImageController alloc] initWithImage:image tipText:@"> 这里是提示文字"];
    WS(weakSelf);
    vc.editFinishedBlock = ^(UIImage * _Nonnull image) {
        weakSelf.imageView.image = image;
    };
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}

#pragma mark - Event Handle
//选择照片
- (void)selectImage {
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:YES completion:nil];
        self.pickVC = imagePicker;
    }
}
//保存照片
- (void)saveImage {
    if(self.imageView.image){
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]) {
            UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        }
    }
}
-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSString *msg = nil;
    if(error){
        msg = @"保存图片失败";
    }else{
        msg = @"保存图片成功";
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [alert dismissViewControllerAnimated:YES completion:^{
            
        }];
    }]];
    [self presentViewController:alert animated:YES completion:^{
        
    }];
}
#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage * retusltImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self showEditImageVCWithImage:retusltImage];
    }];

}

@end
