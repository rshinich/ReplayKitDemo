//
//  ViewController.m
//  ReplayKitDemo
//
//  Created by 张忠瑞 on 2020/3/25.
//  Copyright © 2020 张忠瑞. All rights reserved.
//

#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>
#import <GCDAsyncSocket.h>
#import "LLBSDMessage.h"
#import "LLBSDConnection.h"
#import "AAPLEAGLLayer.h"
#import "H264DecodeTool.h"

#import <WebRTC/WebRTC.h>
#import "ZZRSocketPacket.h"
#import "ZZRTPCircularBuffer.h"
#import "ZZRI420Frame.h"

@interface ViewController ()<H264DecodeFrameCallbackDelegate,GCDAsyncSocketDelegate,LLBSDConnectionServerDelegate,AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic ,strong) UITextView                *logTextView;
@property (nonatomic ,strong) UIImageView               *showImageView;
@property (nonatomic ,strong) AAPLEAGLLayer             *playLayer;     //用于解码后播放

@property (nonatomic ,strong) H264DecodeTool            *h264Decoder;

@property (nonatomic ,strong) GCDAsyncSocket            *clientSocket;
@property (nonatomic ,strong) LLBSDConnectionServer     *llbsdServer;

@property (nonatomic ,strong) NSMutableArray               *clientSocketArr;

@property (nonatomic, assign) ZZRTPCircularBuffer        *recvBuffer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];
    [self initPlayLayer];
    [self configH264Decoder];
    [self setupSocket];
//    [self setupLLBSDMessageing];
}

#pragma Mark -

- (void)setupViews {

    self.view.backgroundColor = [UIColor whiteColor];

    self.logTextView = [[UITextView alloc] init];
    self.logTextView.frame = CGRectMake(600, 100, 300, 400);
    self.logTextView.editable = NO;
    [self.view addSubview:self.logTextView];

    self.showImageView = [[UIImageView alloc] init];
    self.showImageView.frame = CGRectMake(200, 800, 320, 640);
    [self.view addSubview:self.showImageView];

    RPSystemBroadcastPickerView *pickerView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(100, 100, 50, 50)];
    pickerView.preferredExtension = @"com.zzr.ReplayKitDemo.BroadcastTarget";
    [self.view addSubview:pickerView];
}

- (void)configH264Decoder {
    if (!self.h264Decoder) {
        self.h264Decoder = [[H264DecodeTool alloc] init];
        self.h264Decoder.delegate = self;
    }
}

- (void)initPlayLayer{
    self.playLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(200, 100,320,640)];
    self.playLayer.backgroundColor = [UIColor redColor].CGColor;
    [self.view.layer addSublayer:self.playLayer];
}

- (void)setupSocket {

    _recvBuffer = (ZZRTPCircularBuffer *)malloc(sizeof(ZZRTPCircularBuffer)); // 需要释放
    ZZRTPCircularBufferInit(_recvBuffer, kRecvBufferMaxSize);

    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];

    NSError *error = nil;
    [self.clientSocket acceptOnPort:12345 error:&error];
    if (error) {
        NSLog(@"error = %@",error);
    }
}

- (void)setupLLBSDMessageing {

    self.llbsdServer = [[LLBSDConnectionServer alloc] initWithApplicationGroupIdentifier:@"group.com.zzr.ReplayKitDemo" connectionIdentifier:1];
    self.llbsdServer.delegate = self;
//    server.allowedMessageClasses = [NSSet setWithObject:[]]

    [self.llbsdServer start:^(NSError *error) {
        if (error) {
            [self presentError:error];
        }
    }];
}

- (void)presentError:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:error.localizedDescription message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    });
}


#pragma mark - H264DecodeFrameCallbackDelegate

