//
//  ViewController.m
//  TimeScaleProject
//
//  Created by xudandan on 16/6/29.
//  Copyright © 2016年 WuLian. All rights reserved.
//

#import "ViewController.h"
#import "TimeViewer.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelTime;

@end

@implementation ViewController {
    TimeViewer *timer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    timer = [[TimeViewer alloc] initWithFrame:CGRectMake(0, 200, [[UIScreen mainScreen] bounds].size.width, 140)];
    self.labelTime.text = timer.time;
    [self.view addSubview:timer];
    
    timer.returnMoveTime = ^(NSString *tim) {
        NSLog(@"滚动时间");
    };
    
    __weak ViewController *weakSelf = self;
    timer.returnTimeString = ^(NSString *timstr) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.labelTime.text = timstr;
        });
    };
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleTimeChange:) name:MiddleTimeChangedNotification object:nil];
    
    //时间增加的定时器
    NSTimer * timeAdd = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeAddOneSecond:) userInfo:nil repeats:YES];
    [timeAdd fire];
}

- (void)timeAddOneSecond:(id)sender {
    timer.midTimeInterval += 1;
    [timer reDraw];
}

- (void)handleTimeChange:(NSNotification *)notice {
    //移动时间停止  接收到通知
    self.labelTime.text = notice.object;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
