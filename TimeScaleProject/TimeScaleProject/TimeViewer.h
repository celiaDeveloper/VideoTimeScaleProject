//
//  TimeViewer.h
//  TimeViewer
//
//  Created by xudandan on 16/2/16.
//  Copyright © 2016年 WuLian. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^PostTimeWhenMove)(NSString *time);
typedef void (^PostTimeStringImmediate)(NSString *time);

#define MiddleTimeChangedNotification @"timeChanged"

@interface TimeViewer : UIView

@property (nonatomic, assign) NSTimeInterval midTimeInterval;//中间时间的 时间戳
@property (nonatomic, strong) NSString *time;//中间时间 字符串

@property (nonatomic, strong) NSArray *recordTime;//标记有数据的时间点 格式要是 [@{@"start":时间戳, @"end":时间戳},@{@"start":时间戳, @"end":时间戳}]

@property (nonatomic, strong) PostTimeWhenMove returnMoveTime;
@property (nonatomic, strong) PostTimeStringImmediate returnTimeString;

- (void)reDraw;

@end
