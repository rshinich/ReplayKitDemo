//
//  ZZRYUVConverter.h
//  BroadcastTarget
//
//  Created by 张忠瑞 on 2020/3/31.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMSampleBuffer.h>
#import "ZZRI420Frame.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(uint8_t, ZZRVideoPackOrientation) {
    ZZRVideoPackOrientationPortrait                  = 0,
    ZZRVideoPackOrientationLandscapeLeft             = 1,
    ZZRVideoPackOrientationPortraitUpsideDown        = 2,
    ZZRVideoPackOrientationLandscapeRight            = 3,
};

@interface ZZRYUVConverter : NSObject

+ (ZZRI420Frame *)pixelBufferToI420:(CVImageBufferRef)pixelBuffer
                           withCrop:(float)cropRatio
                         targetSize:(CGSize)size
                        orientation:(ZZRVideoPackOrientation)orientation;

+ (CVPixelBufferRef)i420FrameToPixelBuffer:(ZZRI420Frame *)i420Frame;

+ (CMSampleBufferRef)pixelBufferToSampleBuffer:(CVPixelBufferRef)pixelBuffer;

@end

NS_ASSUME_NONNULL_END
