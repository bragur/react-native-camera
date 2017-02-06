#import "RCTCameraManager.h"
#import "RCTCamera.h"
#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTUtils.h>
#import <React/RCTLog.h>
#import <React/UIView+React.h>
#import "NSMutableDictionary+ImageMetadata.m"
#import <AssetsLibrary/ALAssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <ImageIO/ImageIO.h>
#import "RCTSensorOrientationChecker.h"
#import <CoreImage/CoreImage.h>

@interface RCTCameraManager ()

@property (strong, nonatomic) RCTSensorOrientationChecker * sensorOrientationChecker;
@property (assign, nonatomic) NSInteger* flashMode;

@end

@implementation RCTCameraManager

RCT_EXPORT_MODULE();

- (UIView *)viewWithProps:(__unused NSDictionary *)props
{
    self.presetCamera = ((NSNumber *)props[@"type"]).integerValue;
    return [self view];
}

- (UIView *)view
{
  self.session = [AVCaptureSession new];
    
  self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
  self.previewLayer.needsDisplayOnBoundsChange = YES;

  if (!self.camera){
    self.camera = [[RCTCamera alloc] initWithManager:self bridge:self.bridge];
  }
  return self.camera;
}

- (NSDictionary *)constantsToExport
{
  return @{
           @"Aspect": @{
               @"stretch": @(RCTCameraAspectStretch),
               @"fit": @(RCTCameraAspectFit),
               @"fill": @(RCTCameraAspectFill)
               },
           @"BarCodeType": @{
               @"upce": AVMetadataObjectTypeUPCECode,
               @"code39": AVMetadataObjectTypeCode39Code,
               @"code39mod43": AVMetadataObjectTypeCode39Mod43Code,
               @"ean13": AVMetadataObjectTypeEAN13Code,
               @"ean8":  AVMetadataObjectTypeEAN8Code,
               @"code93": AVMetadataObjectTypeCode93Code,
               @"code128": AVMetadataObjectTypeCode128Code,
               @"pdf417": AVMetadataObjectTypePDF417Code,
               @"qr": AVMetadataObjectTypeQRCode,
               @"aztec": AVMetadataObjectTypeAztecCode
               #ifdef AVMetadataObjectTypeInterleaved2of5Code
               ,@"interleaved2of5": AVMetadataObjectTypeInterleaved2of5Code
               # endif
               #ifdef AVMetadataObjectTypeITF14Code
               ,@"itf14": AVMetadataObjectTypeITF14Code
               # endif
               #ifdef AVMetadataObjectTypeDataMatrixCode
               ,@"datamatrix": AVMetadataObjectTypeDataMatrixCode
               # endif
               },
           @"Type": @{
               @"front": @(RCTCameraTypeFront),
               @"back": @(RCTCameraTypeBack)
               },
           @"CaptureMode": @{
               @"still": @(RCTCameraCaptureModeStill),
               @"video": @(RCTCameraCaptureModeVideo)
               },
           @"CaptureQuality": @{
               @"low": @(RCTCameraCaptureSessionPresetLow),
               @"AVCaptureSessionPresetLow": @(RCTCameraCaptureSessionPresetLow),
               @"medium": @(RCTCameraCaptureSessionPresetMedium),
               @"AVCaptureSessionPresetMedium": @(RCTCameraCaptureSessionPresetMedium),
               @"high": @(RCTCameraCaptureSessionPresetHigh),
               @"AVCaptureSessionPresetHigh": @(RCTCameraCaptureSessionPresetHigh),
               @"photo": @(RCTCameraCaptureSessionPresetPhoto),
               @"AVCaptureSessionPresetPhoto": @(RCTCameraCaptureSessionPresetPhoto),
               @"480p": @(RCTCameraCaptureSessionPreset480p),
               @"AVCaptureSessionPreset640x480": @(RCTCameraCaptureSessionPreset480p),
               @"720p": @(RCTCameraCaptureSessionPreset720p),
               @"AVCaptureSessionPreset1280x720": @(RCTCameraCaptureSessionPreset720p),
               @"1080p": @(RCTCameraCaptureSessionPreset1080p),
               @"AVCaptureSessionPreset1920x1080": @(RCTCameraCaptureSessionPreset1080p)
               },
           @"CaptureTarget": @{
               @"memory": @(RCTCameraCaptureTargetMemory),
               @"disk": @(RCTCameraCaptureTargetDisk),
               @"temp": @(RCTCameraCaptureTargetTemp),
               @"cameraRoll": @(RCTCameraCaptureTargetCameraRoll)
               },
           @"Orientation": @{
               @"auto": @(RCTCameraOrientationAuto),
               @"landscapeLeft": @(RCTCameraOrientationLandscapeLeft),
               @"landscapeRight": @(RCTCameraOrientationLandscapeRight),
               @"portrait": @(RCTCameraOrientationPortrait),
               @"portraitUpsideDown": @(RCTCameraOrientationPortraitUpsideDown)
               },
           @"FlashMode": @{
               @"off": @(RCTCameraFlashModeOff),
               @"on": @(RCTCameraFlashModeOn),
               @"auto": @(RCTCameraFlashModeAuto)
               },
           @"TorchMode": @{
               @"off": @(RCTCameraTorchModeOff),
               @"on": @(RCTCameraTorchModeOn),
               @"auto": @(RCTCameraTorchModeAuto)
               }
           };
}

