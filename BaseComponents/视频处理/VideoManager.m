//
//  VideoManager.m
//  BaseComponents
//
//  Created by Yehua Gao on 2017/12/19.
//  Copyright © 2017年 Yehua Gao. All rights reserved.
//

#import "VideoManager.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "GPUImage.h"

@interface VideoManager()
{
    CADisplayLink* dlink;
    
    ///GPUImage
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
    
    ///AVFoundation
    AVAsset *videoAsset;
    AVAssetExportSession *exporter;
}

@end

@implementation VideoManager

//- (void)test{
//    AVURLAsset *asset;
//    [asset loadValuesAsynchronouslyForKeys:@[] completionHandler:^{
//        NSError *error = nil;
//        AVKeyValueStatus status = [asset statusOfValueForKey:@"" error:&error];
//    }];
//}

/**
 使用GPUImage加载水印
 
 @param vedioPath 视频路径
 @param img 水印图片
 @param coverImg 水印图片二
 @param question 字符串水印
 @param fileName 生成之后的视频名字
 */
-(void)saveVedioPath:(NSURL*)vedioPath WithWaterImg:(UIImage*)img WithCoverImage:(UIImage*)coverImg WithQustion:(NSString*)question WithFileName:(NSString*)fileName
{
    
    filter = [[GPUImageNormalBlendFilter alloc] init];
    
    NSURL *sampleURL  = vedioPath;
    AVAsset *asset = [AVAsset assetWithURL:sampleURL];
    CGSize size = asset.naturalSize;
    
    movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
    movieFile.playAtActualSpeed = NO;
    
    // 文字水印
    UILabel *label = [[UILabel alloc] init];
    label.text = question;
    label.font = [UIFont systemFontOfSize:30];
    label.textColor = [UIColor whiteColor];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label sizeToFit];
    label.layer.masksToBounds = YES;
    label.layer.cornerRadius = 18.0f;
    [label setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
    [label setFrame:CGRectMake(50, 100, label.frame.size.width+20, label.frame.size.height)];
    
    //图片水印
    UIImage *coverImage1 = [img copy];
    UIImageView *coverImageView1 = [[UIImageView alloc] initWithImage:coverImage1];
    [coverImageView1 setFrame:CGRectMake(0, 100, 210, 50)];
    
    //第二个图片水印
    UIImage *coverImage2 = [coverImg copy];
    UIImageView *coverImageView2 = [[UIImageView alloc] initWithImage:coverImage2];
    [coverImageView2 setFrame:CGRectMake(270, 100, 210, 50)];
    
    UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    subView.backgroundColor = [UIColor clearColor];
    
    [subView addSubview:coverImageView1];
    [subView addSubview:coverImageView2];
    [subView addSubview:label];
    
    
    GPUImageUIElement *uielement = [[GPUImageUIElement alloc] initWithView:subView];
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.mp4",fileName]];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(720.0, 1280.0)];
    
    GPUImageFilter* progressFilter = [[GPUImageFilter alloc] init];
    [progressFilter addTarget:filter];
    [movieFile addTarget:progressFilter];
    [uielement addTarget:filter];
    movieWriter.shouldPassthroughAudio = YES;
    if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] > 0){
        movieFile.audioEncodingTarget = movieWriter;
    } else {//no audio
        movieFile.audioEncodingTarget = nil;
    }
    //    movieFile.playAtActualSpeed = true;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:movieWriter];
    // 显示到界面
    [filter addTarget:movieWriter];
    
    [movieWriter startRecording];
    [movieFile startProcessing];
    
    __weak typeof(self) weakSelf = self;
    //渲染
    [progressFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        //水印可以移动
        CGRect frame = coverImageView1.frame;
        frame.origin.x += 1;
        frame.origin.y += 1;
        coverImageView1.frame = frame;
        //第5秒之后隐藏coverImageView2
        if (time.value/time.timescale>=5.0) {
            [coverImageView2 removeFromSuperview];
        }
        [uielement update];
        
    }];
    //保存相册
    [movieWriter setCompletionBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->filter removeTarget:strongSelf->movieWriter];
            [strongSelf->movieWriter finishRecording];
            __block PHObjectPlaceholder *placeholder;
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie))
            {
                NSError *error;
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:movieURL];
                    placeholder = [createAssetRequest placeholderForCreatedAsset];
                } error:&error];
                if (error) {
                    NSLog(@"error---%@",error.localizedDescription);
                }else{
                    NSLog(@"视频已经保存到相册");
                }
            }
        });
    }];
}