- (void)gotDecodedFrame:(CVImageBufferRef)imageBuffer{
    if(imageBuffer)
    {
        //解码回来的数据绘制播放
        self.playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {

    ZZRTPCircularBufferClear(self.recvBuffer);

    [self.clientSocketArr addObject:newSocket];
    [newSocket readDataWithTimeout:-1 tag:100];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"新的客户端接入" message:nil preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];

    [alertController addAction:cancelAction];

    [self presentViewController:alertController animated:YES completion:nil];

    NSLog(@"新的客户端接入");
//    NSLog(@"服务器IP: %@-------端口: %d",newSocket,port);
}


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
//    [self.h264Decoder decodeNalu:(uint8_t *)[data bytes] size:(uint32_t)data.length];
//
//    CMTime inTime = CMTimeMakeWithSeconds(5, 600);
//
//    CVPixelBufferRef piexlBuffer = [self yuvPixelBufferWithData:data presentationTime:inTime width:640 height:500];
//    UIImage *image = [self makeUIImageWithYUVPixelBuffer:piexlBuffer];
//    self.showImageView.image = image;

//    RTCCVPixelBuffer *rtcPiexlBuffer = [[RTCCVPixelBuffer alloc] initWithPixelBuffer:piexlBuffer];
//
//    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
//    NSTimeInterval time=[date timeIntervalSince1970]*1000;// *1000 是精确到毫秒，不乘就是精确到秒
//
//    RTCVideoFrame *videoFrame = [[RTCVideoFrame alloc] initWithBuffer:rtcPiexlBuffer rotation:RTCVideoRotation_0 timeStampNs:time];


    self.logTextView.text = [NSString stringWithFormat:@"%@\n%@",self.logTextView.text,data];

    static uint64_t currentDataSize = 0;
    static uint64_t targetDataSize = 0;

    BOOL isHead = NO;

    if(data.length == sizeof(ZZRSocketHead)) {
        ZZRSocketHead *head = (ZZRSocketHead *)data.bytes;
        if(head->version == 1 && head->command_id == 1 && head->service_id == 1) {
            isHead = YES;
            targetDataSize = head->data_len;
            currentDataSize = 0;
        }
    } else {
        currentDataSize += data.length;
    }

    if (isHead) {
        //接收到新的一帧，将原来的缓存清空

        [self handleRecvBuffer];

        ZZRTPCircularBufferProduceBytes(self.recvBuffer, data.bytes, (int32_t)data.length);

    } else if (currentDataSize >= targetDataSize && currentDataSize != -1) {
        //加上新的数据之后，已经满足一帧
        ZZRTPCircularBufferProduceBytes(self.recvBuffer, data.bytes, (int32_t)data.length);

        currentDataSize = -1;
        [self handleRecvBuffer];

    } else {

        //不够一帧，提那家不处理
        ZZRTPCircularBufferProduceBytes(self.recvBuffer, data.bytes, (int32_t)data.length);
    }

    // 读取到服务端数据值后,能再次读取
    [sock readDataWithTimeout:- 1 tag:tag];
}

- (void)handleRecvBuffer {

    int32_t availableBytes = 0;
    void * buffer = ZZRTPCircularBufferTail(self.recvBuffer, &availableBytes);
    int32_t headSize = sizeof(ZZRSocketHead);

    if(availableBytes <= headSize) {
        //        NSLog(@" > 不够文件头");
        ZZRTPCircularBufferClear(self.recvBuffer);
        return;
    }

    ZZRSocketHead head;
    memset(&head, 0, sizeof(head));
    memcpy(&head, buffer, headSize);
    uint64_t dataLen = head.data_len;

    if(dataLen > availableBytes - headSize && dataLen >0) {
        //        NSLog(@" > 不够数据体");
        ZZRTPCircularBufferClear(self.recvBuffer);
        return;
    }

    void *data = malloc(dataLen);
    memset(data, 0, dataLen);
    memcpy(data, buffer + headSize, dataLen);
    ZZRTPCircularBufferClear(self.recvBuffer); // 处理完一帧数据就清空缓存

//    if([self respondsToSelector:@selector(onRecvData:)]) {
//        @autoreleasepool {
//            [self onRecvData:[NSData dataWithBytes:data length:dataLen]];
//        };
//    }

    free(data);
}

- (void)onRecvData:(NSData *)data
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ZZRI420Frame *frame = [ZZRI420Frame initWithData:data];
        CMSampleBufferRef sampleBuffer = [frame convertToSampleBuffer];
        if (sampleBuffer == NULL) {
            return;
        }

        //推流到RN

        CFRelease(sampleBuffer);
    });

}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    ZZRTPCircularBufferClear(self.recvBuffer);

    NSLog(@"断开连接");
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
}

#pragma mark - LLBSDConnectionServerDelegate

- (BOOL)server:(LLBSDConnectionServer *)server shouldAcceptNewConnection:(LLBSDProcessInfo *)connectionInfo
{
    NSLog(@"shouldAcceptNewConnection");
    return YES;
}

- (void)connection:(LLBSDConnection *)connection didReceiveMessage:(LLBSDMessage *)message fromProcess:(LLBSDProcessInfo *)processInfo
{
    if (![message.name isEqualToString:@"message"]) {
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
//        NSString *text = self.logView.text;
//        text = [text stringByAppendingString:@"\n\n"];
//        text = [text stringByAppendingString:message.userInfo[@"text"]];
//        text = [text stringByAppendingString:@"\n"];
//        text = [text stringByAppendingString:[message.userInfo[@"special"] title]];
//        self.logView.text = text;
    });
}

- (void)connection:(LLBSDConnection *)connection didFailToReceiveMessageWithError:(NSError *)error
{
    [self presentError:error];
}


#pragma mark - getter

-(NSMutableArray *)clientSocketArr{
    if (_clientSocketArr == nil) {
        _clientSocketArr = [NSMutableArray array];
    }
    return _clientSocketArr;
}



@end