RCT_EXPORT_VIEW_PROPERTY(orientation, NSInteger);
RCT_EXPORT_VIEW_PROPERTY(defaultOnFocusComponent, BOOL);
RCT_EXPORT_VIEW_PROPERTY(onFocusChanged, BOOL);
RCT_EXPORT_VIEW_PROPERTY(onZoomChanged, BOOL);

RCT_CUSTOM_VIEW_PROPERTY(captureQuality, NSInteger, RCTCamera) {
  [self setCaptureQuality:AVCaptureSessionPresetPhoto];
}

RCT_CUSTOM_VIEW_PROPERTY(aspect, NSInteger, RCTCamera) {
  NSInteger aspect = [RCTConvert NSInteger:json];
  NSString *aspectString;
  switch (aspect) {
    default:
    case RCTCameraAspectFill:
      aspectString = AVLayerVideoGravityResizeAspectFill;
      break;
    case RCTCameraAspectFit:
      aspectString = AVLayerVideoGravityResizeAspect;
      break;
    case RCTCameraAspectStretch:
      aspectString = AVLayerVideoGravityResize;
      break;
  }

  self.previewLayer.videoGravity = aspectString;
}

RCT_CUSTOM_VIEW_PROPERTY(type, NSInteger, RCTCamera) {
  NSInteger type = [RCTConvert NSInteger:json];

  self.presetCamera = type;
  if (self.session.isRunning) {
    dispatch_async(self.sessionQueue, ^{
      AVCaptureDevice *currentCaptureDevice = [self.videoCaptureDeviceInput device];
      AVCaptureDevicePosition position = (AVCaptureDevicePosition)type;
      AVCaptureDevice *captureDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:(AVCaptureDevicePosition)position];

      if (captureDevice == nil) {
        return;
      }
        
      self.session.sessionPreset = AVCaptureSessionPresetPhoto;

      self.presetCamera = type;

      NSError *error = nil;
      AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];

      if (error || captureDeviceInput == nil)
      {
        NSLog(@"%@", error);
        return;
      }

      [self.session beginConfiguration];

      [self.session removeInput:self.videoCaptureDeviceInput];

      if ([self.session canAddInput:captureDeviceInput])
      {
        [self.session addInput:captureDeviceInput];

        [NSNotificationCenter.defaultCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:currentCaptureDevice];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
        self.videoCaptureDeviceInput = captureDeviceInput;
        [self setFlashMode];
      }
      else
      {
        [self.session addInput:self.videoCaptureDeviceInput];
      }

      [self.session commitConfiguration];
    });
  }
  [self initializeCaptureSessionInput:AVMediaTypeVideo];
}

