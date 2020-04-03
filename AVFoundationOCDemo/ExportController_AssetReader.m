//
//  ExportController-AssetReader.m
//  AVFoundationOCDemo
//
//  Created by Bytebaker on 17/3/27.
//  Copyright © 2017年 bytebaker. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "ExportController_AssetReader.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface ExportController_AssetReader ()

@property (nonatomic, strong) dispatch_queue_t mainSerializationQueue;
@property (nonatomic, strong) dispatch_queue_t rwAudioSerializationQueue;
@property (nonatomic, strong) dispatch_queue_t rwVideoSerializationQueue;

@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic, assign) BOOL cancelled;

@property (nonatomic, strong) NSURL *outputURL;

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetReader *assetReader;

@property (nonatomic, strong) AVAssetReaderTrackOutput *assetReaderAudioOutput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetReaderVideoOutput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;

@property (nonatomic, strong) dispatch_group_t dispatchGroup;

@property (nonatomic, assign) BOOL audioFinished;
@property (nonatomic, assign) BOOL videoFinished;

@end

@implementation ExportController_AssetReader

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/** 音频解码 */
- (NSDictionary *)configAudioOutput
{
    NSDictionary *audioOutputSetting = @{
                                         AVFormatIDKey: @(kAudioFormatLinearPCM)
                                         };
    return audioOutputSetting;
}

/** 视频解码 */
- (NSDictionary *)configVideoOutput
{
    NSDictionary *videoOutputSetting = @{
                                         (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_422YpCbCr8],
                                         (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey:[NSDictionary dictionary]
                                         };
    
    return videoOutputSetting;
}

/** 音频编码
 For AVMediaTypeAudio the following keys are not currently supported in the outputSettings dictionary: AVEncoderAudioQualityKey and AVSampleRateConverterAudioQualityKey.  When using this method to construct a new instance, an audio settings dictionary must be fully specified, meaning that it must contain AVFormatIDKey, AVSampleRateKey, and AVNumberOfChannelsKey.  If no other channel layout information is available, a value of 1 for AVNumberOfChannelsKey will result in mono output and a value of 2 will result in stereo output.  If AVNumberOfChannelsKey specifies a channel count greater than 2, the dictionary must also specify a value for AVChannelLayoutKey.  For kAudioFormatLinearPCM, all relevant AVLinearPCM*Key keys must be included, and for kAudioFormatAppleLossless, AVEncoderBitDepthHintKey keys must be included.  See +assetWriterInputWithMediaType:outputSettings:sourceFormatHint: for a way to avoid having to specify a value for each of those keys.
 */
- (NSDictionary *)configAudioInput
{
    AudioChannelLayout channelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = kAudioChannelBit_Left,
        .mNumberChannelDescriptions = 0
    };
    NSData *channelLayoutData = [NSData dataWithBytes:&channelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    NSDictionary *audioInputSetting = @{
                                        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                        AVSampleRateKey: @(44100),
                                        AVNumberOfChannelsKey: @(2),
                                        AVChannelLayoutKey:channelLayoutData
                                        };
    return audioInputSetting;
}

/** 视频编码
 For AVMediaTypeVideo, any output settings dictionary must request a compressed video format.  This means that the value passed in for outputSettings must follow the rules for compressed video output, as laid out in AVVideoSettings.h.  When using this method to construct a new instance, a video settings dictionary must be fully specified, meaning that it must contain AVVideoCodecKey, AVVideoWidthKey, and AVVideoHeightKey.  See +assetWriterInputWithMediaType:outputSettings:sourceFormatHint: for a way to avoid having to specify a value for each of those keys.  On iOS, the only values currently supported for AVVideoCodecKey are AVVideoCodecH264 and AVVideoCodecJPEG.  AVVideoCodecH264 is not supported on iPhone 3G.  For AVVideoScalingModeKey, the value AVVideoScalingModeFit is not supported.
 */
- (NSDictionary *)configVideoInput
{
    NSDictionary *videoInputSetting = @{
                                        AVVideoCodecKey:AVVideoCodecH264,
                                        AVVideoWidthKey: @(540),
                                        AVVideoHeightKey: @(360)
                                        };
    return videoInputSetting;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self assetOutputSettingAssistant];
    
//    return;
    
    self.mainSerializationQueue = dispatch_queue_create("Main Queue", NULL);
    
    dispatch_queue_t audioQueue = dispatch_queue_create("Audio Queue", DISPATCH_QUEUE_SERIAL);
    self.rwAudioSerializationQueue = audioQueue;
    
    dispatch_queue_t videoQueue = dispatch_queue_create("Video Queue", DISPATCH_QUEUE_SERIAL);
    self.rwVideoSerializationQueue = videoQueue;
    
    //AVAssetReader
    NSURL *assetUrl = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVAsset *asset = [AVAsset assetWithURL:assetUrl];
    self.asset = asset;
    if (asset == nil) {
        return;
    }
    
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:asset error:nil];
    self.assetReader = assetReader;
    
    AVAssetTrack *audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    NSDictionary *audioOutputSetting = [self configAudioOutput];
    AVAssetReaderTrackOutput *audioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:audioOutputSetting];
    self.assetReaderAudioOutput = audioTrackOutput;
    
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    NSDictionary *videoOutputSetting = [self configVideoOutput];
    AVAssetReaderTrackOutput *videoTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack outputSettings:videoOutputSetting];
    self.assetReaderVideoOutput = videoTrackOutput;
    
    if ([assetReader canAddOutput:audioTrackOutput]) {
        [assetReader addOutput:audioTrackOutput];
    }
    if ([assetReader canAddOutput:videoTrackOutput]) {
        [assetReader addOutput:videoTrackOutput];
    }
    
    NSString *path = [NSString stringWithFormat:@"%@demo.%@", NSTemporaryDirectory(), CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(AVFileTypeQuickTimeMovie), (CFStringRef)kUTTagClassFilenameExtension))];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSURL *url = [NSURL fileURLWithPath:path];
    NSLog(@"%@", path);
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
    self.assetWriter = assetWriter;
    
    
    NSDictionary *audioInputSetting = [self configAudioInput];
    AVAssetWriterInput *audioTrackInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioInputSetting];
    self.assetWriterAudioInput = audioTrackInput;
    
    NSDictionary *videoInputSetting = [self configVideoInput];
    AVAssetWriterInput *videoTrackInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoInputSetting];
    self.assetWriterVideoInput = videoTrackInput;
    
    if ([assetWriter canAddInput:audioTrackInput]) {
        [assetWriter addInput:audioTrackInput];
    }
    if ([assetWriter canAddInput:videoTrackInput]) {
        [assetWriter addInput:videoTrackInput];
    }
    
    
    //    [self startAssetReaderAndWriter:nil];
    
