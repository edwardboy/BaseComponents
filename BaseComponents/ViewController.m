//
//  ViewController.m
//  BaseComponents
//
//  Created by Yehua Gao on 2017/12/19.
//  Copyright © 2017年 Yehua Gao. All rights reserved.
//

#import "ViewController.h"
#import "VideoManager.h"

#import <Photos/Photos.h>
#import "UIImage+Extension.h"

@interface ViewController ()
{
    VideoManager *videoManager;
    NSString *filePath;
}
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *imgViews;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupView];
}

- (void)setupView{
    self.navigationItem.title = @"水印";
    videoManager = [[VideoManager alloc]init];
    filePath = [[NSBundle mainBundle] pathForResource:@"IMG_0897.MOV" ofType:nil];
}

- (IBAction)generateImgs:(UIButton *)sender {
    [videoManager generateSerialImagesWithVideoPath:filePath result:^(NSArray *result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (int i = 0; i<self.imgViews.count; i++) {
                if (result.count >= i + 1) {
                    UIImageView *imgView = (UIImageView *)[self.imgViews objectAtIndex:i];
                    UIImage *img = result[i];
                    imgView.image = [img normalizedImage];
                }
            }
        });
    }];
}

- (IBAction)combineVideo:(UIButton *)sender {
    
    NSString *sec = [[NSBundle mainBundle] pathForResource:@"IMG_0898.MOV" ofType:nil];
    NSString *bg = [[NSBundle mainBundle] pathForResource:@"once more love,once more pain.mp3" ofType:nil];
    
    [videoManager combineVideo:filePath withVideo:sec andMusic:bg fileName:@"combinedVideo_bg"];
}

/**
 利用AVFoundation添加水印
 */
- (IBAction)renderMarkWithFoundation:(UIButton *)sender {
    [videoManager AVsaveVideoPath:[NSURL fileURLWithPath:filePath] WithWaterImg:[UIImage imageNamed:@"icon"] WithCoverImage:[UIImage imageNamed:@"head"] WithQustion:@"达芬奇" WithFileName:@"IMG_0897_mark"];
}
- (IBAction)renderMarkWithGPU:(UIButton *)sender {
    [videoManager AVsaveVideoPath:[NSURL fileURLWithPath:filePath] WithWaterImg:[UIImage imageNamed:@"icon"] WithCoverImage:[UIImage imageNamed:@"head"] WithQustion:@"达芬奇" WithFileName:@"IMG_0897_mark1"];
}
- (IBAction)playVideo:(UIButton *)sender {
}

@end
