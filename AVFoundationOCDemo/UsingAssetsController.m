//
//  UsingAssetsController.m
//  AVFoundationOCDemo
//
//  Created by SouFun on 17/3/1.
//  Copyright © 2017年 bytebaker. All rights reserved.
//

#import "UsingAssetsController.h"
#import <AVFoundation/AVFoundation.h>

@interface UsingAssetsController ()

@end

@implementation UsingAssetsController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self test];
}

#pragma mark 截图
- (void)test
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVAsset *avAsset = [AVAsset assetWithURL:url];
    //Getting Still Images From a Video
    if ([avAsset tracksWithMediaType:AVMediaTypeVideo] > 0) {
        AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:avAsset];
        Float64 durationSeconds = CMTimeGetSeconds(avAsset.duration);
        CMTime midPoint = CMTimeMakeWithSeconds(durationSeconds / 2.0, 600);
        NSError *error;
        CMTime actualTime;
        
        CGImageRef halfWayImage = [imageGenerator copyCGImageAtTime:midPoint actualTime:&actualTime error:&error];
        
        if (halfWayImage != NULL) {
            NSString *actualTimeString = (NSString *)CFBridgingRelease(CMTimeCopyDescription(NULL, actualTime));
            NSString *requestedTimeString = (NSString *)CFBridgingRelease(CMTimeCopyDescription(NULL, midPoint));
            NSLog(@"Got halfWayImage: Asked for %@, got %@", requestedTimeString, actualTimeString);
            
            // Do something interesting with the image.
            CGImageRelease(halfWayImage);
        }
    }
    
    //Generating a Sequence of Images
    if ([avAsset tracksWithMediaType:AVMediaTypeVideo] > 0)
    {
        Float64 durationSeconds = CMTimeGetSeconds(avAsset.duration);
        CMTime firstThird = CMTimeMakeWithSeconds(durationSeconds / 3.0, 600);
        CMTime secondThird = CMTimeMakeWithSeconds(durationSeconds * 2.0 / 3.0, 600);
        CMTime end = CMTimeMakeWithSeconds(durationSeconds, 600);
        
        NSArray *times = @[[NSValue valueWithCMTime:kCMTimeZero], [NSValue valueWithCMTime:firstThird], [NSValue valueWithCMTime:secondThird], [NSValue valueWithCMTime:end]];
        AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:avAsset];
        [imageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
            NSString *requestedTimeString = (NSString *)
            CFBridgingRelease(CMTimeCopyDescription(NULL, requestedTime));
            NSString *actualTimeString = (NSString *)
            CFBridgingRelease(CMTimeCopyDescription(NULL, actualTime));
            NSLog(@"Requested: %@; actual %@", requestedTimeString, actualTimeString);
            
            if (result == AVAssetImageGeneratorSucceeded) {
                // Do something interesting with the image.
            }
            
            if (result == AVAssetImageGeneratorFailed) {
                NSLog(@"Failed with error: %@", [error localizedDescription]);
            }
            if (result == AVAssetImageGeneratorCancelled) {
                NSLog(@"Canceled");
            }
        }];
    }
}

- (void)test0
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVURLAsset *anAsset = [[AVURLAsset alloc] initWithURL:url options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
    NSArray *keys = @[@"duration"];
    [anAsset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
        NSError *error = nil;
        AVKeyValueStatus tracksStatus = [anAsset statusOfValueForKey:@"duration" error:&error];
        switch (tracksStatus) {
            case AVKeyValueStatusFailed:
                break;
                
            default:
                break;
        }
    }];
}

#pragma mark 转码
- (void)test2
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVAsset *avAsset = [AVAsset assetWithURL:url];
    //Trimming and Transcoding a Movie
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetLowQuality];
        NSURL *outputURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/test.mov", NSHomeDirectory()]];
        exportSession.outputURL = outputURL;
        exportSession.outputFileType = AVFileTypeQuickTimeMovie;
        CMTime start = CMTimeMakeWithSeconds(1.0, 600);
        CMTime duration = CMTimeMakeWithSeconds(3.0, 600);
        CMTimeRange range = CMTimeRangeMake(start, duration);
        exportSession.timeRange = range;
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed:
                    break;
                case AVAssetExportSessionStatusCompleted:
                    break;
                default:
                    break;
            }
        }];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
