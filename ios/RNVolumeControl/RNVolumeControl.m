//
//  ReactNativeVolumeController.m
//  ReactNativeVolumeController
//
//  Created by Tyler Malone on 03/18/19.
//  Copyright © 2019. All rights reserved.
//

#import "RNVolumeControl.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@implementation RNVolumeControl {
    MPVolumeView *volumeView;
    UISlider *volumeViewSlider;
    AVAudioSession *audioSession;
    bool hasListeners;
}

RCT_EXPORT_MODULE(VolumeControl)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"VolumeChanged"];
}

- (instancetype)init{
    self = [super init];
    [self initVolumeView];
    [self initAudioSessionObserver];
    return self;
}

- (void)startObserving {
    hasListeners = YES;
}

- (void)stopObserving {
    hasListeners = NO;
}

+ (BOOL) requiresMainQueueSetup {
    return YES;
}

- (void)initAudioSessionObserver{
    audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:YES error:nil];
    [audioSession addObserver:self forKeyPath:@"outputVolume" options:0 context:nil];
}


- (void)initVolumeView{
    volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
    volumeView.showsRouteButton = NO;
    volumeView.clipsToBounds = YES;
    [volumeView setUserInteractionEnabled:NO];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addSubview:volumeView];
    
    for (UIView *view in volumeView.subviews) {
        if ([view isKindOfClass:[UISlider class]]) {
            volumeViewSlider = (UISlider *)view;
            break;
        }
    }
}

- (void)setVolume:(float)volumeValue {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        float newVolume = 0;
        if (volumeValue > 0.999) {
            newVolume = 0.9375;
        } else if (volumeValue < 0.001) {
            newVolume = 0.0625;
        } else {
            newVolume = volumeValue;
        }
        volumeViewSlider.value = newVolume;
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if ([keyPath isEqual:@"outputVolume"] && hasListeners) {
            volumeViewSlider.value = volumeViewSlider.value;
            float newVolume = volumeViewSlider.value;
            [self sendEventWithName:@"VolumeChanged" body:@{@"volume": [NSNumber numberWithFloat: newVolume]}];
    }
}

- (void)dealloc {
    [audioSession removeObserver:self forKeyPath:@"outputVolume"];
    [volumeView removeFromSuperview];
}



RCT_EXPORT_METHOD(change:(float)value)
{
    [self setVolume:value];
}

RCT_EXPORT_METHOD(getVolume:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject){
    dispatch_sync(dispatch_get_main_queue(), ^{
        resolve([NSNumber numberWithFloat:[volumeViewSlider value]]);
    });
}

@end
