//
//  ViewController.m
//  HLEditImageDemo
//
//  Created by alin on 2020/12/4.
//  Copyright © 2020 alin. All rights reserved.
//

#import "ViewController.h"
#import "SLEditImageController.h"

@interface ViewController () <UIImagePickerControllerDelegate,UINavigationBarDelegate>
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation ViewController
- (UIImageView *)imageView {
    if(!_imageView){
        _imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.view addSubview:_imageView];
    }
    return _imageView;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = [UIColor redColor];
    btn.frame = CGRectMake(0, 0, 100, 40);
    btn.center = self.view.center;
    [btn setTitle:NSLocalizedString(@"选择照片", @"") forState:UIControlStateNormal];
    [self.view addSubview:btn];
    [btn addTarget:self action:@selector(selectImage) forControlEvents:UIControlEventTouchUpInside];
    
}
- (void)selectImage {
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.delegate = self;
        [self presentViewController:imagePicker animated:YES completion:nil];

    }

    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage * retusltImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self showEditImageVCWithImage:retusltImage];
    }];

}
- (void)showEditImageVCWithImage:(UIImage *)image {
    SLEditImageController *vc = [[SLEditImageController alloc] init];
    vc.image = image;
    WS(weakSelf);
    vc.editFinishedBlock = ^(UIImage * _Nonnull image) {
        weakSelf.imageView.image = image;
    };
    [self presentViewController:vc animated:YES completion:^{
        
    }];
}
@end
