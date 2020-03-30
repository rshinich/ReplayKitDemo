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

@interface ViewController ()<H264DecodeFrameCallbackDelegate,GCDAsyncSocketDelegate,LLBSDConnectionServerDelegate>

@property (nonatomic ,strong) UITextView                *logTextView;
@property (nonatomic ,strong) AAPLEAGLLayer             *playLayer;     //用于解码后播放

@property (nonatomic ,strong) H264DecodeTool            *h264Decoder;

@property (nonatomic ,strong) GCDAsyncSocket            *clientSocket;
@property (nonatomic ,strong) LLBSDConnectionServer     *llbsdServer;

@property(strong,nonatomic)NSMutableArray               *clientSocketArr;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupViews];
    [self initPlayLayer];
    [self configH264Decoder];
//    [self setupSocket];
    [self setupLLBSDMessageing];
}

#pragma Mark -

- (void)setupViews {

    self.view.backgroundColor = [UIColor whiteColor];

    self.logTextView = [[UITextView alloc] init];
    self.logTextView.frame = CGRectMake(600, 100, 300, 400);
    self.logTextView.editable = NO;
    [self.view addSubview:self.logTextView];

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
    [self.h264Decoder decodeNalu:(uint8_t *)[data bytes] size:(uint32_t)data.length];

    self.logTextView.text = [NSString stringWithFormat:@"%@\n%@",self.logTextView.text,data];

    // 读取到服务端数据值后,能再次读取
    [sock readDataWithTimeout:- 1 tag:tag];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
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
