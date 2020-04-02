//
//  ZZRYUVConverter.m
//  BroadcastTarget
//
//  Created by 张忠瑞 on 2020/3/31.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

#import "ZZRYUVConverter.h"
#import "ZZRVideoUtils.h"
#import "libyuv.h"

@implementation ZZRYUVConverter

+ (ZZRI420Frame *)pixelBufferToI420:(CVImageBufferRef)pixelBuffer
                           withCrop:(float)cropRatio
                         targetSize:(CGSize)size
                        orientation:(ZZRVideoPackOrientation)orientation {

    if (pixelBuffer == NULL) {
        return  nil;
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    OSType sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);

    size_t bufferWidth = 0;
    size_t bufferHeight = 0;
    size_t rowSize = 0;
    uint8_t *pixel = NULL;

//    YUV格式有两大类：planar和packed。
//    对于planar的YUV格式，先连续存储所有像素点的Y，紧接着存储所有像素点的U，随后是所有像素点的V。
//    对于packed的YUV格式，每个像素点的Y,U,V是连续交*存储的。
    if (CVPixelBufferIsPlanar(pixelBuffer)) {
        int basePlane = 0;
        pixel = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, basePlane);
        bufferWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, basePlane);
        bufferHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, basePlane);
        rowSize = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, basePlane);

    } else {
        pixel = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
        bufferWidth = CVPixelBufferGetWidth(pixelBuffer);
        bufferHeight = CVPixelBufferGetHeight(pixelBuffer);
        rowSize = CVPixelBufferGetBytesPerRow(pixelBuffer);
    }

    ZZRI420Frame *convertedI420Frame = [[ZZRI420Frame alloc] initWithWidth:(int)bufferWidth height:(int)bufferHeight];

    int error = -1;

    if (sourcePixelFormat == kCVPixelFormatType_32BGRA) {

        error = libyuv::ARGBToI420(pixel,
                                   (int)rowSize,
                                   [convertedI420Frame dataOfPlane:ZZRI420FramePlaneY], (int)[convertedI420Frame strideOfPlane:ZZRI420FramePlaneY],
                                   [convertedI420Frame dataOfPlane:ZZRI420FramePlaneU], (int)[convertedI420Frame strideOfPlane:ZZRI420FramePlaneU],
                                   [convertedI420Frame dataOfPlane:ZZRI420FramePlaneV], (int)[convertedI420Frame strideOfPlane:ZZRI420FramePlaneV],
                                   (int)bufferWidth,
                                   (int)bufferHeight);

    } else if (sourcePixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange ||
               sourcePixelFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange) {

        error = libyuv::NV12ToI420(pixel,
                                   (int)rowSize,
                                   (const uint8 *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1),
                                   (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1),
                                   [convertedI420Frame dataOfPlane:ZZRI420FramePlaneY], (int)[convertedI420Frame strideOfPlane:ZZRI420FramePlaneY],
                                   [convertedI420Frame dataOfPlane:ZZRI420FramePlaneU], (int)[convertedI420Frame strideOfPlane:ZZRI420FramePlaneU],
                                   [convertedI420Frame dataOfPlane:ZZRI420FramePlaneV], (int)[convertedI420Frame strideOfPlane:ZZRI420FramePlaneV],
                                   (int)bufferWidth,
                                   (int)bufferHeight);
    } else {

    }

    if (error) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        NSLog(@"error convert pixel buffer to i420 with error %d", error);
        return nil;
    } else {
        rowSize = [convertedI420Frame strideOfPlane:ZZRI420FramePlaneY];
        pixel = convertedI420Frame.data;
    }

    CMVideoDimensions inputDimens = {(int32_t)bufferWidth, (int32_t)bufferHeight};
    CMVideoDimensions outputDimens = [ZZRVideoUtils outputVideoDimens:inputDimens crop:cropRatio];
    CMVideoDimensions sizeDimens = {(int32_t)size.width, (int32_t)size.height};
    CMVideoDimensions targetDimens = [ZZRVideoUtils outputVideoDimens:sizeDimens crop:cropRatio];

    int cropX = (inputDimens.width - outputDimens.width) / 2;
    int cropY = (inputDimens.height - outputDimens.height) / 2;

    if (cropX % 2) {
        cropX += 1;
    }

    if (cropY % 2) {
        cropY += 1;
    }

    float scale = targetDimens.width*1.0/outputDimens.width;

    ZZRI420Frame *croppedI420Frame = [[ZZRI420Frame alloc] initWithWidth:outputDimens.width height:outputDimens.height];

    error = libyuv::ConvertToI420(pixel,
                                  bufferHeight * rowSize * 1.5,
                                  [croppedI420Frame dataOfPlane:ZZRI420FramePlaneY], (int)[croppedI420Frame strideOfPlane:ZZRI420FramePlaneY],
                                  [croppedI420Frame dataOfPlane:ZZRI420FramePlaneU], (int)[croppedI420Frame strideOfPlane:ZZRI420FramePlaneU],
                                  [croppedI420Frame dataOfPlane:ZZRI420FramePlaneV], (int)[croppedI420Frame strideOfPlane:ZZRI420FramePlaneV],
                                  cropX,
                                  cropY,
                                  (int)bufferWidth,
                                  (int)bufferHeight,
                                  croppedI420Frame.width,
                                  croppedI420Frame.height,
                                  libyuv::kRotate0,
                                  libyuv::FOURCC_I420);

    if (error) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        NSLog(@"error convert pixel buffer to i420 with error %d", error);
        return nil;
    }

    ZZRI420Frame *i420Frame;

    if (scale == 1.0) {
        i420Frame = croppedI420Frame;
    } else {
        int width = outputDimens.width * scale;
        width &= 0xFFFFFFFE;

        int height = outputDimens.height * scale;
        height &= 0xFFFFFFFE;

        i420Frame = [[ZZRI420Frame alloc] initWithWidth:width height:height];

        libyuv::I420Scale([croppedI420Frame dataOfPlane:ZZRI420FramePlaneY], (int)[croppedI420Frame strideOfPlane:ZZRI420FramePlaneY],
                          [croppedI420Frame dataOfPlane:ZZRI420FramePlaneU], (int)[croppedI420Frame strideOfPlane:ZZRI420FramePlaneU],
                          [croppedI420Frame dataOfPlane:ZZRI420FramePlaneV], (int)[croppedI420Frame strideOfPlane:ZZRI420FramePlaneV],
                          croppedI420Frame.width,
                          croppedI420Frame.height,
                          [i420Frame dataOfPlane:ZZRI420FramePlaneY], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneY],
                          [i420Frame dataOfPlane:ZZRI420FramePlaneU], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneU],
                          [i420Frame dataOfPlane:ZZRI420FramePlaneV], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneV],
                          i420Frame.width,
                          i420Frame.height,
                          libyuv::kFilterBilinear);
    }

    int dstWidth, dstHeight;
    libyuv::RotationModeEnum rotateMode = [ZZRYUVConverter rotateMode:orientation];

    if (rotateMode != libyuv::kRotateNone) {
        if(rotateMode == libyuv::kRotate270 || rotateMode == libyuv:: kRotate90) {
            dstWidth = i420Frame.height;
            dstHeight = i420Frame.width;
        } else {
            dstWidth = i420Frame.width;
            dstHeight = i420Frame.height;
        }

        ZZRI420Frame *rotatedI420Frame = [[ZZRI420Frame alloc] initWithWidth:dstWidth height:dstHeight];

        libyuv::I420Rotate([i420Frame dataOfPlane:ZZRI420FramePlaneY], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneY],
                           [i420Frame dataOfPlane:ZZRI420FramePlaneU], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneU],
                           [i420Frame dataOfPlane:ZZRI420FramePlaneV], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneV],
                           [rotatedI420Frame dataOfPlane:ZZRI420FramePlaneY], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneY],
                           [rotatedI420Frame dataOfPlane:ZZRI420FramePlaneU], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneU],
                           [rotatedI420Frame dataOfPlane:ZZRI420FramePlaneV], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneV],
                           i420Frame.width,
                           i420Frame.height,
                           rotateMode);

        i420Frame = rotatedI420Frame;
    }

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return i420Frame;
}

