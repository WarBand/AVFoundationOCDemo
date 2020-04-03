//
//  ViewController.m
//  AVFoundationOCDemo
//
//  Created by Bytebaker on 17/2/8.
//  Copyright © 2017年 bytebaker. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import "PlaybackController.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface PlaybackController ()
{
    AVPlayer *avPlayer;
    AVPlayerItem *avPlayerItem;
}

@property (nonatomic, strong) NSTimer *timer;

@end

@implementation PlaybackController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self test];
}

#pragma mark 播放
- (void)test
{
    NSString *path = [NSString stringWithFormat:@"%@demo.%@", NSTemporaryDirectory(), CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(AVFileTypeMPEG4), (CFStringRef)kUTTagClassFilenameExtension))];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSURL *url = [NSURL fileURLWithPath:path];
//    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVURLAsset *avUrlAsset = [AVURLAsset assetWithURL:url];
    avPlayerItem = [[AVPlayerItem alloc] initWithAsset:avUrlAsset];
    [avPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    avPlayer = [AVPlayer playerWithPlayerItem:avPlayerItem];
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:avPlayer];
    
    playerLayer.frame = [UIScreen mainScreen].bounds;
    [self.view.layer addSublayer:playerLayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:avPlayerItem];
    
    
    
//    AVQueuePlayer
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(AVPlayerItem *)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if (object.status == AVPlayerItemStatusReadyToPlay) {
        
        [avPlayer play];
        if ([avPlayerItem canPlayReverse]) {
            
        } else if ([avPlayerItem canPlaySlowReverse]) {
            
        }
        [avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(3, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            NSLog(@"%s", __func__);
        }];
        [avPlayer addBoundaryTimeObserverForTimes:@[[NSValue valueWithCMTime:CMTimeMake(3, 1)]] queue:dispatch_get_main_queue() usingBlock:^{
            NSLog(@"%s", __func__);
        }];
//        avPlayer.rate = 3.0;
    }
}

- (void)playerItemDidReachEnd:(NSNotification *)noti
{
    [avPlayer seekToTime:kCMTimeZero];
//    avPlayer seekToTime:<#(CMTime)#> toleranceBefore:<#(CMTime)#> toleranceAfter:<#(CMTime)#>
    
}

- (void)dealloc
{
    [avPlayerItem removeObserver:self forKeyPath:@"status"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