///使用AVfoundation添加水印
- (void)AVsaveVideoPath:(NSURL*)videoPath WithWaterImg:(UIImage*)img WithCoverImage:(UIImage*)coverImg WithQustion:(NSString*)question WithFileName:(NSString*)fileName
{
    if (!videoPath) {
        return;
    }
    
    //1 创建AVAsset实例 AVAsset包含了video的所有信息 self.videoUrl输入视频的路径
    
    //封面图片
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    videoAsset = [AVURLAsset URLAssetWithURL:videoPath options:opts];     //初始化视频媒体文件
    
    CMTime startTime = CMTimeMakeWithSeconds(0, 600);
    CMTime endTime = CMTimeMakeWithSeconds(videoAsset.duration.value/videoAsset.duration.timescale, videoAsset.duration.timescale);
    
    
    //2 创建AVMutableComposition实例. apple developer 里边的解释 【AVMutableComposition is a mutable subclass of AVComposition you use when you want to create a new composition from existing assets. You can add and remove tracks, and you can add, remove, and scale time ranges.】
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    /**视频处理*/
    //  视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    //把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
    [videoTrack insertTimeRange:CMTimeRangeFromTimeToTime(startTime, endTime)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    
    /**音频处理*/
    //  通道编辑器（音频、视频）
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //  采集视频中的音频通道
    AVAssetTrack *audioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [audioTrack insertTimeRange:CMTimeRangeFromTimeToTime(startTime, endTime) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //  3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, videoTrack.timeRange.duration);
    
    //  3.2 AVMutableVideoCompositionLayerInstruction 一个视频轨道，包含了这个轨道上的所有视频素材
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:endTime];
    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    
    //AVMutableVideoComposition：管理所有视频轨道，可以决定最终视频的尺寸，裁剪需要在这里进行
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    
    //  frameDuration表示什么
#warning frameDuration表示什么
    mainCompositionInst.frameDuration = CMTimeMake(1, 25);
    
    [self applyVideoEffectsToComposition:mainCompositionInst WithWaterImg:img WithCoverImage:coverImg WithQustion:question size:CGSizeMake(renderWidth, renderHeight)];
    
    // 4 - 输出路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",fileName]];
    unlink([myPathDocs UTF8String]);
    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
    
    dlink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    [dlink setFrameInterval:15];
    [dlink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [dlink setPaused:NO];
    // 5 - 视频文件输出
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=videoUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //这里是输出视频之后的操作，做你想做的
            [self exportDidFinish:exporter];
        });
    }];
}

- (void)exportDidFinish:(AVAssetExportSession*)session {
    if (session.status == AVAssetExportSessionStatusCompleted) {
        NSURL *outputURL = session.outputURL;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __block PHObjectPlaceholder *placeholder;
            if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(outputURL.path)) {
                NSError *error;
                [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                    PHAssetChangeRequest* createAssetRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputURL];
                    placeholder = [createAssetRequest placeholderForCreatedAsset];
                } error:&error];
                if (error) {
//                    NSLog(@"error---%@",error.localizedDescription);
                    [self alert:error.localizedDescription];
                }
                else{
                    NSLog(@"视频已经保存到相册");
                    [self alert:@"视频已经保存到相册"];
                }
            }else {
                NSLog(@"视频保存相册失败，请设置软件读取相册权限");
                [self alert:@"视频保存相册失败，请设置软件读取相册权限"];
            }
        });
    }
}