#pragma mark ==========================================
    
    [self.assetReader startReading];
    [self.assetWriter startWriting];
    
    self.dispatchGroup = dispatch_group_create();
    [self.assetWriter startSessionAtSourceTime:CMTimeMake(2, 1)];
    
    self.audioFinished = NO;
    self.videoFinished = NO;
    
    dispatch_group_enter(self.dispatchGroup);
    [audioTrackInput requestMediaDataWhenReadyOnQueue:audioQueue usingBlock:^{
        BOOL completedOrFailed = NO;
        while ([self.assetWriterAudioInput isReadyForMoreMediaData] && !completedOrFailed) {
            CMSampleBufferRef sampleBuffer = [self.assetReaderAudioOutput copyNextSampleBuffer];
            if (sampleBuffer != NULL) {
                BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                sampleBuffer = NULL;
                completedOrFailed = !success;
            } else {
                completedOrFailed = YES;
            }
        }
        if (completedOrFailed) {
            BOOL oldfinished = self.audioFinished;
            self.audioFinished = YES;
            if (oldfinished == NO) {
                [self.assetWriterAudioInput markAsFinished];
            }
            dispatch_group_leave(self.dispatchGroup);
        }
    }];
    
    dispatch_group_enter(self.dispatchGroup);
    [videoTrackInput requestMediaDataWhenReadyOnQueue:videoQueue usingBlock:^{
        while ([videoTrackInput isReadyForMoreMediaData] && !self.videoFinished) {
            CMSampleBufferRef sampleBuffer = [videoTrackOutput copyNextSampleBuffer];
            if (sampleBuffer != NULL) {
                [videoTrackInput appendSampleBuffer:sampleBuffer];
                sampleBuffer = NULL;
            } else {
                self.videoFinished = YES;
                [videoTrackInput markAsFinished];
                dispatch_group_leave(self.dispatchGroup);
            }
        }
    }];
    dispatch_group_notify(self.dispatchGroup, self.mainSerializationQueue, ^{
        BOOL finalSuccess = YES;
        NSError *finalError = nil;
        if (self.cancelled) {
            [self.assetReader cancelReading];
            [self.assetWriter cancelWriting];
        } else {
            if ([self.assetReader status] == AVAssetReaderStatusFailed) {
                finalSuccess = NO;
                finalError = [self.assetReader error];
            }
            if (finalSuccess) {
                finalSuccess = [self.assetWriter finishWriting];
                if (!finalSuccess) {
                    finalError = [self.assetWriter error];
                }
            }
            [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
        }
    });
    
}

