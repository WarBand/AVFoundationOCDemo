//
//  CaptureController.m
//  AVFoundationOCDemo
//
//  Created by SouFun on 17/2/20.
//  Copyright © 2017年 bytebaker. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <CoreLocation/CoreLocation.h>
#import "CaptureController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

#define LOGFUNC NSLog(@"%s", __FUNCTION__)

typedef enum : NSUInteger {
    CaptureTypeImage,
    CaptureTypeVideo,
    CaptureTypeAudio
} CaptureType;

typedef enum : NSUInteger {
    CameraTypeBack,
    CameraTypeFront
}CameraType;

@interface CaptureController ()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDevice *backCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *backCameraInput;
@property (nonatomic, strong) AVCaptureDevice *frontCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *frontCameraInput;
@property (nonatomic, strong) AVCaptureDevice *audioRecorder;
@property (nonatomic, strong) AVCaptureDeviceInput *audioRecorderInput;

@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieOutput;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, weak) IBOutlet UISegmentedControl *typeSelectView;
@property (nonatomic, assign) CaptureType captureType;
@property (weak, nonatomic) IBOutlet UIButton *beginButton;
@property (nonatomic, assign) CameraType cameraType;

@property (nonatomic, strong) dispatch_queue_t videoOutputQueue;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) dispatch_queue_t audioOutputQueue;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;

@end

@implementation CaptureController

- (void)setCameraType:(CameraType)type
{
    _cameraType = type;
    switch (_cameraType) {
        case CameraTypeBack:
        {
            if ([self.captureSession.inputs containsObject:self.backCameraInput]) {
                break;
            } else {
                for (AVCaptureInput *input in self.captureSession.inputs) {
                    [self.captureSession removeInput:input];
                }
                if ([self.captureSession canAddInput:self.backCameraInput]) {
                    [self.captureSession addInput:self.backCameraInput];
                }
            }
        }
            break;
        case CameraTypeFront:
            if ([self.captureSession.inputs containsObject:self.frontCameraInput]) {
                break;
            } else {
                for (AVCaptureInput *input in self.captureSession.inputs) {
                    [self.captureSession removeInput:input];
                }
                if ([self.captureSession canAddInput:self.frontCameraInput]) {
                    [self.captureSession addInput:self.frontCameraInput];
                }
            }
            break;
        default:
            break;
    }
}

- (void)setCaptureType:(CaptureType)type
{
    _captureType = type;
    switch (_captureType) {
        case CaptureTypeImage:
            self.beginButton.backgroundColor = [UIColor whiteColor];
            if ([self.captureSession.outputs containsObject:self.imageOutput]) {
                break;
            } else {
                [self.captureSession beginConfiguration];
                for (AVCaptureOutput *output in self.captureSession.outputs) {
                    [self.captureSession removeOutput:output];
                }
                if ([self.captureSession canAddOutput:self.imageOutput]) {
                    [self.captureSession addOutput:self.imageOutput];
                }
                [self.captureSession commitConfiguration];
            }
            break;
        case CaptureTypeVideo:
            self.beginButton.backgroundColor = [UIColor redColor];
            if ([self.captureSession.outputs containsObject:self.movieOutput]) {
                break;
            } else {
                [self.captureSession beginConfiguration];
                for (AVCaptureOutput *output in self.captureSession.outputs) {
                    [self.captureSession removeOutput:output];
                }
                if ([self.captureSession canAddOutput:self.movieOutput]) {
                    [self.captureSession addOutput:self.movieOutput];
                }
                [self.captureSession commitConfiguration];
            }
            if ([self.captureSession.inputs containsObject:self.audioRecorderInput]) {
                break;
            } else {
                [self.captureSession beginConfiguration];
                if ([self.captureSession canAddInput:self.audioRecorderInput]) {
                    [self.captureSession addInput:self.audioRecorderInput];
                }
                [self.captureSession commitConfiguration];
            }
            break;
        case CaptureTypeAudio:
            self.beginButton.backgroundColor = [UIColor blueColor];
            if ([self.captureSession.outputs containsObject:self.movieOutput]) {
                break;
            } else {
                [self.captureSession beginConfiguration];
                for (AVCaptureOutput *output in self.captureSession.outputs) {
                    [self.captureSession removeOutput:output];
                }
                if ([self.captureSession canAddOutput:self.movieOutput]) {
                    [self.captureSession addOutput:self.movieOutput];
                }
                [self.captureSession commitConfiguration];
            }
            if ([self.captureSession.inputs containsObject:self.audioRecorderInput]) {
                break;
            } else {
                [self.captureSession beginConfiguration];
                if ([self.captureSession canAddInput:self.audioRecorderInput]) {
                    [self.captureSession addInput:self.audioRecorderInput];
                }
                [self.captureSession commitConfiguration];
            }
            break;
        default:
            break;
    }
}

