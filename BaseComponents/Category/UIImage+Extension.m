//
//  UIImage+Extension.m
//  BaseComponents
//
//  Created by Yehua Gao on 2017/12/20.
//  Copyright © 2017年 Yehua Gao. All rights reserved.
//

#import "UIImage+Extension.h"

@implementation UIImage (Extension)

- (UIImage *)normalizedImage{
    if (self.imageOrientation == UIImageOrientationUp) {
        return self;
    }
    
    UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
    [self drawInRect:(CGRect){0,0,self.size}];
    UIImage *normalizedImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return normalizedImg;
}

@end