- (void)setFlashMode {
    // Flash always off
    AVCaptureDevice *device = [self.videoCaptureDeviceInput device];
    NSError *error = nil;
    
    if (![device hasFlash]) return;
    if (![device lockForConfiguration:&error]) {
        NSLog(@"%@", error);
        return;
    }
    if (device.hasFlash && [device isFlashModeSupported:self.flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:AVCaptureFlashModeOff];
            [device unlockForConfiguration];
        }
        else
        {
            NSLog(@"%@", error);
        }
    }
    [device unlockForConfiguration];
}

RCT_CUSTOM_VIEW_PROPERTY(keepAwake, BOOL, RCTCamera) {
  BOOL enabled = [RCTConvert BOOL:json];
  [UIApplication sharedApplication].idleTimerDisabled = enabled;
}

RCT_CUSTOM_VIEW_PROPERTY(mirrorImage, BOOL, RCTCamera) {
  self.mirrorImage = [RCTConvert BOOL:json];
}

RCT_CUSTOM_VIEW_PROPERTY(barCodeTypes, NSArray, RCTCamera) {
  self.barCodeTypes = [RCTConvert NSArray:json];
}

RCT_CUSTOM_VIEW_PROPERTY(captureAudio, BOOL, RCTCamera) {
  BOOL captureAudio = [RCTConvert BOOL:json];
  if (captureAudio) {
    RCTLog(@"capturing audio");
    [self initializeCaptureSessionInput:AVMediaTypeAudio];
  }
}

- (NSArray *)customDirectEventTypes
{
    return @[
      @"focusChanged",
      @"zoomChanged",
    ];
}

- (id)init {
  if ((self = [super init])) {
    self.mirrorImage = false;

    self.sessionQueue = dispatch_queue_create("cameraManagerQueue", DISPATCH_QUEUE_SERIAL);

    self.sensorOrientationChecker = [RCTSensorOrientationChecker new];
  }
  return self;
}

RCT_EXPORT_METHOD(checkDeviceAuthorizationStatus:(RCTPromiseResolveBlock)resolve
                  reject:(__unused RCTPromiseRejectBlock)reject) {
  __block NSString *mediaType = AVMediaTypeVideo;

  [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
    if (!granted) {
      resolve(@(granted));
    }
    else {
      mediaType = AVMediaTypeAudio;
      [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        resolve(@(granted));
      }];
    }
  }];
}

RCT_EXPORT_METHOD(changeOrientation:(NSInteger)orientation) {
  [self setOrientation:orientation];
}

RCT_EXPORT_METHOD(capture:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
  NSInteger captureMode = [[options valueForKey:@"mode"] intValue];
  NSInteger captureTarget = [[options valueForKey:@"target"] intValue];

  [self captureStill:captureTarget options:options resolve:resolve reject:reject];
}

RCT_EXPORT_METHOD(hasFlash:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject) {
    AVCaptureDevice *device = [self.videoCaptureDeviceInput device];
    resolve(@(device.hasFlash));
}

- (void)startSession {
  dispatch_async(self.sessionQueue, ^{

    self.presetCamera = AVCaptureDevicePositionBack;

    AVCapturePhotoOutput *photoOutput = [[AVCapturePhotoOutput alloc] init];
    if ([self.session canAddOutput:photoOutput])
    {
      [self.session addOutput:photoOutput];
      self.photoOutput = photoOutput;
        
      self.photoOutput.highResolutionCaptureEnabled = YES;
      self.photoOutput.livePhotoCaptureEnabled = NO;
    }
    else {
        NSLog( @"Could not add photo output to the session" );
        [self.session commitConfiguration];
        return;
    }


    AVCaptureMetadataOutput *metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    if ([self.session canAddOutput:metadataOutput]) {
      [metadataOutput setMetadataObjectsDelegate:self queue:self.sessionQueue];
      [self.session addOutput:metadataOutput];
      [metadataOutput setMetadataObjectTypes:self.barCodeTypes];
      self.metadataOutput = metadataOutput;
    }
      
    [self.session commitConfiguration];

    __weak RCTCameraManager *weakSelf = self;
    [self setRuntimeErrorHandlingObserver:[NSNotificationCenter.defaultCenter addObserverForName:AVCaptureSessionRuntimeErrorNotification object:self.session queue:nil usingBlock:^(NSNotification *note) {
      RCTCameraManager *strongSelf = weakSelf;
      dispatch_async(strongSelf.sessionQueue, ^{
        // Manually restarting the session since it must have been stopped due to an error.
        [strongSelf.session startRunning];
      });
    }]];

    [self.session startRunning];
  });
}

