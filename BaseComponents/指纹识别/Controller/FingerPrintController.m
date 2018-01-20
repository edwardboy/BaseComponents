//
//  FingerPrintController.m
//  BaseComponents
//
//  Created by dfc on 2018/1/19.
//  Copyright © 2018年 Yehua Gao. All rights reserved.
//

#import "FingerPrintController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <pthread.h>

#define kSYSVersion [UIDevice currentDevice].systemVersion.floatValue

@interface FingerPrintController ()

@end

@implementation FingerPrintController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"指纹识别";
    
    [self  configFingerPrint];
}

- (void)configFingerPrint{
    if (kSYSVersion < 8.0) {
        [self alertTitle:@"尚不支持指纹识别"];
        return;
    }else {
        LAContext *context = [[LAContext alloc]init];
        context.localizedFallbackTitle = @"验证登录密码";
//        if (@avaliable (iOS 10,)) {
//
//        }
        if (kSYSVersion > 10.0) {
            context.localizedCancelTitle = @"取消";
        }
        NSData *stateData = context.evaluatedPolicyDomainState;
        NSLog(@"stateData---%@",stateData);
        
        NSError *error;
        __block NSString *localizedReason = @"通过Home键验证已有指纹";
        if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error]) {
            [context evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:localizedReason reply:^(BOOL success, NSError * _Nullable error) {
                if (success) {
                    [self alertTitle:@"解锁成功"];
                }else {
                    // 错误码 error.code
                    NSLog(@"指纹识别错误描述 %@",error.description);
                    
                    // -1: 连续三次指纹识别错误
                    // -2: 在TouchID对话框中点击了取消按钮
                    // -3: 在TouchID对话框中点击了输入密码按钮
                    // -4: TouchID对话框被系统取消，例如按下Home或者电源键
                    // -8: 连续五次指纹识别错误，TouchID功能被锁定，下一次需要输入系统密码
                    NSString * message;
                    switch (error.code) {
                        case -1://LAErrorAuthenticationFailed
                            message = @"已经连续三次指纹识别错误了，请输入密码验证";
                            localizedReason = @"指纹验证失败";
                            break;
                        case -2:
                            message = @"在TouchID对话框中点击了取消按钮";
                            return ;
                            break;
                        case -3:
                            message = @"在TouchID对话框中点击了输入密码按钮";
                            break;
                        case -4:
                            message = @"TouchID对话框被系统取消，例如按下Home或者电源键或者弹出密码框";
                            break;
                        case -8:
                            message = @"TouchID已经被锁定,请前往设置界面重新启用";
                            break;
                        default:
                            break;
                    }
                    
                    [self alertTitle:message];
                }
            }];
        }else{
            if (error.code == -8) {
                
            }else {
                
            }
        }
    }
}

- (void)alertTitle:(NSString *)title{
    if (pthread_main_np()) {    // 主线程
        [self alert:title];
    }else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self alert:title];
        });
    }
}

- (void)alert:(NSString *)title{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

@end
