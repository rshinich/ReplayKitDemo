//
//  SampleHandler.m
//  BroadcastTarget
//
//  Created by 张忠瑞 on 2020/3/25.
//  Copyright © 2020 张忠瑞. All rights reserved.
//


#import "SampleHandler.h"
#import <VideoToolbox/VideoToolbox.h>
#import <GCDAsyncSocket.h>
#import "LLBSDMessage.h"
#import "LLBSDConnection.h"
#import "H264EncodeTool.h"


@interface SampleHandler()<GCDAsyncSocketDelegate,H264EncodeCallBackDelegate,LLBSDConnectionDelegate>

@property (nonatomic ,strong) H264EncodeTool            *h264Encoder;
@property (nonatomic ,strong) GCDAsyncSocket            *extensionSocket;
@property (nonatomic ,strong) LLBSDConnectionClient     *llbsdClient;

@end

@implementation SampleHandler
{
    int frameID;
    VTCompressionSessionRef EncodingSession;
}


#pragma mark -

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    [self setupEncoder];
//    [self setupGCDAsyncSocket];
    [self setupLLBSDMessageing];
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    [self.h264Encoder stopEncode];
    self.h264Encoder = nil;

}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {

    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo: {

            [self.h264Encoder encode:sampleBuffer];
            break;
        }
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;

        default:
            break;
    }
}

#pragma mark - Private method

- (void)setupEncoder {
    if (!self.h264Encoder) {
        self.h264Encoder = [[H264EncodeTool alloc]init];
        //640 * 480
        [self.h264Encoder initEncode:640 height:480];
        self.h264Encoder.delegate = self;
    }
}

- (void)setupGCDAsyncSocket {

    self.extensionSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    NSError *error = nil;
    [self.extensionSocket connectToHost:@"127.0.0.1" onPort:12345 error:&error];
    if (error) {
        NSLog(@"error == %@",error);
    }
}

- (void)setupLLBSDMessageing {

    self.llbsdClient = [[LLBSDConnectionClient alloc] initWithApplicationGroupIdentifier:@"group.com.zzr.ReplayKitDemo" connectionIdentifier:1];
    self.llbsdClient.delegate = self;

    [self.llbsdClient start:^(NSError *error) {
        if(error) {
            NSLog(@"start error = %@",error);
        }
    }];
}


//编码sampleBuffer
- (void)encode:(CMSampleBufferRef )sampleBuffer {

    CVImageBufferRef imageBuffer = (CVImageBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    // 帧时间，如果不设置会导致时间轴过长。
    CMTime presentationTimeStamp = CMTimeMake(frameID++, 1000);
    VTEncodeInfoFlags flags;
    OSStatus statusCode = VTCompressionSessionEncodeFrame(EncodingSession,
                                                          imageBuffer,
                                                          presentationTimeStamp,
                                                          kCMTimeInvalid,
                                                          NULL, NULL, &flags);
    if (statusCode != noErr) {
        NSLog(@"H264: VTCompressionSessionEncodeFrame failed with %d", (int)statusCode);

        VTCompressionSessionInvalidate(self->EncodingSession);
        CFRelease(EncodingSession);
        EncodingSession = NULL;
        return;
    }
    NSLog(@"H264: VTCompressionSessionEncodeFrame Success");
}

- (void)sendData:(NSData *)data {

    //via GCDAsyncSocket
//    [self.extensionSocket writeData:data withTimeout:-1 tag:0];

    //via LLBSD
    NSDictionary *dataDic = @{@"data": data};
    LLBSDMessage *message = [LLBSDMessage messageWithName:@"message" userInfo:dataDic];
    [self.llbsdClient sendMessage:message completion:^(NSError *error) {
        if(error) {
            NSLog(@"sendMessageError = %@",error);
        }
    }];
}

#pragma mark - H264EncodeCallBackDelegate

- (void)gotSpsPps:(NSData *)sps pps:(NSData *)pps{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];

    NSMutableData *h264spsData = [[NSMutableData alloc] init];
    NSMutableData *h264ppsData = [[NSMutableData alloc] init];

    //sps
    [h264spsData appendData:ByteHeader];
    [h264spsData appendData:sps];
    NSLog(@"sps = %@",h264spsData);
    [self sendData:h264spsData];

    //pps
    [h264ppsData resetBytesInRange:NSMakeRange(0, [h264spsData length])];
    [h264ppsData setLength:0];
    [h264ppsData appendData:ByteHeader];
    [h264ppsData appendData:pps];
    NSLog(@"pps = %@",h264ppsData);

    [self sendData:h264ppsData];
}

- (void)gotEncodedData:(NSData *)data isKeyFrame:(BOOL)isKeyFrame{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    NSLog(@"data = %@",h264Data);

    [self sendData:h264Data];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"链接成功");
    NSLog(@"服务器IP: %@-------端口: %d",host,port);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"发送数据 tag = %zi",tag);
    [sock readDataWithTimeout:-1 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"读取数据 data = %@ tag = %zi",str,tag);
    // 读取到服务端数据值后,能再次读取
    [sock readDataWithTimeout:- 1 tag:tag];

}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"断开连接");
    self.extensionSocket.delegate = nil;
    self.extensionSocket = nil;
}

#pragma mark - LLBSDConnectionDelegate

- (void)connection:(LLBSDConnection *)connection didReceiveMessage:(LLBSDMessage *)message fromProcess:(LLBSDProcessInfo *)processInfo
{
    if (![message.name isEqualToString:@"message"]) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
    });
}

- (void)connection:(LLBSDConnection *)connection didFailToReceiveMessageWithError:(NSError *)error
{
    NSLog(@"didFailToReceiveMessageWithError = %@",error);
}




@end