- (IBAction)typeChanged:(UISegmentedControl *)sender {
    self.captureType = sender.selectedSegmentIndex;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
    self.cameraType = CameraTypeFront;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    [self showView];
}

- (void)showView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    view.backgroundColor = [UIColor redColor];
    [self.view addSubview:view];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [view removeFromSuperview];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    //Monitoring Capture Session State
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(monitoringCaptureSessionState:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasConnected:) name:AVCaptureDeviceWasConnectedNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasDisconnected:) name:AVCaptureDeviceWasConnectedNotification object:nil];
//    
//    //Config AVCaptureSession
//    AVCaptureSession *session = [[AVCaptureSession alloc] init];
//    
//    [session beginConfiguration];
//    if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
//        [session setSessionPreset:AVCaptureSessionPreset1280x720];
//    }
//    [session commitConfiguration];
//    
//    self.captureSession = session;
//    //Config AVCaptureDeviceVideo
//    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//    for (AVCaptureDevice *device in devices) {
//        if (device.position == AVCaptureDevicePositionBack) {
//            self.backCamera = device;
//            self.backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
//            //观察这个属性，可以获取输入已经呈现的时机
//            [self.captureSession addObserver:self forKeyPath:@"inputs" options:NSKeyValueObservingOptionNew context:nil];
//            
//        } else if (device.position == AVCaptureDevicePositionFront) {
//            self.frontCamera = device;
//            self.frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:nil];
//        } else {
//            //do nothing
//        }
//    }
//    //Config AVCaptureDeviceAudio
//    devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
//    if ([devices count] > 0) {
//        self.audioRecorder = [devices firstObject];
//        self.audioRecorderInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.audioRecorder error:nil];
//        if ([self.captureSession canAddInput:self.audioRecorderInput]) {
//            [self.captureSession addInput:self.audioRecorderInput];
//        }
//    }
//    //Config AVCaptureOutput
//    //1.StillImageOutput
//    AVCaptureStillImageOutput *stillOutput = [[AVCaptureStillImageOutput alloc] init];
//    self.imageOutput = stillOutput;
//    NSDictionary *imageSetting = @{AVVideoCodecKey: AVVideoCodecJPEG};
//    [self.imageOutput setOutputSettings:imageSetting];
//    
//    //2.MovieOutput
//    AVCaptureMovieFileOutput *movieOutput = [[AVCaptureMovieFileOutput alloc] init];
//    self.movieOutput = movieOutput;
    
    //3.AudioOutput
//    AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
//    self.audioOutputQueue = dispatch_queue_create("audioOutputQueue", NULL);
//    if ([self.captureSession canAddOutput:audioDataOutput]) {
//        [self.captureSession addOutput:audioDataOutput];
//    }
//    self.audioDataOutput = audioDataOutput;
//    [self.audioDataOutput setSampleBufferDelegate:self queue:self.audioOutputQueue];
    
    //4.VideoOutput
//    AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
//    self.videoOutputQueue = dispatch_queue_create("videoOutputQueue", NULL);
//    if ([self.captureSession canAddOutput:videoDataOutput]) {
//        [self.captureSession addOutput:videoDataOutput];
//    }
//    self.videoDataOutput = videoDataOutput;
//    [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoOutputQueue];
    
//    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
//    self.previewLayer.frame = [UIScreen mainScreen].bounds;
//    [self.view.layer addSublayer:self.previewLayer];
//    
//    for (UIView *subView in self.view.subviews) {
//        [self.view bringSubviewToFront:subView];
//    }
//    
//    if ([self.captureSession canAddInput:self.backCameraInput]) {
//        [self.captureSession addInput:self.backCameraInput];
//    }
//    if ([self.captureSession canAddOutput:self.imageOutput]) {
//        [self.captureSession addOutput:self.imageOutput];
//    }
//    [self.captureSession startRunning];
    
    //录音
    [UIDevice currentDevice].proximityMonitoringEnabled = YES;
    if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0"] != NSOrderedAscending) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *sessionError;
        
        //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
