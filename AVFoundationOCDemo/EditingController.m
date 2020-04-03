//
//  EditingController.m
//  AVFoundationOCDemo
//
//  Created by Bytebaker on 17/3/1.
//  Copyright © 2017年 bytebaker. All rights reserved.
//

#import "EditingController.h"
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface EditingController ()

@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@property (nonatomic, strong) AVAudioMix *audioMix;

@end

@implementation EditingController

- (void)viewDidLoad
{
    [super viewDidLoad];
    /** 载入视频源 */
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVAsset *videoAsset = [AVAsset assetWithURL:url];
    AVAssetTrack *videoTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    AVAssetTrack *audioTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(2, 1)) ofTrack:videoTrack atTime:CMTimeMake(2, 1) error:nil];
    
    AVMutableCompositionTrack *audioCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(2, 1)) ofTrack:audioTrack atTime:kCMTimeZero error:nil];
    //视频行为控制
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = videoAsset.naturalSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    /** 创建视频流命令控制器 */
    AVMutableVideoCompositionInstruction *mutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    /** 设置视频流命令控制器有效时间区域 */
    mutableVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, mutableComposition.duration);
    mutableVideoCompositionInstruction.backgroundColor = [UIColor redColor].CGColor;
    videoComposition.instructions = @[mutableVideoCompositionInstruction];
    
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:[mutableComposition tracksWithMediaType:AVMediaTypeVideo][0]];
    mutableVideoCompositionInstruction.layerInstructions = @[passThroughLayer];
    
    [passThroughLayer setTransform:CGAffineTransformMakeTranslation(0, 250) atTime:CMTimeMake(2, 1)];
    [passThroughLayer setTransform:CGAffineTransformMakeTranslation(0, 500) atTime:CMTimeMake(3, 1)];
    [passThroughLayer setOpacityRampFromStartOpacity:0.5 toEndOpacity:1 timeRange:CMTimeRangeMake(CMTimeMake(2, 1), CMTimeMake(3, 1))];
    
    /** 水印 */
    CGSize videoSize = CGSizeMake(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
    CATextLayer *textLayer = [CATextLayer layer];

    textLayer.backgroundColor = [UIColor redColor].CGColor;
    textLayer.string = @"123456";
    textLayer.bounds = CGRectMake(0, 0, videoSize.width * 0.5, videoSize.height * 0.5);
    
    CALayer *baseLayer = [CALayer layer];
    [baseLayer addSublayer:textLayer];
    baseLayer.position = CGPointMake(videoComposition.renderSize.width/2, videoComposition.renderSize.height/2);
    
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:baseLayer];
    AVVideoCompositionCoreAnimationTool *animalTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    videoComposition.animationTool = animalTool;
    
    CABasicAnimation *baseAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    baseAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(100, 100)];
    baseAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(200, 200)];
    baseAnimation.repeatCount = 5;
    baseAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
    baseAnimation.duration = 1;
    baseAnimation.removedOnCompletion = NO;
    [textLayer addAnimation:baseAnimation forKey:@"hehe"];
    
    //音频
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    AVMutableAudioMixInputParameters *inputParameter = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrack];
    audioMix.inputParameters = @[inputParameter];
    [inputParameter setVolumeRampFromStartVolume:0 toEndVolume:1 timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(2, 1))];
    
    [self exportAvasset:mutableComposition videoComposition:videoComposition audioMix:audioMix];
}

- (void)exportAvasset:(AVAsset *)asset videoComposition:(AVVideoComposition *)videoComposition audioMix:(AVAudioMix *)audioMix
{
    //导出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality];
    NSString *outputPath = [NSString stringWithFormat:@"%@/tmp/test.%@", NSHomeDirectory(),CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension))];
    NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
    }
    NSLog(@"输出至: %@", outputUrl);
    exporter.outputURL = outputUrl;
    exporter.videoComposition = videoComposition;
    exporter.audioMix = audioMix;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"status: %ld; error: %@;", (long)exporter.status, exporter.error);
    }];
}

