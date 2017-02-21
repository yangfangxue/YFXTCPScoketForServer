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
@interface ViewController ()<GCDAsyncSocketDelegate>
{
    
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
     
     PS:iPhone手机
     
     本Demo为服务端Demo
     
     配合学习请看客户端Demo
     */
    
    //1.创建服务器socket
    self.serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    //2.开始监听（开放哪一个端口）
    NSError *error = nil;
    
    BOOL result = [self.serverSocket acceptOnPort:8000 error:&error];
    if (result) {
        //开放成功
        NSLog(@"开放成功");
    }else{
        //开放失败
        NSLog(@"开放失败");
    }
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    //给链接的客户端发送消息
    [self.clientSocket writeData:[@"我是服务端" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
}
#pragma mark - delegate


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
    
    NSLog(@"读取客户端发过来的消息 = %@",message);
    
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
