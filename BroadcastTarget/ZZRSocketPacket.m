//
//  ZZRSocketPacket.m
//  BroadcastTarget
//
//  Created by 张忠瑞 on 2020/4/1.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

#import "ZZRSocketPacket.h"

@implementation ZZRSocketPacket

+ (NSData *)packetWithBuffer:(NSData *)rawData {

    NSMutableData *mutableData = [NSMutableData data];
    @autoreleasepool {
        if(rawData.length == 0) {
            return NULL;
        }

        static uint64_t serial_id = 0;
        size_t size = rawData.length;
        void *data = malloc(sizeof(ZZRSocketHead));
        ZZRSocketHead *head = (ZZRSocketHead *)malloc(sizeof(ZZRSocketHead));
        head->version = 1;
        head->command_id = 1;
        head->service_id = 1;
        head->serial_id = serial_id++;
        head->data_len = (uint32_t)size;

        size_t headSize = sizeof(ZZRSocketHead);
        memcpy(data, head, headSize);
        NSData *headData = [NSData dataWithBytes:data length:headSize];
        [mutableData appendData: headData];

        free(data);
        free(head);
    }

    return [mutableData copy];
}

+ (NSData *)oacketWithBuffer:(NSData *)rawData head:(ZZRSocketHead *)head {

    if(rawData) {
        head->data_len = rawData.length;
    }

    NSMutableData *mutableData = [NSMutableData data];
    NSData *headData = [NSData dataWithBytes:head length:sizeof(ZZRSocketHead)];
    [mutableData appendData:headData];

    if(rawData) {
        [mutableData appendData:rawData];
    }

    return mutableData.copy;
}

@end