- (void)stopSession {
  dispatch_async(self.sessionQueue, ^{
    self.camera = nil;
    [self.previewLayer removeFromSuperlayer];
    [self.session commitConfiguration];
    [self.session stopRunning];
    for(AVCaptureInput *input in self.session.inputs) {
      [self.session removeInput:input];
    }

    for(AVCaptureOutput *output in self.session.outputs) {
      [self.session removeOutput:output];
    }
  });
}

- (void)initializeCaptureSessionInput:(NSString *)type {
  dispatch_async(self.sessionQueue, ^{

    [self.session beginConfiguration];

    NSError *error = nil;
    AVCaptureDevice *captureDevice;

    if (type == AVMediaTypeVideo) {
      captureDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:self.presetCamera];
    }

    if (captureDevice == nil) {
      return;
    }

    AVCaptureDeviceInput *captureDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];

    if (error || captureDeviceInput == nil) {
      NSLog(@"%@", error);
      return;
    }

    if (type == AVMediaTypeVideo) {
      [self.session removeInput:self.videoCaptureDeviceInput];
    }

    if ([self.session canAddInput:captureDeviceInput]) {
      [self.session addInput:captureDeviceInput];

      if (type == AVMediaTypeVideo) {
        self.videoCaptureDeviceInput = captureDeviceInput;
        [self setFlashMode];
      }
      [self.metadataOutput setMetadataObjectTypes:self.metadataOutput.availableMetadataObjectTypes];
    }

    [self.session commitConfiguration];
  });
}

- (void)captureStill:(NSInteger)target options:(NSDictionary *)options resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{
    AVCaptureVideoOrientation orientation = options[@"orientation"] != nil ? [options[@"orientation"] integerValue] : self.orientation;
    if (orientation == RCTCameraOrientationAuto) {
            [self.sensorOrientationChecker getDeviceOrientationWithBlock:^(UIInterfaceOrientation orientation) {
                [self captureStill:target options:options orientation:[self.sensorOrientationChecker convertToAVCaptureVideoOrientation: orientation] resolve:resolve reject:reject];
            }];
    } else {
        [self captureStill:target options:options orientation:orientation resolve:resolve reject:reject];
    }
}

- (void)captureStill:(NSInteger)target options:(NSDictionary *)options orientation:(AVCaptureVideoOrientation)orientation resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject
{

  dispatch_async(self.sessionQueue, ^{
      AVCaptureConnection *photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
      if (self.photoOutput.availableRawPhotoPixelFormatTypes.count) {
          AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettingsWithRawPixelFormatType:(self.photoOutput.availableRawPhotoPixelFormatTypes[0]).unsignedLongValue];
          photoSettings.flashMode = AVCaptureFlashModeOff;
          photoSettings.highResolutionPhotoEnabled = YES;
          if ( photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0 ) {
              photoSettings.previewPhotoFormat = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject };
          }
          
          [self.photoOutput capturePhotoWithSettings:photoSettings delegate:self];

      }
  });
}

