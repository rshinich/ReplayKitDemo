//
//  ZZRI420Frame.m
//  BroadcastTarget
//
//  Created by 张忠瑞 on 2020/3/31.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

#import "ZZRI420Frame.h"
#import "ZZRYUVConverter.h"

@interface ZZRI420Frame() {

    CFMutableDataRef _cfData;
    UInt8 *_planeData[3];
    NSUInteger _stride[3];
}

@end

@implementation ZZRI420Frame

+ (instancetype)initWithData:(NSData *)data {

    int width = 0;
    int height = 0;
    int i420DataLength = 0;
    UInt64 timetag = 0;

    int structSize = sizeof(width) + sizeof(height) + sizeof(i420DataLength) + sizeof(timetag);
    if (structSize > data.length) {
        return nil;
    }

    const void *buffer = [data bytes];
    int offset = 0;

    memcpy(&width, buffer + offset, sizeof(width));
    offset += sizeof(width);

    memcpy(&height, buffer + offset, sizeof(height));
    offset += sizeof(height);

    memcpy(&i420DataLength, buffer + offset, sizeof(i420DataLength));
    offset += sizeof(i420DataLength);

    memcpy(&timetag, buffer + offset, sizeof(timetag));
    offset += sizeof(timetag);

    if (i420DataLength > data.length - structSize) {
        return nil;
    }

    ZZRI420Frame *frame = [[[self class] alloc] initWithWidth:width height:height];

    //YUV 4:2:2采样
    memcpy([frame dataOfPlane:ZZRI420FramePlaneY],  buffer + offset, [frame strideOfPlane:ZZRI420FramePlaneY] * height);
    offset += [frame strideOfPlane:ZZRI420FramePlaneY] * height;

    memcpy([frame dataOfPlane:ZZRI420FramePlaneU], buffer + offset, [frame strideOfPlane:ZZRI420FramePlaneU] * height / 2);
    offset += [frame strideOfPlane:ZZRI420FramePlaneU] * height / 2;

    memcpy([frame dataOfPlane:ZZRI420FramePlaneV], buffer + offset, [frame strideOfPlane:ZZRI420FramePlaneV] * height / 2);
    offset += [frame strideOfPlane:ZZRI420FramePlaneV] * height / 2;

    return frame;
}

- (NSData *)bytes {
    int structSize = sizeof(self.width) + sizeof(self.height) + sizeof(self.i420DataLength) + sizeof(self.timetag);

    void *buffer = malloc(structSize + self.i420DataLength);

    memset(buffer, 0, structSize + self.i420DataLength);
    int offset = 0;

    memcpy(buffer + offset, &_width, sizeof(_width));
    offset += sizeof(_width);

    memcpy(buffer + offset, &_height, sizeof(_height));
    offset += sizeof(_height);

    memcpy(buffer + offset, &_i420DataLength, sizeof(_i420DataLength));
    offset += sizeof(_i420DataLength);

    memcpy(buffer + offset, &_timetag, sizeof(_timetag));
    offset += sizeof(_timetag);

    memcpy(buffer + offset, [self dataOfPlane:ZZRI420FramePlaneY], [self strideOfPlane:ZZRI420FramePlaneY] * self.height);
    offset += [self strideOfPlane:ZZRI420FramePlaneY] * self.height;

    memcpy(buffer + offset, [self dataOfPlane:ZZRI420FramePlaneU], [self strideOfPlane:ZZRI420FramePlaneU] * self.height / 2);
    offset += [self strideOfPlane:ZZRI420FramePlaneU] * self.height / 2;

    memcpy(buffer + offset, [self dataOfPlane:ZZRI420FramePlaneV], [self strideOfPlane:ZZRI420FramePlaneV] * self.height / 2);
    offset += [self strideOfPlane:ZZRI420FramePlaneV] * self.height / 2;

    NSData *data = [NSData dataWithBytes:buffer length:offset];
    free(buffer);
    return data;
}

- (id)initWithWidth:(int)width height:(int)height {

    if (self = [super init]) {

        _width = width;
        _height = height;
        _i420DataLength = _width * _height * 3 >> 1;
        _cfData = CFDataCreateMutable(kCFAllocatorDefault, _i420DataLength);
        _data = CFDataGetMutableBytePtr(_cfData);
        _planeData[ZZRI420FramePlaneY] = _data;
        _planeData[ZZRI420FramePlaneU] = _planeData[ZZRI420FramePlaneY] + _width * _height;
        _planeData[ZZRI420FramePlaneV] = _planeData[ZZRI420FramePlaneU] + _width * _height / 4;
        _stride[ZZRI420FramePlaneY] = _width;
        _stride[ZZRI420FramePlaneU] = _width >> 1;
        _stride[ZZRI420FramePlaneV] = _width >> 1;
    }

    return self;
}


- (CMSampleBufferRef)convertToSampleBuffer {

    CVPixelBufferRef pixelBuffer = [ZZRYUVConverter i420FrameToPixelBuffer:self];

    if (!pixelBuffer) {
        return  nil;
    }

    CMSampleBufferRef sampleBuffer = [ZZRYUVConverter pixelBufferToSampleBuffer:pixelBuffer];
    return sampleBuffer;
}

#pragma mark - getter

- (UInt8 *)dataOfPlane:(ZZRI420FramePlane)plane {

    return _planeData[plane];
}

- (NSUInteger)strideOfPlane:(ZZRI420FramePlane)plane {

    return _stride[plane];
}


#pragma mark - dealloc

- (void)dealloc {

    [self freeData];
}

- (void)freeData {

    CFRelease(_cfData);

    _data = NULL;
    _width = _height = _i420DataLength = 0;
}


@end