- (void)viewDidLoad_01 {
    [super viewDidLoad];
    
    NSString *serializationQueueDescription = [NSString stringWithFormat:@"%@ serialization queue", self];
    // Create the main serialization queue.
    self.mainSerializationQueue = dispatch_queue_create([serializationQueueDescription UTF8String], NULL);
    
    // Create the serialization queue to use for reading and writing the audio data.
    NSString *rwAudioSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw audio serialization queue", self];
    self.rwAudioSerializationQueue = dispatch_queue_create([rwAudioSerializationQueueDescription UTF8String], NULL);
    // Create the serialization queue to use for reading and writing the video data.
    NSString *rwVideoSerializationQueueDescription = [NSString stringWithFormat:@"%@ rw video serialization queue", self];
    self.rwVideoSerializationQueue = dispatch_queue_create([rwVideoSerializationQueueDescription UTF8String], NULL);
    
    self.asset = [AVAsset assetWithURL:[[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"]];
    self.cancelled = NO;
    
    NSString *outputPath = [NSString stringWithFormat:@"%@/output.mov", NSHomeDirectory()];
    self.outputURL = [NSURL fileURLWithPath:outputPath];
    NSLog(@"Output to here: %@", self.outputURL);
    
    //    [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
    if (self.cancelled) {
        return;
    }
    BOOL success = YES;
    NSError *localError = nil;
    //        success = [self.asset statusOfValueForKey:@"tracks" error:&localError] == AVKeyValueStatusLoaded;
    if (success) {
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *localOutputPath = [self.outputURL path];
        if ([fm fileExistsAtPath:localOutputPath]) {
            success = [fm removeItemAtPath:localOutputPath error:&localError];
        }
        if (success) {
            success = [self setupAssetReaderAndAssetWriter:&localError];
        }
        if (success) {
            success = [self startAssetReaderAndWriter:&localError];
        }
        if (!success) {
            [self readingAndWritingDidFinishSuccessfully:success withError:localError];
        }
    }
    //    }];
}

- (BOOL)setupAssetReaderAndAssetWriter:(NSError **)outError
{
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:outError];
    BOOL success = self.assetReader != nil;
    if (success) {
        // If the asset reader was successfully initialized, do the same for the asset writer.
        self.assetWriter = [[AVAssetWriter alloc] initWithURL:self.outputURL fileType:AVFileTypeQuickTimeMovie error:outError];
        success = self.assetWriter != nil;
    }
    if (success) {
        // If the reader and writer were successfully initialized, grab the audio and video asset tracks that will be used.
        AVAssetTrack *assetAudioTrack = nil, *assetVideoTrack = nil;
        NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
        if ([audioTracks count] > 0) {
            assetAudioTrack = [audioTracks firstObject];
        }
        NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
        if ([videoTracks count] > 0) {
            assetVideoTrack = [videoTracks firstObject];
        }
        
        if (assetAudioTrack) {
            // If there is an audio track to read, set the decompression settings to Linear PCM and create the asset reader output.
            NSDictionary *decompressionAudioSettings = @{
                                                         AVFormatIDKey:[NSNumber numberWithUnsignedInt:kAudioFormatLinearPCM]
                                                         };
            self.assetReaderAudioOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetAudioTrack outputSettings:decompressionAudioSettings];
            [self.assetReader addOutput:self.assetReaderAudioOutput];
            // Then, set the compression settings to 128kbps AAC and create the asset writer input.
            AudioChannelLayout stereoChannelLayout = {
                .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
                .mChannelBitmap = 0,
                .mNumberChannelDescriptions = 0
            };
            NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
            NSDictionary *compressionAudioSettings = @{
                                                       AVFormatIDKey: [NSNumber numberWithUnsignedInt:kAudioFormatMPEG4AAC],
                                                       AVEncoderBitRateKey: [NSNumber numberWithInteger:128000],
                                                       AVSampleRateKey: [NSNumber numberWithInteger:44100],
                                                       AVChannelLayoutKey: channelLayoutAsData,
                                                       AVNumberOfChannelsKey: [NSNumber numberWithUnsignedInteger:2]
                                                       };
            self.assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetAudioTrack mediaType] outputSettings:compressionAudioSettings];
            [self.assetWriter addInput:self.assetWriterAudioInput];
        }
        if (assetVideoTrack) {
            NSDictionary *decompressionVideoSetting = @{
                                                        (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_422YpCbCr8],
                                                        (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey:[NSDictionary dictionary]
                                                        };
            self.assetReaderVideoOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:assetVideoTrack outputSettings:decompressionVideoSetting];
            [self.assetReader addOutput:self.assetReaderVideoOutput];
            
            CMFormatDescriptionRef formatDescription = NULL;
            // Grab the video format descriptions from the video track and grab the first one if it exists.
            NSArray *videoFormatDescriptions = [assetVideoTrack formatDescriptions];
            if ([videoFormatDescriptions count] > 0) {
                formatDescription = (__bridge CMFormatDescriptionRef)[videoFormatDescriptions firstObject];
            }
            CGSize trackDimensions = {
                .width = 0.0,
                .height = 0.0
            };
            // If the video track had a format description, grab the track dimensions from there. Otherwise, grab them direcly from the track itself.
            if (formatDescription) {
                trackDimensions = CMVideoFormatDescriptionGetPresentationDimensions(formatDescription, false, false);
            } else {
                trackDimensions = [assetVideoTrack naturalSize];
            }
            NSDictionary *compressionSettings = nil;
            if (formatDescription) {
                NSDictionary *cleanAperture = nil;
                NSDictionary *pixelAspectRatio = nil;
                CFDictionaryRef cleanApertureFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_CleanAperture);
                if (cleanApertureFromCMFormatDescription) {
                    cleanAperture = @{
                                      AVVideoCleanApertureWidthKey: (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureWidth),
                                      AVVideoCleanApertureHeightKey: (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHeight),
                                      AVVideoCleanApertureHorizontalOffsetKey:(id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureHorizontalOffset),
                                      AVVideoCleanApertureVerticalOffsetKey: (id)CFDictionaryGetValue(cleanApertureFromCMFormatDescription, kCMFormatDescriptionKey_CleanApertureVerticalOffset)
                                      };
                }
                CFDictionaryRef pixelAspectRatioFromCMFormatDescription = CMFormatDescriptionGetExtension(formatDescription, kCMFormatDescriptionExtension_PixelAspectRatio);
                if (pixelAspectRatioFromCMFormatDescription) {
                    pixelAspectRatio = @{
                                         AVVideoPixelAspectRatioHorizontalSpacingKey: (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioHorizontalSpacing),
                                         AVVideoPixelAspectRatioVerticalSpacingKey: (id)CFDictionaryGetValue(pixelAspectRatioFromCMFormatDescription, kCMFormatDescriptionKey_PixelAspectRatioVerticalSpacing)
                                         };
                }
                if (cleanAperture || pixelAspectRatio) {
                    NSMutableDictionary *mutableCompressionSettings = [[NSMutableDictionary alloc] init];
                    if (cleanAperture) {
                        [mutableCompressionSettings setObject:cleanAperture forKey:AVVideoCleanApertureKey];
                    }
                    if (pixelAspectRatio) {
                        [mutableCompressionSettings setObject:pixelAspectRatio forKey:AVVideoPixelAspectRatioKey];
                    }
                    compressionSettings = mutableCompressionSettings;
                }
            }
            NSMutableDictionary *videoSettings = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                                   AVVideoCodecKey: AVVideoCodecH264,
                                                                                                   AVVideoWidthKey: [NSNumber numberWithDouble:trackDimensions.width * 0.5],
                                                                                                   AVVideoHeightKey:[NSNumber numberWithDouble:trackDimensions.height * 0.5]
                                                                                                   }];
            if (compressionSettings) {
                [videoSettings setObject:compressionSettings forKey:AVVideoCompressionPropertiesKey];
            }
            self.assetWriterVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:[assetVideoTrack mediaType] outputSettings:videoSettings];
            [self.assetWriter addInput:self.assetWriterVideoInput];
        }
    }
    return success;
}

