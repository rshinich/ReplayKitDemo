//
//  ZZRI420Frame.h
//  BroadcastTarget
//
//  Created by 张忠瑞 on 2020/3/31.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMSampleBuffer.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ZZRI420FramePlane) {
    ZZRI420FramePlaneY = 0,
    ZZRI420FramePlaneU = 1,
    ZZRI420FramePlaneV = 2,
};

@interface ZZRI420Frame : NSObject

@property (nonatomic ,readonly) int width;
@property (nonatomic ,readonly) int height;
@property (nonatomic ,readonly) int i420DataLength;
@property (nonatomic ,assign) UInt64 timetag;
@property (nonatomic ,readonly) UInt8 *data;

+ (instancetype)initWithData:(NSData *)data;

- (NSData *)bytes;

- (id)initWithWidth:(int)width height:(int)height;

- (UInt8 *)dataOfPlane:(ZZRI420FramePlane)plane;

- (NSUInteger)strideOfPlane:(ZZRI420FramePlane)plane;

- (CMSampleBufferRef)convertToSampleBuffer;

@end

NS_ASSUME_NONNULL_END