- (void)viewDidLoad01 {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
//    [self beginEdit];
    [self export01];
    
//    CALayer *layer = [CALayer layer];
//    layer.frame = CGRectMake(0, 0, 200, 200);
//    layer.backgroundColor = [UIColor redColor].CGColor;
//    
//    [self.view.layer addSublayer:layer];
//    
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        CABasicAnimation *baseAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
//        baseAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(100, 100)];
//        baseAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(200, 200)];
//        baseAnimation.autoreverses = NO;
//        baseAnimation.duration = 10;
//        [layer addAnimation:baseAnimation forKey:@"hhhh"];
//    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)beginEdit
{
    /** 载入视频源 */
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVAsset *videoAsset = [AVAsset assetWithURL:url];
    
    /** 创建待输出的视频源 */
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    
    /** 向待输出的视频源添加视频流*/
    AVMutableCompositionTrack *videoCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    /** 提取视频源视频流数据 */
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    /** 将提取出的视频流插入到待输出的视频流上 */
    [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(2, 1)) ofTrack:videoAssetTrack atTime:CMTimeMake(2, 1) error:nil];
    
    /** 创建视频流输出控制 */
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    
    videoComposition.renderSize = videoAssetTrack.naturalSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    /** 创建视频流命令控制器 */
    AVMutableVideoCompositionInstruction *mutableVideoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    /** 设置视频流命令控制器有效时间区域 */
    mutableVideoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, mutableComposition.duration);
    
    /** 设置视频流命令控制器图层控制命令（操作待输出视频源的视频流） */
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:[mutableComposition tracksWithMediaType:AVMediaTypeVideo][0]];
    
    [passThroughLayer setTransform:CGAffineTransformMakeTranslation(0, 250) atTime:CMTimeMake(2, 1)];
    [passThroughLayer setTransform:CGAffineTransformMakeTranslation(0, 500) atTime:CMTimeMake(3, 1)];
    
    [passThroughLayer setOpacityRampFromStartOpacity:0.5 toEndOpacity:1 timeRange:CMTimeRangeMake(CMTimeMake(2, 1), CMTimeMake(3, 1))];
    mutableVideoCompositionInstruction.layerInstructions = @[passThroughLayer];
    mutableVideoCompositionInstruction.backgroundColor = [UIColor blueColor].CGColor;
    /** 设置命令 */
    videoComposition.instructions = @[mutableVideoCompositionInstruction];
    
    /** 水印 */
    CGSize videoSize = CGSizeMake(videoAssetTrack.naturalSize.width, videoAssetTrack.naturalSize.height);
    CATextLayer *textLayer = [CATextLayer layer];

    
    textLayer.backgroundColor = [UIColor redColor].CGColor;
    textLayer.string = @"123456";
    textLayer.bounds = CGRectMake(0, 0, videoSize.width * 0.5, videoSize.height * 0.5);
    
    CALayer *baseLayer = [CALayer layer];
    [baseLayer addSublayer:textLayer];
    baseLayer.position = CGPointMake(videoComposition.renderSize.width/2, videoComposition.renderSize.height/2);
    
    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height);
    
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:baseLayer];
    
    CABasicAnimation *baseAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    baseAnimation.fromValue = [NSValue valueWithCGPoint:CGPointMake(100, 100)];
    baseAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(200, 200)];
    baseAnimation.repeatCount = 5;
    baseAnimation.beginTime = AVCoreAnimationBeginTimeAtZero;
    baseAnimation.duration = 1;
    baseAnimation.removedOnCompletion = NO;
    [textLayer addAnimation:baseAnimation forKey:@"hhhh"];
    
    AVVideoCompositionCoreAnimationTool *animalTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    videoComposition.animationTool =  animalTool;
    
    
    //音频
    AVAsset *musicAsset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"Beacon" withExtension:@"m4a"]];
    AVAssetTrack *musicAssetTrack = [[musicAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    AVMutableCompositionTrack *audioCompositionTrack1 = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioCompositionTrack1 insertTimeRange:CMTimeRangeMake(kCMTimeZero, musicAssetTrack.timeRange.duration) ofTrack:musicAssetTrack atTime:kCMTimeZero error:nil];
    
    
    AVAssetTrack *firstAudioAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    AVMutableCompositionTrack *audioCompositionTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(3, 1)) ofTrack:firstAudioAssetTrack atTime:kCMTimeZero error:nil];
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrack];
    [mixParameters setVolumeRampFromStartVolume:0 toEndVolume:1 timeRange:CMTimeRangeMake(kCMTimeZero, CMTimeMake(2, 1))];
    audioMix.inputParameters = @[mixParameters];
    
    
    //导出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mutableComposition presetName:AVAssetExportPresetHighestQuality];
    NSString *outputPath = [NSString stringWithFormat:@"%@/tmp/test.%@", NSHomeDirectory(),CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension))];
    NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
    }
    NSLog(@"输出至: %@", outputUrl);
    exporter.outputURL = outputUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = videoComposition;
    exporter.audioMix = audioMix;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"status: %ld; error: %@;", (long)exporter.status, exporter.error);
    }];

}

- (void)export01
{
    /** 载入视频源 */
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVAsset *videoAsset = [AVAsset assetWithURL:url];
    //导出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:AVAssetExportPresetHighestQuality];
    NSString *outputPath = [NSString stringWithFormat:@"%@/tmp/test.%@", NSHomeDirectory(),CFBridgingRelease(UTTypeCopyPreferredTagWithClass((CFStringRef)AVFileTypeQuickTimeMovie, kUTTagClassFilenameExtension))];
    NSURL *outputUrl = [NSURL fileURLWithPath:outputPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        [[NSFileManager defaultManager] removeItemAtURL:outputUrl error:nil];
    }
    NSLog(@"输出至: %@", outputUrl);
    exporter.outputURL = outputUrl;
    exporter.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMake(2, 1));
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        NSLog(@"status: %ld; error: %@;", (long)exporter.status, exporter.error);
    }];
}

@end