//        if ([[UIDevice currentDevice] proximityState] == YES)
//        {
//            NSLog(@"Device is close to user");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
//        }
//        else
//        {
//            NSLog(@"Device is not close to user");
//            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
//        }
        
        
        if (session == nil) {
            NSLog(@"Error creating session: %@", sessionError);
        } else {
            [session setActive:YES error:nil];
        }
    }
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *playName = [NSString stringWithFormat:@"%@/play.acc", docDir];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:playName]) {
        [[NSFileManager defaultManager] removeItemAtPath:playName error:nil];
    }
    
    NSDictionary *recorderSettingsDict = @{
                                           AVFormatIDKey:@(kAudioFormatMPEG4AAC),
                                           AVSampleRateKey: @(44100),
                                           AVNumberOfChannelsKey:@(2),
                                           AVLinearPCMBitDepthKey:@(8),
                                           AVLinearPCMIsBigEndianKey:@(NO),
                                           AVLinearPCMIsFloatKey:@(NO)
                                           };
    NSError *error = nil;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:playName] settings:recorderSettingsDict error:&error];
    if (self.recorder) {
        self.recorder.meteringEnabled = YES;
        [self.recorder prepareToRecord];
        [self.recorder record];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.recorder stop];
            
            //如果此时手机靠近面部放在耳朵旁，那么声音将通过听筒输出，并将屏幕变暗（省电啊）
                    if ([[UIDevice currentDevice] proximityState] == YES)
                    {
                        NSLog(@"Device is close to user");
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
                    }
                    else
                    {
                        NSLog(@"Device is not close to user");
                        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                    }
            
            self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:playName] error:nil];
//            [self.audioPlayer prepareToPlay];
            [self.audioPlayer play];
        });
    }
    
}

- (IBAction)getContent
{
    switch (self.captureType) {
        case CaptureTypeImage:
            [self captureImage];
            break;
        case CaptureTypeVideo:
            [self captureVideo];
        default:
            break;
    }
}

- (void)captureVideo
{
    if ([self.movieOutput isRecording]) {
        [self.movieOutput stopRecording];
    } else {
        NSString *outputPath = [NSString stringWithFormat:@"%@/tmp/CaptureMoveiOutput.mov", NSHomeDirectory()];
        if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
            [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
        }
        NSURL *url = [NSURL fileURLWithPath:outputPath];
        NSLog(@"输出视频至: %@", url);
        [self.movieOutput startRecordingToOutputFileURL:url recordingDelegate:self];
    }
    
}

- (void)captureImage
{
    AVCaptureConnection *imageConnection = nil;
    for (AVCaptureConnection *connect in self.imageOutput.connections) {
        for (AVCaptureInputPort *port in connect.inputPorts) {
            if (port.mediaType == AVMediaTypeVideo) {
                imageConnection = connect;
                break;
            }
        }
        if (imageConnection != nil) {
            break;
        }
    }
    
    if (imageConnection != nil) {
        [self.imageOutput captureStillImageAsynchronouslyFromConnection:imageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
            //            UIImage *image = [[UIImage alloc] initWithData:[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer]];
            //            NSLog(@"get image success: %@", image);
            CVImageBufferRef imageRef = CMSampleBufferGetImageBuffer(imageDataSampleBuffer);
            
        }];
    }
}

- (IBAction)switchCamera:(UISwitch *)sender
{
    if (sender.isOn) {
        self.cameraType = CameraTypeBack;
    } else {
        self.cameraType = CameraTypeFront;
    }
}

