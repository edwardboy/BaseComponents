//
//  VideoManager.h
//  BaseComponents
//
//  Created by Yehua Gao on 2017/12/19.
//  Copyright © 2017年 Yehua Gao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void(^IMGeneratorBlock)(NSArray *result);

typedef enum{
    // video
    MediaTypeMovie, //  .mov and .qt
    MediaTypeMp4,   //  .mp4
    MediaTypeM4V,   //  .m4v
    
    // audio
    MediaTypeM4A,   //  .m4a
    MediaType3GPP,  //  .3gp  .3gpp
    MediaTypeCoreAudioFormat,   //  .caf
    MediaTypeWAVE,  //  .wav  .wave  .bwf
    MediaTypeAIFF,  //  .aif  .aiff
    MediaTypeAMR,   //  .amr
    MediaTypeMPEGLayer3,    //  .mp3
    MediaTypeAC3,   //  .ac3
    
} MediaType;

@interface VideoManager : NSObject

/*************1、添加水印****************/
/**
 使用GPUImage添加水印
 */
-(void)saveVedioPath:(NSURL*)vedioPath WithWaterImg:(UIImage*)img WithCoverImage:(UIImage*)coverImg WithQustion:(NSString*)question WithFileName:(NSString*)fileName;

///使用AVfoundation添加水印
- (void)AVsaveVideoPath:(NSURL*)videoPath WithWaterImg:(UIImage*)img WithCoverImage:(UIImage*)coverImg WithQustion:(NSString*)question WithFileName:(NSString*)fileName;

/*************2、合并视频****************/
/**
 合并视频

 @param firstPath 第一段视频路径
 @param secondPath 第二段视频路径
 @param bgMusicPath 背景音乐路径
 */
- (void)combineVideo:(NSString *)firstPath withVideo:(NSString *)secondPath andMusic:(NSString *)bgMusicPath fileName:(NSString *)fileName;



/*************3、视频中一系列图片****************/
- (void)generateSerialImagesWithVideoPath:(NSString *)videoPath result:(IMGeneratorBlock)generateResult;

/*************n、音视频转码****************/
- (void)transCodeWithVideoPath:(NSString *)videoPath toType:(MediaType)type destPath:(NSString *)destPath;
- (void)transCodeWithAudioPath:(NSString *)videoPath toType:(MediaType)type destPath:(NSString *)destPath;
@end