+ (CVPixelBufferRef)i420FrameToPixelBuffer:(ZZRI420Frame *)i420Frame {

    if(i420Frame == nil) {
        return NULL;
    }

    CVPixelBufferRef pixelBuffer = NULL;

    NSDictionary *pixelBufferAttributes = @{(id)kCVPixelBufferIOSurfacePropertiesKey: [NSDictionary dictionary]};

    CVReturn result = CVPixelBufferCreate(kCFAllocatorDefault,
                                          i420Frame.width,
                                          i420Frame.height,
                                          kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                                          (__bridge CFDictionaryRef)pixelBufferAttributes,
                                          &pixelBuffer);

    if (result != kCVReturnSuccess) {
        return NULL;
    }

    result = CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    if (result != kCVReturnSuccess) {
        CFRelease(pixelBuffer);
        return NULL;
    }

    uint8 *dstY = (uint8 *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    int dstStrideY = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    uint8 *dstUV = (uint8 *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    int dstStrideUV = (int)CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);

    int ret = libyuv::I420ToNV12([i420Frame dataOfPlane:ZZRI420FramePlaneY], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneY],
                                 [i420Frame dataOfPlane:ZZRI420FramePlaneU], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneU],
                                 [i420Frame dataOfPlane:ZZRI420FramePlaneV], (int)[i420Frame strideOfPlane:ZZRI420FramePlaneV],
                                 dstY, dstStrideY,
                                 dstUV, dstStrideUV,
                                 i420Frame.width,
                                 i420Frame.height);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    if (ret) {

        CFRelease(pixelBuffer);
        return NULL;
    }

    return pixelBuffer;
}

+ (CMSampleBufferRef)pixelBufferToSampleBuffer:(CVPixelBufferRef)pixelBuffer {

    if (pixelBuffer == NULL) {
        return NULL;
    }

    CMSampleBufferRef sampleBuffer;
    CMTime frameTime = CMTimeMakeWithSeconds([[NSDate date] timeIntervalSince1970], 1000000000);
    CMSampleTimingInfo timing = {kCMTimeInvalid, frameTime, kCMTimeInvalid};
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);

    OSStatus status = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, true, NULL, NULL, videoInfo, &timing, &sampleBuffer);

    if (status != noErr) {
        NSLog(@"Failed to create sample buffer with error %d.", (int)status);
    }

    CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, true);
    CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
    CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);

    CVPixelBufferRelease(pixelBuffer);
    if(videoInfo) {
        CFRelease(videoInfo);
    }

    return sampleBuffer;
}

#pragma mark - Private

+ (libyuv::RotationModeEnum)rotateMode:(ZZRVideoPackOrientation)orientation {

    switch (orientation) {
        case ZZRVideoPackOrientationPortrait:
            return libyuv::kRotate0;
        case ZZRVideoPackOrientationPortraitUpsideDown:
            return libyuv::kRotate180;
        case ZZRVideoPackOrientationLandscapeLeft:
            return libyuv::kRotate90;
        case ZZRVideoPackOrientationLandscapeRight:
            return libyuv::kRotate270;
        default:
            return libyuv::kRotate0;
    }
}


@end
