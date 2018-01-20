//
//  CFRecorder.h
//  BaseComponents
//
//  Created by dfc on 2018/1/17.
//  Copyright © 2018年 Yehua Gao. All rights reserved.
//  collect audio (采集音频)

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define kBuffersNum 3

typedef  struct  _AQCallbackStruct{
    
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef  queue;
    AudioQueueBufferRef mBuffers[kBuffersNum];
    int run;
    
}AQCallbackStruct;

// 回调协议
@protocol CFRecorderDelegate <NSObject>
/**
 音频数据回调
 */
- (void)audioDataCallback:(AudioQueueBufferRef)buffer;
@end

@interface CFRecorder : NSObject

@property (nonatomic,weak) id<CFRecorderDelegate>delegate;
@property (nonatomic,assign) AQCallbackStruct aqc;

- (id)initWithDelegate:(id)delegate sampleRate:(NSInteger)sampleRate channels:(UInt32)channels;

/**
 开始采集
 */
- (void)start;

/**
 暂停采集
 */
- (void)pause;

/**
 停止采集

 @param immediate 是否立即停止
 */
- (void)stop:(BOOL)immediate;

@end