- (BOOL)startAssetReaderAndWriter:(NSError **)outError
{
    BOOL success = YES;
    success = [self.assetReader startReading];
    if (!success) {
        *outError = [self.assetReader error];
    }
    if (success) {
        success = [self.assetWriter startWriting];
        if (!success) {
            *outError = [self.assetWriter error];
        }
    }
    if (success) {
        self.dispatchGroup = dispatch_group_create();
        [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
        self.audioFinished = NO;
        self.videoFinished = NO;
        if (self.assetWriterAudioInput) {
            dispatch_group_enter(self.dispatchGroup);
            [self.assetWriterAudioInput requestMediaDataWhenReadyOnQueue:self.rwAudioSerializationQueue usingBlock:^{
                if (self.audioFinished) {
                    return;
                }
                BOOL completedOrFailed = NO;
                while ([self.assetWriterAudioInput isReadyForMoreMediaData] && !completedOrFailed) {
                    CMSampleBufferRef sampleBuffer = [self.assetReaderAudioOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL) {
                        BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                    } else {
                        completedOrFailed = YES;
                    }
                }
                if (completedOrFailed) {
                    BOOL oldfinished = self.audioFinished;
                    self.audioFinished = YES;
                    if (oldfinished == NO) {
                        [self.assetWriterAudioInput markAsFinished];
                    }
                    dispatch_group_leave(self.dispatchGroup);
                }
            }];
        }
        if (self.assetWriterVideoInput) {
            dispatch_group_enter(self.dispatchGroup);
            [self.assetWriterVideoInput requestMediaDataWhenReadyOnQueue:self.rwVideoSerializationQueue usingBlock:^{
                if (self.videoFinished) {
                    return;
                }
                BOOL completedOrFailed = NO;
                while ([self.assetWriterVideoInput isReadyForMoreMediaData] && !completedOrFailed) {
                    CMSampleBufferRef sampleBuffer = [self.assetReaderVideoOutput copyNextSampleBuffer];
                    if (sampleBuffer != NULL) {
                        BOOL success = [self.assetWriterVideoInput appendSampleBuffer:sampleBuffer];
                        CFRelease(sampleBuffer);
                        sampleBuffer = NULL;
                        completedOrFailed = !success;
                    } else {
                        completedOrFailed = YES;
                    }
                }
                if (completedOrFailed) {
                    BOOL oldFinished = self.videoFinished;
                    self.videoFinished = YES;
                    if (oldFinished == NO) {
                        [self.assetWriterVideoInput markAsFinished];
                    }
                    dispatch_group_leave(self.dispatchGroup);
                }
            }];
        }
        
        dispatch_group_notify(self.dispatchGroup, self.mainSerializationQueue, ^{
            BOOL finalSuccess = YES;
            NSError *finalError = nil;
            if (self.cancelled) {
                [self.assetReader cancelReading];
                [self.assetWriter cancelWriting];
            } else {
                if ([self.assetReader status] == AVAssetReaderStatusFailed) {
                    finalSuccess = NO;
                    finalError = [self.assetReader error];
                }
                if (finalSuccess) {
                    finalSuccess = [self.assetWriter finishWriting];
                    if (!finalSuccess) {
                        finalError = [self.assetWriter error];
                    }
                }
                [self readingAndWritingDidFinishSuccessfully:finalSuccess withError:finalError];
            }
        });
    }
    return YES;
}

- (void)readingAndWritingDidFinishSuccessfully:(BOOL)success withError:(NSError *)error
{
    if (!success) {
        [self.assetReader cancelReading];
        [self.assetWriter cancelWriting];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Update UI here of fail!");
        });
    } else {
        self.cancelled = NO;
        self.videoFinished = NO;
        self.audioFinished = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Update UI here of success!");
        });
    }
}

