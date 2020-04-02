//
//  ZZRSocketPacket.h
//  BroadcastTarget
//
//  Created by 张忠瑞 on 2020/4/1.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    uint8_t version;
    uint8_t service_id;
    uint8_t command_id;
    uint8_t serial_id;
    uint64_t data_len;
} ZZRSocketHead;

#define kRecvBufferMaxSize 1024*1024*15
#define kRecvBufferPerSize 1024

@interface ZZRSocketPacket : NSObject

+ (NSData *)packetWithBuffer:(NSData *)rawData;
+ (NSData *)oacketWithBuffer:(NSData *)rawData head:(ZZRSocketHead *)head;


@end

NS_ASSUME_NONNULL_END