- (void)test {
    
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    [session startRunning];
    
    [session beginConfiguration];
    [session commitConfiguration];
    //Monitoring Capture Session State
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(monitoringCaptureSessionState:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasConnected:) name:AVCaptureDeviceWasConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceWasDisconnected:) name:AVCaptureDeviceWasConnectedNotification object:nil];
    
    
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    NSMutableArray *torchDevices = [[NSMutableArray alloc] init];
    for (AVCaptureDevice *device in devices) {
    
        if (![device lockForConfiguration:nil]) {
            continue;
        }
        
        if ([device hasTorch] &&
            [device supportsAVCaptureSessionPreset:AVCaptureSessionPreset640x480]) {
            [torchDevices addObject:device];
        }
        //对焦模式
        if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
            
        }
        //特定点
        if ([device isFocusPointOfInterestSupported]) {
            CGPoint autofocusPoint = CGPointMake(0.5f, 0.5f);
            [device setFocusPointOfInterest:autofocusPoint];
        }
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
//        Exposure Modes
        if ([device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            CGPoint exposurePoint = CGPointMake(0.5f, 0.5f);
            [device setExposurePointOfInterest:exposurePoint];
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
//        Flash Modes
        if ([device hasFlash]) {
            if ([device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [device setFlashMode:AVCaptureFlashModeAuto];
            }
        }
//        Torch Mode
        if ([device hasTorch]) {
            if ([device isTorchModeSupported:AVCaptureTorchModeOn]) {
                [device setTorchMode:AVCaptureTorchModeOn];
            }
        }
//        Video Stabilization
//        AVCaptureConnection *connect = [[AVCaptureConnection alloc] init];
//        connect.videoStabilizationEnabled = YES;

//        While Balance
        if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
            device.whiteBalanceMode = AVCaptureWhiteBalanceModeLocked;
        }
        
//        Configuring a Device
        if ([device isFocusModeSupported:AVCaptureFocusModeLocked]) {
            NSError *error = nil;
            if ([device lockForConfiguration:&error]) {
                device.focusMode = AVCaptureFocusModeLocked;
                [device unlockForConfiguration];
            } else {
                
            }
        }
        
        [device unlockForConfiguration];
    }
    
//    Switching Between Devices
//    AVCaptureSession *session = <#A capture session#>;
//    [session beginConfiguration];
//    
//    [session removeInput:frontFacingCameraDeviceInput];
//    [session addInput:backFacingCameraDeviceInput];
//    
//    [session commitConfiguration];
    
    AVCaptureMovieFileOutput *aMoveiFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    NSArray *existingMetadataArray = aMoveiFileOutput.metadata;
    NSMutableArray *newMetadataArray = nil;
    if (existingMetadataArray) {
        newMetadataArray = [existingMetadataArray mutableCopy];
    } else {
        newMetadataArray = [[NSMutableArray alloc] init];
    }
    
    AVMutableMetadataItem *item = [[AVMutableMetadataItem alloc] init];
    item.keySpace = AVMetadataKeySpaceCommon;
    item.key = AVMetadataCommonKeyLocation;
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    item.value = [NSString stringWithFormat:@"%f, %f", location.coordinate.longitude, location.coordinate.latitude];
    [newMetadataArray addObject:item];
    aMoveiFileOutput.metadata = newMetadataArray;
    
    NSLog(@"%@", item.dataType);
    
    AVCaptureVideoDataOutput *dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [dataOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    dataOutput.videoSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    [dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    
    if ([session canAddOutput:dataOutput]) {
        [session addOutput:dataOutput];
    }
    
    
    AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{AVVideoCodecKey: AVVideoCodecJPEG};
    [stillImageOutput setOutputSettings:outputSettings];
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connect in stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connect inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connect;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
//        CFDictionaryRef exifAttachments =
//        CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
//        if (exifAttachments) {
//            // Do something with the attachments.
//        }
        // Continue as appropriate.
    }];
    
    AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    NSArray *connections = audioDataOutput.connections;
    if ([connections count] > 0) {
        AVCaptureConnection *connection = [connections objectAtIndex:0];
        NSArray *audioChannels = connection.audioChannels;
        for (AVCaptureAudioChannel *channel in audioChannels) {
            float avg = channel.averagePowerLevel;
            float peak = channel.peakHoldLevel;
            // Update the level meter user interface.
        }
    }
}

- (void)deviceWasDisconnected:(NSNotification *)noti
{
    NSLog(@"%s, noti: %@", __func__, noti);
}

- (void)deviceWasConnected:(NSNotification *)noti
{
    NSLog(@"%s, noti: %@", __func__, noti);
}

- (void)monitoringCaptureSessionState:(NSNotification *)noti
{
    NSLog(@"%s, noti: %@", __func__, noti);
}

#pragma mark =========AVCaptureVideoDataOutputSampleBufferDelegate=========
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%@", captureOutput);
    LOGFUNC;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"%@", captureOutput);
    LOGFUNC;
}

#pragma mark =========AVCaptureFileOutputRecordingDelegate=========
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    LOGFUNC;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    LOGFUNC;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    LOGFUNC;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    LOGFUNC;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    LOGFUNC;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