- (void)cancel
{
    dispatch_async(self.mainSerializationQueue, ^{
        if (self.assetWriterAudioInput) {
            dispatch_async(self.rwAudioSerializationQueue, ^{
                BOOL oldFindshed = self.audioFinished;
                self.audioFinished = YES;
                if (oldFindshed == NO) {
                    [self.assetWriterAudioInput markAsFinished];
                }
                dispatch_group_leave(self.dispatchGroup);
            });
        }
        if (self.assetWriterVideoInput) {
            dispatch_async(self.rwVideoSerializationQueue, ^{
                BOOL oldFinished = self.videoFinished;
                self.videoFinished = YES;
                if (oldFinished == NO) {
                    [self.assetWriterVideoInput markAsFinished];
                }
                dispatch_group_leave(self.dispatchGroup);
            });
        }
        self.cancelled = YES;
    });
}

//Asset Output Settings Assistant
- (void)assetOutputSettingAssistant
{
    
    //    NSArray *array = [AVOutputSettingsAssistant availableOutputSettingsPresets];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"demo" withExtension:@"mp4"];
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    CMFormatDescriptionRef formatDescription = (__bridge CMFormatDescriptionRef)([[videoTrack formatDescriptions] firstObject]);
    
    AVOutputSettingsAssistant *outputSettingAssistant = [AVOutputSettingsAssistant outputSettingsAssistantWithPreset:AVOutputSettingsPreset1280x720];
    //    CMFormatDescriptionRef audioFormat = [self getAudioFormat]
    CMFormatDescriptionRef audioFormat = NULL;
    if (audioFormat != NULL) {
        [outputSettingAssistant setSourceAudioFormat:(CMAudioFormatDescriptionRef)audioFormat];
    }
    //    CMFormatDescriptionRef videoFormat = [self getVidoFormat]
    CMFormatDescriptionRef videoFormat = formatDescription;
    if (videoFormat != NULL) {
        [outputSettingAssistant setSourceVideoFormat:(CMVideoFormatDescriptionRef)videoFormat];
    }
    //    CMTime assetMinVideoFrameDuration = [self getMinFrameDuration];
    CMTime assetMinVideoFrameDuration;
    //    CMTime averageFrameDuration = [self getAvgFrameDuration];
    CMTime averageFrameDuration = CMTimeMake(1, 30);
    if (CMTimeCompare(averageFrameDuration, kCMTimeZero) != 0) {
        [outputSettingAssistant setSourceVideoAverageFrameDuration:averageFrameDuration];
    }
    
    if (CMTimeCompare(assetMinVideoFrameDuration, kCMTimeZero) != 0) {
        [outputSettingAssistant setSourceVideoMinFrameDuration:assetMinVideoFrameDuration];
    }
    
    NSLog(@"Audio Setting = %@", [outputSettingAssistant audioSettings]);
    //    AVAssetWriterInput *audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[outputSettingAssistant audioSettings] sourceFormatHint:audioFormat];
    NSLog(@"Video Setting = %@", [outputSettingAssistant videoSettings]);
    //    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[outputSettingAssistant videoSettings] sourceFormatHint:videoFormat];
}

