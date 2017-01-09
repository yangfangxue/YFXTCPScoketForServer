//
//  ViewController.m
//  YFX_ScoketForServerDemo
//
//  Created by fangxue on 2017/1/9.
//  Copyright © 2017年 fangxue. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GCDAsyncSocket.h"
@interface ViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,GCDAsyncSocketDelegate>
{
    UIImageView *imgView;
}

@property (nonatomic, strong) GCDAsyncSocket *serverSocket;

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        
    }
    return self;
}

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    /*
     1.手机开热点(谁当服务端 host就写谁的ip地址)
     
     2.开热点的手机称为服务端  连接此热点的其他手机称为客户端
     
     3.GCDAsyncSocket这个类采用的是TCP连接 由于要经历3次握手 耗时一点 故实效性不高
     有时间我会继续学习一下GCDAsyncUdpSocket这个类 采用的是UDP 实效性好一点
     
     4.scoket还是很强大的 从它的代理方法中 就可以知道服务端和客户端是可以进行交互的
     
     */
    
    /*
     PS:iPhone手机
     
     本Demo为服务端Demo 目的是为了把实时拍摄的视频数据通过scoket传输到另一台手机上
     
     配合学习请看客户端Demo
     */
    //1.创建服务器socket
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    //2.开始监听（开放哪一个端口）
    NSError *error = nil;
    
    BOOL result = [self.serverSocket acceptOnPort:[@"8000" integerValue] error:&error];
    if (result) {
        //开放成功
        NSLog(@"开放成功");
    }else{
        //开放失败
        NSLog(@"开放失败");
    }
    
    imgView = [[UIImageView alloc]initWithFrame:self.view.frame];
    
    imgView.contentMode = 3;
    
    [self.view addSubview:imgView];
    
    [self setupCaptureSession];
}

-(void) setupCaptureSession
{
    NSError *error = nil;
    
    AVCaptureSession *session = [[AVCaptureSession alloc]init];
    
    session.sessionPreset = AVCaptureSessionPreset640x480;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (!input) {
        NSLog(@"%@",error);
    }
    [session addInput:input];
    
    
    AVCaptureVideoDataOutput *outPut = [[AVCaptureVideoDataOutput alloc]init];
    [session addOutput:outPut];
    
    outPut.alwaysDiscardsLateVideoFrames = YES;
    
    dispatch_queue_t queue = dispatch_queue_create("myQueue",NULL);
    
    [outPut setSampleBufferDelegate:self queue:queue];
    
    outPut.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA],kCVPixelBufferPixelFormatTypeKey,nil];
    
    [session startRunning];
    
    AVCaptureVideoPreviewLayer *preLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    
    preLayer.frame = self.view.frame;
    
    preLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.view.layer addSublayer:preLayer];
}
#pragma mark - delegate
//使用这个委托方法获取帧
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
    
    NSData *data = UIImageJPEGRepresentation(image,0.5);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        imgView.image = image;
        
        //发送信息
        if (data!=nil) {
            
            [self.clientSocket writeData:data withTimeout:-1 tag:0];
        }
    });
}
#pragma mark  socketdelegate
//监听到客户端socket链接
//当客户端链接成功后，生成一个新的客户端socket
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket{
    
    NSLog(@"连接成功");
    //connectedHost:地址IP
    //connectedPort:端口
    NSLog(@"%@",[NSString stringWithFormat:@"链接地址:%@",newSocket.connectedHost]);
    //保存客户端socket
    self.clientSocket = newSocket;
    
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}
//成功读取客户端发过来的消息
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"成功读取客户端发过来的消息 = %@",message);
    
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
    NSLog(@"消息发送成功");
}

// 通过抽样缓存数据创建一个UIImage对象
-(UIImage *)imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (!colorSpace) {
        NSLog(@"CGColorSpaceCreateDeviceRGB failure");
        return nil;
    }
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage scale:0.2f orientation:UIImageOrientationRight];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    return image;
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