- (void) captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingRawPhotoSampleBuffer:(CMSampleBufferRef)rawSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
    if (error != nil) {
        NSLog( @"Error capturing photo: %@", error );
        return;
    }
    
    NSData *photoData = [AVCapturePhotoOutput DNGPhotoDataRepresentationForRawSampleBuffer:rawSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    
    CIFilter *rawFilter = [CIFilter filterWithImageData:photoData options:nil];
   // [rawFilter setValue:@10 forKey:kCIInputNeutralTemperatureKey];
    CIImage *ciImage = [rawFilter outputImage];
    
    EAGLContext *eContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    CIContext *ciContext = [CIContext contextWithEAGLContext:eContext options:nil];
    
    UIImage *uiImage = [UIImage imageWithCGImage:[ciContext createCGImage:ciImage fromRect:ciImage.extent] scale:1.0 orientation:UIImageOrientationUp];
    
    [self saveImage:UIImageJPEGRepresentation(uiImage, 1.0) target:nil metadata:nil resolve:nil reject:nil];
}




- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
    if (error != nil) {
        NSLog( @"Error capturing photo: %@", error );
        return;
    }    
}


- (void)saveImage:(NSData*)imageData target:(NSInteger)target metadata:(NSDictionary *)metadata resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
  NSString *responseString;

  //if (target == RCTCameraCaptureTargetMemory) {
    //resolve(@{@"data":[imageData base64EncodedStringWithOptions:0]});
    //return;
//  }


    [[[ALAssetsLibrary alloc] init] writeImageDataToSavedPhotosAlbum:imageData metadata:metadata completionBlock:^(NSURL* url, NSError* error) {
      if (error == nil) {
          NSLog(@"oh yes");
  //        resolve(@{@"path":[url absoluteString]});
      }
      else {
          NSLog(@"oh no");
      //  reject(RCTErrorUnspecified, nil, RCTErrorWithMessage(error.description));
      }
    }];
    return;
//  }
//  resolve(@{@"path":responseString});
}

- (CGImageRef)newCGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle
{
  CGFloat angleInRadians = angle * (M_PI / 180);
  CGFloat width = CGImageGetWidth(imgRef);
  CGFloat height = CGImageGetHeight(imgRef);

  CGRect imgRect = CGRectMake(0, 0, width, height);
  CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
  CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);

  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef bmContext = CGBitmapContextCreate(NULL, rotatedRect.size.width, rotatedRect.size.height, 8, 0, colorSpace, (CGBitmapInfo) kCGImageAlphaPremultipliedFirst);

  if (self.mirrorImage) {
    CGAffineTransform transform = CGAffineTransformMakeTranslation(rotatedRect.size.width, 0.0);
    transform = CGAffineTransformScale(transform, -1.0, 1.0);
    CGContextConcatCTM(bmContext, transform);
  }

  CGContextSetAllowsAntialiasing(bmContext, TRUE);
  CGContextSetInterpolationQuality(bmContext, kCGInterpolationNone);

  CGColorSpaceRelease(colorSpace);

  CGContextTranslateCTM(bmContext, +(rotatedRect.size.width/2), +(rotatedRect.size.height/2));
  CGContextRotateCTM(bmContext, angleInRadians);
  CGContextTranslateCTM(bmContext, -(rotatedRect.size.width/2), -(rotatedRect.size.height/2));

  CGContextDrawImage(bmContext, CGRectMake((rotatedRect.size.width-width)/2.0f, (rotatedRect.size.height-height)/2.0f, width, height), imgRef);

  CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
  CFRelease(bmContext);
  return rotatedImage;
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {

  for (AVMetadataMachineReadableCodeObject *metadata in metadataObjects) {
    for (id barcodeType in self.barCodeTypes) {
      if ([metadata.type isEqualToString:barcodeType]) {
        // Transform the meta-data coordinates to screen coords
        AVMetadataMachineReadableCodeObject *transformed = (AVMetadataMachineReadableCodeObject *)[_previewLayer transformedMetadataObjectForMetadataObject:metadata];

        NSDictionary *event = @{
          @"type": metadata.type,
          @"data": metadata.stringValue,
          @"bounds": @{
            @"origin": @{
              @"x": [NSString stringWithFormat:@"%f", transformed.bounds.origin.x],
              @"y": [NSString stringWithFormat:@"%f", transformed.bounds.origin.y]
            },
            @"size": @{
              @"height": [NSString stringWithFormat:@"%f", transformed.bounds.size.height],
              @"width": [NSString stringWithFormat:@"%f", transformed.bounds.size.width],
            }
          }
        };

        [self.bridge.eventDispatcher sendAppEventWithName:@"CameraBarCodeRead" body:event];
      }
    }
  }
}


- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
  NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
  AVCaptureDevice *captureDevice = [devices firstObject];

  for (AVCaptureDevice *device in devices)
  {
    if ([device position] == position)
    {
      captureDevice = device;
      break;
    }
  }

  return captureDevice;
}

- (void)subjectAreaDidChange:(NSNotification *)notification
{
  CGPoint devicePoint = CGPointMake(.5, .5);
  [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
  dispatch_async([self sessionQueue], ^{
    AVCaptureDevice *device = [[self videoCaptureDeviceInput] device];
    NSError *error = nil;
    if ([device lockForConfiguration:&error])
    {
      if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:focusMode])
      {
        [device setFocusMode:focusMode];
        [device setFocusPointOfInterest:point];
      }
      if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:exposureMode])
      {
        [device setExposureMode:exposureMode];
        [device setExposurePointOfInterest:point];
      }
      [device setSubjectAreaChangeMonitoringEnabled:monitorSubjectAreaChange];
      [device unlockForConfiguration];
    }
    else
    {
      NSLog(@"%@", error);
    }
  });
}

- (void)focusAtThePoint:(CGPoint) atPoint;
{
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        dispatch_async([self sessionQueue], ^{
            AVCaptureDevice *device = [[self videoCaptureDeviceInput] device];
            if([device isFocusPointOfInterestSupported] &&
               [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
                CGRect screenRect = [[UIScreen mainScreen] bounds];
                double screenWidth = screenRect.size.width;
                double screenHeight = screenRect.size.height;
                double focus_x = atPoint.x/screenWidth;
                double focus_y = atPoint.y/screenHeight;
                if([device lockForConfiguration:nil]) {
                    [device setFocusPointOfInterest:CGPointMake(focus_x,focus_y)];
                    [device setFocusMode:AVCaptureFocusModeAutoFocus];
                    if ([device isExposureModeSupported:AVCaptureExposureModeAutoExpose]){
                        [device setExposureMode:AVCaptureExposureModeAutoExpose];
                    }
                    [device unlockForConfiguration];
                }
            }
        });
    }
}

- (void)zoom:(CGFloat)velocity reactTag:(NSNumber *)reactTag{
    if (isnan(velocity)) {
        return;
    }
    const CGFloat pinchVelocityDividerFactor = 20.0f; // TODO: calibrate or make this component's property
    NSError *error = nil;
    AVCaptureDevice *device = [[self videoCaptureDeviceInput] device];
    if ([device lockForConfiguration:&error]) {
        CGFloat zoomFactor = device.videoZoomFactor + atan(velocity / pinchVelocityDividerFactor);
        if (zoomFactor > device.activeFormat.videoMaxZoomFactor) {
            zoomFactor = device.activeFormat.videoMaxZoomFactor;
        } else if (zoomFactor < 1) {
            zoomFactor = 1.0f;
        }

        NSDictionary *event = @{
          @"target": reactTag,
          @"zoomFactor": [NSNumber numberWithDouble:zoomFactor],
          @"velocity": [NSNumber numberWithDouble:velocity]
        };

        [self.bridge.eventDispatcher sendInputEventWithName:@"zoomChanged" body:event];

        device.videoZoomFactor = zoomFactor;
        [device unlockForConfiguration];
    } else {
        NSLog(@"error: %@", error);
    }
}

- (void)setCaptureQuality:(NSString *)quality
{
        if (quality) {
            [self.session beginConfiguration];
            if ([self.session canSetSessionPreset:quality]) {
                self.session.sessionPreset = quality;
            }
            [self.session commitConfiguration];
        }
}

@end