- (void)alert:(NSString *)title{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"提示" message:title delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition WithWaterImg:(UIImage*)img WithCoverImage:(UIImage*)coverImg WithQustion:(NSString*)question  size:(CGSize)size {
    
    UIFont *font = [UIFont systemFontOfSize:30.0];
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFontSize:30];
    [subtitle1Text setString:question];
    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    subtitle1Text.masksToBounds = YES;
    subtitle1Text.cornerRadius = 23.0f;
//    [subtitle1Text setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor];
    subtitle1Text.backgroundColor = [UIColor clearColor].CGColor;
    CGSize textSize = [question sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    [subtitle1Text setFrame:CGRectMake(50, 100, textSize.width+20, textSize.height+10)];
    
    //水印(显示位置、大小)
    CALayer *imgLayer = [CALayer layer];
    imgLayer.contents = (id)img.CGImage;
    //    imgLayer.bounds = CGRectMake(0, 0, size.width, size.height);
    imgLayer.bounds = CGRectMake(0, 0, 160, 160);
    imgLayer.position = CGPointMake(size.width - 85, size.height - 85);
    
    //第二个水印
    CALayer *coverImgLayer = [CALayer layer];
    coverImgLayer.contents = (id)coverImg.CGImage;
    //    [coverImgLayer setContentsGravity:@"resizeAspect"];
    coverImgLayer.bounds =  CGRectMake(50, 200,180,180);
    coverImgLayer.position = CGPointMake(size.width/2.0, size.height/2.0);
    
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    [overlayLayer addSublayer:imgLayer];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    [parentLayer addSublayer:coverImgLayer];
    
    //设置封面
    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"opacity"];
    anima.fromValue = [NSNumber numberWithFloat:1.0f];
    anima.toValue = [NSNumber numberWithFloat:0.0f];
    anima.repeatCount = 0;
    anima.duration = 5.0f;  //5s之后消失
    [anima setRemovedOnCompletion:NO];
    [anima setFillMode:kCAFillModeForwards];
    anima.beginTime = AVCoreAnimationBeginTimeAtZero;
    [coverImgLayer addAnimation:anima forKey:@"opacityAniamtion"];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
}

//更新生成进度
- (void)updateProgress {
    NSLog(@"生成中...");
    if (exporter.progress>=1.0) {
        [dlink setPaused:true];
        [dlink invalidate];
    }
}



/*************2、合并视频****************/
/**
 合并视频
 
 @param firstPath 第一段视频路径
 @param secondPath 第二段视频路径
 @param bgMusicPath 背景音乐路径
 */
- (void)combineVideo:(NSString *)firstPath withVideo:(NSString *)secondPath andMusic:(NSString *)bgMusicPath fileName:(NSString *)fileName{
    
    if (!firstPath.length || !secondPath.length) {
        NSLog(@"video Path can not be nil");
        [self alert:@"video Path can not be nil"];
        return;
    }
    
    NSDictionary *options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@(YES)};
    
    // 读取第一段视频的相关信息
    NSURL *firstURL = [NSURL fileURLWithPath:firstPath];
    AVURLAsset *firstUrlAsset = [AVURLAsset URLAssetWithURL:firstURL options:options];
    
    // 读取第二段视频的相关信息
    NSURL *secondURL = [NSURL fileURLWithPath:secondPath];
    AVURLAsset *secondUrlAsset = [AVURLAsset URLAssetWithURL:secondURL options:options];
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc]init];
    
    NSError *error;
    // 视频轨道处理
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    // 插入第一段视频
    AVAssetTrack *firstTrack = [firstUrlAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstUrlAsset.duration) ofTrack:firstTrack atTime:kCMTimeZero error:&error];
    
    // 插入第二段视频
    AVAssetTrack *secondTrack = [secondUrlAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondUrlAsset.duration) ofTrack:secondTrack atTime:firstUrlAsset.duration error:&error];
    
    //  处理视频方向
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, videoTrack.timeRange.duration);
    
    CGSize videoSize = videoTrack.naturalSize;
    
    CGAffineTransform t = firstTrack.preferredTransform;
//    CGAffineTransform secondTransform = secondTrack.preferredTransform;
    
