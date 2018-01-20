//
//  CFRecorder.m
//  BaseComponents
//
//  Created by dfc on 2018/1/17.
//  Copyright © 2018年 Yehua Gao. All rights reserved.
//  

#import "CFRecorder.h"

@implementation CFRecorder

/**
 音频队列处理回调
 */
static void AQinputCallback(void *inUserData, AudioQueueRef inAudioQueue,AudioQueueBufferRef inBuffer,const AudioTimeStamp *inStartTime,UInt32 inNumPackets,const AudioStreamPacketDescription *inPacketDesc){
    CFRecorder *recorder = (__bridge CFRecorder *)inUserData;
    if (inNumPackets>0) {
        [recorder disposeAudioBuffer:inBuffer queue:inAudioQueue];
    }
    
    if (recorder.aqc.run == 1) {
        AudioQueueEnqueueBuffer(recorder.aqc.queue, inBuffer, 0, NULL);
    }
}

- (id)initWithDelegate:(id)delegate sampleRate:(NSInteger)sampleRate channels:(UInt32)channels{
    if (_aqc.run == 1) {
        return self;
    }
    
    self = [super init];
    if (self) {
        self.delegate = delegate;
        
        _aqc.mDataFormat.mSampleRate = sampleRate;
        _aqc.mDataFormat.mFormatID = kAudioFormatLinearPCM;
        _aqc.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        _aqc.mDataFormat.mBitsPerChannel = 16;
        _aqc.mDataFormat.mChannelsPerFrame = channels;
        _aqc.mDataFormat.mBytesPerFrame = channels * (_aqc.mDataFormat.mBitsPerChannel/8);
        
        _aqc.mDataFormat.mFramesPerPacket = 1;
        _aqc.mDataFormat.mBytesPerPacket = _aqc.mDataFormat.mBytesPerFrame *_aqc.mDataFormat.mFramesPerPacket;
        
        // 创建音频队列
        AudioQueueNewInput(&_aqc.mDataFormat, AQinputCallback, (__bridge void *)(self), NULL, kCFRunLoopCommonModes, 0, &_aqc.queue);
        for (int i = 0; i<kBuffersNum; i++) {
            AudioQueueAllocateBuffer(_aqc.queue, 1280, &_aqc.mBuffers[i]);
            AudioQueueEnqueueBuffer(_aqc.queue, _aqc.mBuffers[i], 0, NULL);
        }
        _aqc.run = 1;
    }
    return self;
}

/**
 开始采集
 */
- (void)start{
    AudioQueueStart(_aqc.queue, NULL);
}

/**
 暂停采集
 */
- (void)pause{
    AudioQueuePause(_aqc.queue);
}

/**
 停止采集
 
 @param immediate 是否立即停止
 */
- (void)stop:(BOOL)immediate{
    AudioQueueStop(_aqc.queue, immediate);
    AudioQueueDispose(_aqc.queue, true);
}

- (void)disposeAudioBuffer:(AudioQueueBufferRef)buffer queue:(AudioQueueRef)queue{
    if (self.delegate && [self.delegate respondsToSelector:@selector(audioDataCallback:)]) {
        [self.delegate audioDataCallback:buffer];
    }
}

- (void)dealloc{
    _delegate = nil;
    AudioQueueStop(_aqc.queue, true);
    _aqc.run = 0;
    AudioQueueDispose(_aqc.queue, true);
}

@end
