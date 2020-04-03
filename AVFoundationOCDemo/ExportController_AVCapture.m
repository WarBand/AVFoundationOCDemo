//
//  ExportController.m
//  AVFoundationOCDemo
//
//  Created by Bytebaker on 17/2/21.
//  Copyright © 2017年 bytebaker. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "ExportController_AVCapture.h"

@interface ExportController_AVCapture ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVAssetWriter *assetWriter;

@property (nonatomic, strong) AVAssetWriterInput *assetWriterAudioInput;
@property (nonatomic, strong) AVAssetWriterInput *assetWriterVideoInput;

//AVCapture
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) dispatch_queue_t captureOutputQueue;
@property (nonatomic, strong) AVAssetWriter *captureWriter;
@property (nonatomic, strong) AVAssetWriterInput *caputureWriterInput;

@end

@implementation ExportController_AVCapture

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.captureOutputQueue = dispatch_queue_create("AVCapture Output Queue", NULL);
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    self.captureSession = session;
    
    AVCaptureDevice *inputDevice;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == AVCaptureDevicePositionBack) {
            inputDevice = device;
            break;
        }
    }
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:nil];
    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//    NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,nil];
    [output setSampleBufferDelegate:self queue:self.captureOutputQueue];
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
    
    AVCaptureVideoPreviewLayer *layer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    [self.view.layer addSublayer:layer];
    layer.frame = [UIScreen mainScreen].bounds;
    
    [session startRunning];
    
    //导出
    NSString *path = [NSString stringWithFormat:@"%@demo.%@", NSTemporaryDirectory(), CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef _Nonnull)(AVFileTypeMPEG4), (CFStringRef)kUTTagClassFilenameExtension))];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    NSURL *url = [NSURL fileURLWithPath:path];
    NSLog(@"%@", path);
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
    self.captureWriter = assetWriter;
    
    AVAssetWriterInput *videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:[self configVideoInput]];
    self.caputureWriterInput = videoInput;
    self.caputureWriterInput.expectsMediaDataInRealTime = YES;
    [self.captureWriter addInput:videoInput];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(50, 200, 100, 100)];
    [self.view addSubview:button];
    button.backgroundColor = [UIColor redColor];
    [button addTarget:self action:@selector(record) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *button1 = [[UIButton alloc] initWithFrame:CGRectMake(200, 200, 100, 100)];
    [self.view addSubview:button1];
    button1.backgroundColor = [UIColor blueColor];
    [button1 addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
}

- (void)record
{
    [self.captureWriter startWriting];
    [self.captureWriter startSessionAtSourceTime:kCMTimeZero];
}

- (void)stop
{
    [self.captureSession stopRunning];
        [self.captureWriter finishWritingWithCompletionHandler:^{
            NSLog(@"+++++");
        }];
//    });
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    BOOL isVideo = YES;
    @synchronized(self) {
        //初始化编码器，当有音频和视频参数时创建编码器

        //判断是否中断录制过
//        if (self.discont) {
//            if (isVideo) {
//                return;
//            }
//            self.discont = NO;
            // 计算暂停的时间
//            CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//            CMTime last = isVideo ? _lastVideo : _lastAudio;
//            if (last.flags & kCMTimeFlags_Valid) {
//                if (_timeOffset.flags & kCMTimeFlags_Valid) {
//                    pts = CMTimeSubtract(pts, _timeOffset);
//                }
//                CMTime offset = CMTimeSubtract(pts, last);
//                if (_timeOffset.value == 0) {
//                    _timeOffset = offset;
//                }else {
//                    _timeOffset = CMTimeAdd(_timeOffset, offset);
//                }
//            }
//            _lastVideo.flags = 0;
//            _lastAudio.flags = 0;
//        }
        // 增加sampleBuffer的引用计时,这样我们可以释放这个或修改这个数据，防止在修改时被释放
        CFRetain(sampleBuffer);
//        if (_timeOffset.value > 0) {
//            CFRelease(sampleBuffer);
//            //根据得到的timeOffset调整
//            sampleBuffer = [self adjustTime:sampleBuffer by:_timeOffset];
//        }
        // 记录暂停上一次录制的时间
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        CMTime dur = CMSampleBufferGetDuration(sampleBuffer);
        if (dur.value > 0) {
            pts = CMTimeAdd(pts, dur);
        }
//        if (isVideo) {
//            _lastVideo = pts;
//        }else {
//            _lastAudio = pts;
//        }
    }
    CMTime dur = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//    if (self.startTime.value == 0) {
//        self.startTime = dur;
//    }
//    CMTime sub = CMTimeSubtract(dur, self.startTime);
//    self.currentRecordTime = CMTimeGetSeconds(sub);
//    if (self.currentRecordTime > self.maxRecordTime) {
//        if (self.currentRecordTime - self.maxRecordTime < 0.1) {
//            if ([self.delegate respondsToSelector:@selector(recordProgress:)]) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self.delegate recordProgress:self.currentRecordTime/self.maxRecordTime];
//                });
//            }
//        }
//        return;
//    }
    // 进行数据编码
    [self encodeFrame:sampleBuffer isVideo:isVideo];
    CFRelease(sampleBuffer);
    
    
//    NSLog(@"didOutputSampleBuffer");
//    if (CMSampleBufferDataIsReady(sampleBuffer) && [self.caputureWriterInput isReadyForMoreMediaData]) {
//        CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//        if (self.captureWriter.status == AVAssetWriterStatusUnknown) {
//            //开始写入
//            [self.captureWriter startWriting];
//            [self.captureWriter startSessionAtSourceTime:startTime];
//        } else {
//            [self.caputureWriterInput appendSampleBuffer:sampleBuffer];
//        }
//        
//    }
}


//通过这个方法写入数据
- (BOOL)encodeFrame:(CMSampleBufferRef) sampleBuffer isVideo:(BOOL)isVideo {
    //数据是否准备写入
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        //写入状态为未知,保证视频先写入
        if (_captureWriter.status == AVAssetWriterStatusUnknown && isVideo) {
            //获取开始写入的CMTime
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            //开始写入
            [_captureWriter startWriting];
            [_captureWriter startSessionAtSourceTime:startTime];
        }
        //写入失败
        if (_captureWriter.status == AVAssetWriterStatusFailed) {
            NSLog(@"writer error %@", _captureWriter.error.localizedDescription);
            return NO;
        }
        //判断是否是视频
        if (isVideo) {
            //视频输入是否准备接受更多的媒体数据
            if (_caputureWriterInput.readyForMoreMediaData == YES) {
                //拼接数据
                [_caputureWriterInput appendSampleBuffer:sampleBuffer];
                return YES;
            }
        }else {
            //音频输入是否准备接受更多的媒体数据
//            if (_audioInput.readyForMoreMediaData) {
//                //拼接数据
//                [_audioInput appendSampleBuffer:sampleBuffer];
//                return YES;
//            }
        }
    }
    return NO;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"didDropSampleBuffer");
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
@end