- (void)test1
{
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVAsset *localAsset = [AVAsset assetWithURL:url];
    
    NSError *outError;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:localAsset error:&outError];
    BOOL success = (assetReader != nil);
    
    if (success) {
        AVAssetTrack *audioTrack = [[localAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        NSDictionary *decompressionAudioSettings = @{AVFormatIDKey: @(kAudioFormatLinearPCM)};
        AVAssetReaderOutput *trackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:decompressionAudioSettings];
        if ([assetReader canAddOutput:trackOutput]) {
            [assetReader addOutput:trackOutput];
        }
        
        //AVAssetReaderAudioMixOutput
        //        AVAudioMix *audioMix;
        //        AVComposition *composition = (AVComposition *)assetReader.asset;
        //        NSArray *audioTracks = [composition tracksWithMediaType:AVMediaTypeAudio];
        //        decompressionAudioSettings = @{AVFormatIDKey: @(kAudioFormatLinearPCM)};
        //        AVAssetReaderAudioMixOutput *audioMixOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:decompressionAudioSettings];
        //        audioMixOutput.audioMix = audioMix;
        //        if ([assetReader canAddOutput:audioMixOutput]) {
        //            [assetReader addOutput:audioMixOutput];
        //        }
        
        //AVAssetReaderVideoCompositionOutput
        //        AVVideoComposition *videoComposition;
        //        // Assumes assetReader was initialized with an AVComposition.
        //        AVComposition *composition = (AVComposition *)assetReader.asset;
        //        NSArray *videoTracks = [composition tracksWithMediaType:AVMediaTypeVideo];
        //        NSDictionary *decompressVideoSetting = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB), (__bridge NSString *)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]};
        //        AVAssetReaderVideoCompositionOutput *videoCompositionOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:decompressionAudioSettings];
        //        videoCompositionOutput.videoComposition = videoComposition;
        //        if ([assetReader canAddOutput:videoCompositionOutput]) {
        //            [assetReader addOutput:videoCompositionOutput];
        //        }
        [assetReader startReading];
        BOOL done = NO;
        while (!done) {
            CMSampleBufferRef sampleBuffer = [trackOutput copyNextSampleBuffer];
            if (sampleBuffer) {
                NSLog(@"%@", sampleBuffer);
                CFRelease(sampleBuffer);
                sampleBuffer = NULL;
            } else {
                if (assetReader.status == AVAssetReaderStatusFailed) {
                    NSError *failureError = assetReader.error;
                    NSLog(@"read error: %@", failureError);
                } else {
                    done = YES;
                }
            }
        }
    } else {
        NSLog(@"初始化AVAssetReader失败");
    }
    
}