#warning 当前是需要合并的两个视频同时方向旋转90度，如果一个旋转、一个正常的话，该如何处理，会不会有问题
    if((t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0) ||
       (t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)){
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstUrlAsset.duration, secondUrlAsset.duration));
    
    mixComposition.naturalSize = videoSize;
    
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    // 此处根据第一个视频判断止呕
    [layerInstruction setTransform:firstTrack.preferredTransform atTime:kCMTimeZero];
    [layerInstruction setTransform:secondTrack.preferredTransform atTime:firstUrlAsset.duration];
    mainInstruction.layerInstructions = @[layerInstruction];
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoSize;
    videoComposition.frameDuration = CMTimeMakeWithSeconds(1/videoTrack.nominalFrameRate, 600);
    videoComposition.instructions = @[mainInstruction];
    
    if (bgMusicPath.length) {   // 需要添加背景音乐
        NSURL *bgmusicURL = [NSURL fileURLWithPath:bgMusicPath];
        AVURLAsset *bgmusicUrlAsset = [AVURLAsset URLAssetWithURL:bgmusicURL options:options];
        
        // 音频轨道处理
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeAdd(firstUrlAsset.duration, secondUrlAsset.duration)) ofTrack:[bgmusicUrlAsset tracksWithMediaType:AVMediaTypeAudio].firstObject atTime:kCMTimeZero error:&error];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",fileName]];
    unlink([myPathDocs UTF8String]);
    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=videoUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = videoComposition;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //这里是输出视频之后的操作，做你想做的
            [self exportDidFinish:exporter];
        });
    }];
}

/**
 视频恢复原方向
 */
- (void)tansformVideo:(AVMutableCompositionTrack *)videoTrack{
    
}


/*************3、视频中一系列图片****************/
- (void)generateSerialImagesWithVideoPath:(NSString *)videoPath result:(IMGeneratorBlock)generateResult{
    AVAsset *videoAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:videoPath]];
    AVAssetImageGenerator *imgGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:videoAsset];
    
    Float64 durationSeconds = CMTimeGetSeconds(videoAsset.duration);
    CMTime time1 = CMTimeMakeWithSeconds(durationSeconds/3.0, 600);
    CMTime time2 = CMTimeMakeWithSeconds(durationSeconds*2/3.0, 600);
    CMTime time3 = CMTimeMakeWithSeconds(durationSeconds, 600);
    NSArray *times = @[[NSValue valueWithCMTime:kCMTimeZero],[NSValue valueWithCMTime:time1],[NSValue valueWithCMTime:time2],[NSValue valueWithCMTime:time3]];
    
    NSMutableArray *imgs = [NSMutableArray array];
    
    NSString *destPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    
    [imgGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        NSString *requestedTimeString = (NSString *)CFBridgingRelease(CMTimeCopyDescription(NULL, requestedTime));
        NSString *actualTimeString = (NSString *)CFBridgingRelease(CMTimeCopyDescription(NULL, actualTime));
        
        NSLog(@"requestedTimeString:%@,actualTimeString:%@",requestedTimeString,actualTimeString);
        
        if (result == AVAssetImageGeneratorSucceeded) {
            UIImage *img = [[UIImage alloc] initWithCGImage:image];
            
            [imgs addObject:img];
            
//            NSString *filePath = [destPath stringByAppendingPathComponent:[NSString stringWithFormat:@"thumbImg"]];
//            NSLog(@"filepath---%@",filePath);
//            if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
//                [[NSFileManager defaultManager] createDirectoryAtPath:filePath
//                       withIntermediateDirectories:YES
//                                        attributes:nil
//                                             error:nil];
//            }
//
//            filePath = [filePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png",actualTimeString]];
//            BOOL status = [UIImagePNGRepresentation(img) writeToFile:filePath atomically:NO];
//            if (!status) {
//                NSLog(@"写入失败");
//            }
        }else if (result == AVAssetImageGeneratorCancelled){
            NSLog(@"AVAssetImageGeneratorCancelled");
        }else if (result == AVAssetImageGeneratorFailed){
            NSLog(@"AVAssetImageGeneratorFailed");
        }else {
            NSLog(@"===========");
        }
        NSLog(@"return====");
        
        if ([[NSValue valueWithCMTime:requestedTime] isEqualToValue:[NSValue valueWithCMTime:time3]]){
            if (generateResult) {
                generateResult(imgs.copy);
            }
        }
    }];
}


/*************3、音视频转码****************/
- (void)transCodeWithVideoPath:(NSString *)videoPath toType:(MediaType)type destPath:(NSString *)destPath{
    
}

- (void)transCodeWithAudioPath:(NSString *)videoPath toType:(MediaType)type destPath:(NSString *)destPath{
    
}




@end