- (void)test2
{
    //    Each AVAssetWriterInput object expects to receive data in the form of CMSampleBufferRef objects, but if you want to append CVPixelBufferRef objects to your asset writer input, use the AVAssetWriterInputPixelBufferAdaptor class.
    NSError *outError;
    
    NSString *path = [NSString stringWithFormat:@"%@/test.mov", NSHomeDirectory()];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    NSLog(@"%@", path);
    
    NSURL *outputURL = [NSURL fileURLWithPath:path];
    
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeQuickTimeMovie error:&outError];
    BOOL success = (assetWriter != nil);
    
    AudioChannelLayout stereoChannelLayout = {
        .mChannelLayoutTag = kAudioChannelLayoutTag_Stereo,
        .mChannelBitmap = 0,
        .mNumberChannelDescriptions = 0
    };
    NSData *channelLayoutAsData = [NSData dataWithBytes:&stereoChannelLayout length:offsetof(AudioChannelLayout, mChannelDescriptions)];
    NSDictionary *compressionAudioSettings = @{
                                               AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                                               AVEncoderBitRateKey:@(12800),
                                               AVSampleRateKey:@(44100),
                                               AVChannelLayoutKey: channelLayoutAsData,
                                               AVNumberOfChannelsKey:@(2)
                                               };
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:compressionAudioSettings];
    if ([assetWriter canAddInput:assetWriterInput]) {
        [assetWriter addInput:assetWriterInput];
    }
    
    NSDictionary *pixelBufferAttributes = @{(__bridge NSString *)kCVPixelBufferCGImageCompatibilityKey: @(YES),(__bridge NSString *)kCVPixelBufferCGBitmapContextCompatibilityKey: @(YES),
                                            (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32ARGB)
                                            };
    AVAssetWriterInputPixelBufferAdaptor *inputPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterInput sourcePixelBufferAttributes:pixelBufferAttributes];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"ElephantSeals" withExtension:@"mov"];
    AVAsset *localAsset = [AVAsset assetWithURL:url];
    
    //    CMTime halfAssetDuration = CMTimeMultiplyByFloat64(localAsset.duration, 0.5);
    //    [assetWriter startSessionAtSourceTime:halfAssetDuration];
    [assetWriter startWriting];
    [assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t inputSerialQueue = dispatch_queue_create("inputSerialQueue", DISPATCH_QUEUE_SERIAL);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:inputSerialQueue usingBlock:^{
        while ([assetWriterInput isReadyForMoreMediaData]) {
            CMSampleBufferRef nextSampleBuffer = [self copyNextSampleBufferToWrite];
            if (nextSampleBuffer) {
                [assetWriterInput appendSampleBuffer:nextSampleBuffer];
                CFRelease(nextSampleBuffer);
                nextSampleBuffer = nil;
            } else {
                [assetWriterInput markAsFinished];
                break;
            }
        }
    }];
}

- (CMSampleBufferRef)copyNextSampleBufferToWrite
{
    return nil;
}

@end
