//
//  TimeViewer.m
//  TimeViewer
//
//  Created by xudandan on 16/2/16.
//  Copyright © 2016年 WuLian. All rights reserved.
//

#import "TimeViewer.h"
typedef enum{
    SCALETYPEFIVEDAY,
    SCALETYPETENHOURS,
    SCALETYPEONEHOUR,
}SCALETYPE;

const int MINSCALEMINUTEFIVEDAY  = 24; //一小格代表的分钟数
const int MINSCALEMINUTETENHOURS = 2;
const int MINSCALEMINUTEONEHOUR  = 1;

const int ONEDAY_SECONDS    = (24*60*60);
const int ONEHOUR_SECONDS   = (60*60);
const int ONEMINUTE_SECONDS = 60;

#define SELF_HEIGHT         self.bounds.size.height
#define SELF_WIDTH          self.bounds.size.width
#define SCREEN_WIDTH        [[UIScreen mainScreen] bounds].size.width

#define MIN_UNIT_WIDTH      1
const float MIN_SCALENUM = 1.0;//最小缩放比
const float MAX_SCALENUM = 5.0;

//刻度线相关默认值
#define DAYPOINTLENGTH      30
#define HOURPOINTLENGTH     20
#define MINUTEPOINTLENGTH   15

const CGFloat DEFAULT_SCALETIME_TEXTFONT =10;
#define DEFAULT_SCALETIME_TEXTCOLOR    [UIColor lightGrayColor]
#define DEFAULT_SCALELINE_COLOR        [UIColor blackColor]
const CGFloat DEFAULT_SCALELINE_WIDTH = 1.0;
#define DEFAULT_SCALEMIDDLE_LINECOLOR  [UIColor redColor]
const CGFloat DEFAULT_SCALE_TOPLINE_WIDTH =0.2;
#define DEFAULT_RECORDTIME_VIEWCOLOR   [UIColor colorWithRed:(0 / 255.0) green:(255 / 255.0) blue:(255 / 255.0) alpha:0.4]

#define TOPGUIDELENGTH      30
#define INDICATORWIDTH      6


@interface TimeViewer ()

@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGPoint movePoint;
@property (nonatomic, assign) CGPoint endPoint;

@property (nonatomic, strong) UIPinchGestureRecognizer *pinchGesture;
@property (nonatomic, assign) SCALETYPE currentType;

@property (nonatomic, strong) NSDecimalNumber* lastScaleNumber;

@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, strong) NSDateFormatter *hourMinuteFormatter;
@property (nonatomic, assign) NSInteger secondsFromGMT;

@property (nonatomic, assign) CGFloat recordScaleValue; //记录捏合手势过程中，上一次的缩放值
@property (nonatomic, assign) int minScaleMinute; //最小刻度 代表的分钟数


@property (nonatomic, strong) NSSet<UITouch *> *touches;
@property (nonatomic, assign) NSUInteger gestureCount;
@property (nonatomic, assign) BOOL isOright;//判断是否打开定时器

@property (nonatomic, assign) BOOL isMidRecord;

@end

@implementation TimeViewer


- (instancetype)initWithFrame:(CGRect)frame {
    self.isOright = NO;
    self = [super initWithFrame:frame];
    
    //false data
    [self makeRecordTimeData];
    
    if (self) {
        self.pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGesture:)];
        [self addGestureRecognizer:self.pinchGesture];
        self.currentType = SCALETYPETENHOURS;
        
        self.lastScaleNumber = [[NSDecimalNumber alloc] initWithFloat:MAX_SCALENUM];
        
        NSDate *sysDate = [NSDate date];
        NSTimeZone *zone = [NSTimeZone systemTimeZone];
        self.secondsFromGMT = [zone secondsFromGMTForDate:sysDate];
        
        NSDate *currentZoneDate = [sysDate dateByAddingTimeInterval:self.secondsFromGMT];
        self.midTimeInterval = [currentZoneDate timeIntervalSince1970];
        
        self.formatter = [[NSDateFormatter alloc] init];
        self.formatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
        self.hourMinuteFormatter = [[NSDateFormatter alloc] init];
        self.hourMinuteFormatter.dateFormat = @"hh:mm";

        self.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)makeRecordTimeData {
    //false data
    NSTimeInterval temTimeData = [[NSDate date] timeIntervalSince1970];
    NSString *s1 = [NSString stringWithFormat:@"%f",temTimeData];
    NSString *e1 = [NSString stringWithFormat:@"%f",temTimeData + 20000];
    
    NSString *s2 = [NSString stringWithFormat:@"%f",temTimeData + 23000];
    NSString *e2 = [NSString stringWithFormat:@"%f",temTimeData + 29000];
    
    NSDictionary *dic1 = @{@"start":s1,@"end":e1};
    NSDictionary *dic2 = @{@"start":s2,@"end":e2};
    self.recordTime = @[dic1,dic2];
}

- (void)setMidTimeInterval:(NSTimeInterval)midTimeInterval {
    _midTimeInterval = midTimeInterval;
    [self getTimeStrWithMidTimeInterval];
    
    if (self.returnTimeString) {
        self.returnTimeString(self.time);
    }
}

- (void)getTimeStrWithMidTimeInterval {
    
    self.currentDate = [NSDate dateWithTimeIntervalSince1970:(self.midTimeInterval - self.secondsFromGMT)];
    
    self.time = [self.formatter stringFromDate:self.currentDate];
}

- (void)pinchGesture:(UIPinchGestureRecognizer*)gesture {
    
          self.isOright = YES;
    
            if (gesture.state == UIGestureRecognizerStateBegan) {
                self.recordScaleValue = gesture.scale;
            }

            else if (gesture.state == UIGestureRecognizerStateChanged && self.isOright == YES) {

                
                if (self.recordScaleValue != gesture.scale) {
                    NSDecimalNumberHandler *roundUp = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundBankers scale:1 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:YES];
                    
                    if (gesture.scale > 1.0) {
                        //expand
                        if ([self.lastScaleNumber floatValue] >= MAX_SCALENUM) {
                            
                            switch (self.currentType) {
                                case SCALETYPEFIVEDAY:
                                    self.currentType = SCALETYPETENHOURS;
                                    break;
                                case SCALETYPETENHOURS:
                                    self.currentType = SCALETYPEONEHOUR;
                                    break;
                                case SCALETYPEONEHOUR:
                                {
                                    NSLog(@"have the largest, can not be bigger");
                                    [self reDraw];
                                    return;
                                }
                                    break;
                                default:
                                    break;
                            }
                            
                            self.lastScaleNumber = [[NSDecimalNumber alloc] initWithDouble:MIN_SCALENUM];
                            
                            return;
                        }
                        
                        CGFloat temp = (gesture.scale - 1.0) / (2 * 2);
                        NSDecimalNumber* currentScaleValue = [[NSDecimalNumber alloc] initWithFloat:temp];
                        
                        self.lastScaleNumber = [self.lastScaleNumber decimalNumberByAdding:currentScaleValue withBehavior:roundUp];
                        
                        if ([self.lastScaleNumber floatValue] > MAX_SCALENUM) {
                            self.lastScaleNumber = [[NSDecimalNumber alloc] initWithDouble:MAX_SCALENUM];
                            return;
                        }
                        
                    } else if (gesture.scale < 1.0) {
                        //Narrow
                        if ([self.lastScaleNumber floatValue] <= MIN_SCALENUM) {
                            
                            
                            switch (self.currentType) {
                                case SCALETYPEFIVEDAY:
                                {
                                    NSLog(@"have a minimum, can not be smaller");
                                    [self reDraw];
                                    return;
                                }
                                    break;
                                case SCALETYPETENHOURS:
                                    self.currentType = SCALETYPEFIVEDAY;
                                    break;
                                case SCALETYPEONEHOUR:
                                    self.currentType = SCALETYPETENHOURS;
                                    break;
                                default:
                                    break;
                            }
                            
                            self.lastScaleNumber = [[NSDecimalNumber alloc] initWithDouble:MAX_SCALENUM];
                            
                            return;
                        }
                        
                        CGFloat temp = (1.0 - gesture.scale) / (2 * 2);
                        NSDecimalNumber* currentScaleValue = [[NSDecimalNumber alloc] initWithFloat:temp];
                        
                        self.lastScaleNumber = [self.lastScaleNumber decimalNumberBySubtracting:currentScaleValue withBehavior:roundUp];
                        
                        if ([self.lastScaleNumber floatValue] < MIN_SCALENUM) {
                            self.lastScaleNumber = [[NSDecimalNumber alloc] initWithDouble:MIN_SCALENUM];
                            return;
                        }
                        
                        NSLog(@"self.lastScaleNumber: %@", self.lastScaleNumber);
                        
                    }
                    
                    self.recordScaleValue = gesture.scale;
                }
            }
            
            else if (gesture.state == UIGestureRecognizerStateEnded){
                //release two hands    pinch gesture end
                NSLog(@"pinch end");
                self.isOright = NO;
            }
    
    [self reDraw];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    self.isOright = YES;
    
    UITouch *touch = [touches anyObject];
    self.startPoint = [touch locationInView:self];

}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    
    self.touches = touches;
    self.gestureCount = touches.count;
    
    if (self.pinchGesture.numberOfTouches == 1 && self.gestureCount == 1) {
    
        //redraw
        UITouch *touch = [touches anyObject];
        self.movePoint = [touch locationInView:self];
        
        CGFloat offsetX = self.movePoint.x - self.startPoint.x;
        
        
        BOOL isChangeMovePoint;
        
        if (offsetX < 0) {
            //left movement   add the time
            isChangeMovePoint = [self setTimeWithOffsetIndex:offsetX];
            
        } else {
            //right movement  reduce the time
            isChangeMovePoint = [self setTimeWithOffsetIndex:offsetX];
            
        }
        
        if (isChangeMovePoint) {
           self.startPoint = self.movePoint;
        }
        
        if (self.returnMoveTime) {
            self.returnMoveTime(self.time);
        }
        
        [self reDraw];
    
    }
    
   
}

- (BOOL)setTimeWithOffsetIndex:(float)offset {
    
    int perUnitSeconds = self.minScaleMinute * ONEMINUTE_SECONDS;
    float perUnitSize = [self.lastScaleNumber floatValue] * MIN_UNIT_WIDTH;
    float addedSeconds = offset / perUnitSize * perUnitSeconds;
    double oldMidTimeInterval = self.midTimeInterval;
    self.midTimeInterval -= addedSeconds;
    
    int addOne = (abs((int)self.midTimeInterval) % ONEMINUTE_SECONDS) > 30 ? 1:0;
    int changeToMinutes = (int)self.midTimeInterval / ONEMINUTE_SECONDS + addOne;
    
    self.midTimeInterval = changeToMinutes * ONEMINUTE_SECONDS;

    if (self.midTimeInterval != oldMidTimeInterval) {
        return YES;
    }
    return NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    self.endPoint = [touch locationInView:self];
    
    self.startPoint = CGPointZero;
    self.endPoint = CGPointZero;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MiddleTimeChangedNotification object:self.time];
}

- (void)setLastScaleNumber:(NSDecimalNumber *)lastScaleNumber {
    
    _lastScaleNumber = lastScaleNumber;
    
}

- (void)setCurrentType:(SCALETYPE)currentType {
    
    switch (currentType) {
        case SCALETYPEFIVEDAY:
            self.minScaleMinute = MINSCALEMINUTEFIVEDAY;
            
            break;
        case SCALETYPETENHOURS:
            self.minScaleMinute = MINSCALEMINUTETENHOURS;
            
            break;
        case SCALETYPEONEHOUR:
            self.minScaleMinute = MINSCALEMINUTEONEHOUR;
            
            break;
        default:
            break;
    }
    
    _currentType = currentType;
    [self reDraw];
    
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    /////////**************  Draw tick marks  绘刻度线  *****************//////////
    int perUnitSeconds = self.minScaleMinute * ONEMINUTE_SECONDS;
    float perUnitSize = [self.lastScaleNumber floatValue] * MIN_UNIT_WIDTH;

    int middleLeftRemainTimeStamp = (int)self.midTimeInterval % perUnitSeconds;
    float midLeftFirstStart = 0;
    if (middleLeftRemainTimeStamp == 0) {
        midLeftFirstStart = DEFAULT_SCALELINE_WIDTH / 2.0;
    }else {
        midLeftFirstStart = (middleLeftRemainTimeStamp / (float)perUnitSeconds) * perUnitSize + DEFAULT_SCALELINE_WIDTH;
    }
    
    int leftCount = (SELF_WIDTH / 2 - midLeftFirstStart) / (float)(perUnitSize + DEFAULT_SCALELINE_WIDTH);
    float currentOffset = SELF_WIDTH / 2 - midLeftFirstStart - leftCount * (perUnitSize + DEFAULT_SCALELINE_WIDTH);
    double currentTimeStamp = self.midTimeInterval - middleLeftRemainTimeStamp - leftCount * perUnitSeconds;
    double lastTimeStamp = (double)(currentTimeStamp + (SELF_WIDTH - currentOffset) * perUnitSeconds / (float)(perUnitSize + DEFAULT_SCALELINE_WIDTH));
    
    //Draw video period  绘制有视频的时间段
    if (self.recordTime.count > 0) {
        _isMidRecord = false;
        for (int i = 0; i < self.recordTime.count; i++) {
            NSDictionary *recordDic = [self.recordTime objectAtIndex:i];
            double recordTimeStart = [recordDic[@"start"] doubleValue];
            double recordTimeEnd = [recordDic[@"end"] doubleValue];
            
            if (recordTimeStart > lastTimeStamp) {
                break;
            }
            
            if (self.midTimeInterval >= recordTimeStart && self.midTimeInterval <= recordTimeEnd) {
                _isMidRecord = true;
            }
            
            if (recordTimeStart <= lastTimeStamp && recordTimeEnd > currentTimeStamp) {
                float recordStartX = currentOffset + (recordTimeStart - currentTimeStamp) * (perUnitSize + DEFAULT_SCALELINE_WIDTH) / (float)perUnitSeconds;
                float recordEndX;
                if (recordTimeEnd >= lastTimeStamp) {
                    recordEndX = SELF_WIDTH;
                }else {
                    recordEndX = currentOffset + (recordTimeEnd - currentTimeStamp) * (perUnitSize + DEFAULT_SCALELINE_WIDTH) / (float)perUnitSeconds;
                }
                
                [DEFAULT_RECORDTIME_VIEWCOLOR setStroke];
                [DEFAULT_RECORDTIME_VIEWCOLOR setFill];
                CGContextSetLineWidth(context, 0.5);
                
                CGMutablePathRef pathR = CGPathCreateMutable();
                CGPathMoveToPoint(pathR, NULL, recordStartX, TOPGUIDELENGTH);
                CGPathAddLineToPoint(pathR, NULL, recordStartX, SELF_HEIGHT);
                CGPathAddLineToPoint(pathR, NULL, recordEndX, SELF_HEIGHT);
                CGPathAddLineToPoint(pathR, NULL, recordEndX, TOPGUIDELENGTH);
                CGPathAddLineToPoint(pathR, NULL, recordStartX, TOPGUIDELENGTH);
                
                CGContextAddPath(context, pathR);
                CGPathRelease(pathR);
                CGContextDrawPath(context, kCGPathFillStroke);
                
            }
            
        }
    }
    
    
    [DEFAULT_SCALELINE_COLOR setStroke];
    [DEFAULT_SCALELINE_COLOR setFill];
    
    int pointLenght = 0;
    while (currentOffset <= SELF_WIDTH) {
        NSInteger allMinutes = currentTimeStamp / perUnitSeconds;
        
        int remainderBy6 = allMinutes % 6;
        int remainderBy5 = allMinutes % 5;
        
        if (remainderBy6 == 0 && remainderBy5 ==  0) {
            pointLenght = DAYPOINTLENGTH;
            
            NSString * timeStr = [self getScaleLineHourAndMinuteWithTimeInterval:currentTimeStamp];
            
            UIFont *font = [UIFont systemFontOfSize:DEFAULT_SCALETIME_TEXTFONT];
            CGSize textSize = [timeStr sizeWithAttributes:@{ NSFontAttributeName : font}];
            //drawing time on scale 绘制刻度尺上的时间
            [timeStr drawInRect:CGRectMake(currentOffset, TOPGUIDELENGTH + pointLenght - textSize.height, textSize.width, textSize.height) withAttributes:@{NSFontAttributeName: font, NSForegroundColorAttributeName: DEFAULT_SCALETIME_TEXTCOLOR }];
            
            
            
        }else if (remainderBy6 != 0 && remainderBy5 == 0) {
            pointLenght = HOURPOINTLENGTH;
            
        }else {
            pointLenght = MINUTEPOINTLENGTH;
            
        }
        
        //up and down line 上下刻度线
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, NULL, currentOffset, TOPGUIDELENGTH);
        CGPathAddLineToPoint(path, NULL, currentOffset, TOPGUIDELENGTH + pointLenght);
        
        CGContextAddPath(context, path);
        
        CGMutablePathRef path1 = CGPathCreateMutable();
        CGPathMoveToPoint(path1, NULL, currentOffset, SELF_HEIGHT);
        CGPathAddLineToPoint(path1, NULL, currentOffset, SELF_HEIGHT - pointLenght);
        CGContextAddPath(context, path1);
        
        CGPathRelease(path);
        CGPathRelease(path1);
        
        currentTimeStamp += perUnitSeconds;
        currentOffset += (DEFAULT_SCALELINE_WIDTH + perUnitSize);
        
        

    }
    
    
    ///////////**************  Draw tick marks  绘刻度线  *****************///////////
    
    CGContextSetLineWidth(context, DEFAULT_SCALELINE_WIDTH);
    CGContextStrokePath(context);
    
    //draw the middle red line  绘画中间的红线
    [DEFAULT_SCALEMIDDLE_LINECOLOR setStroke];
    [DEFAULT_SCALEMIDDLE_LINECOLOR setFill];
    
    CGMutablePathRef indicatorPath = CGPathCreateMutable();
    CGPathMoveToPoint(indicatorPath, NULL, SELF_WIDTH / 2, INDICATORWIDTH + TOPGUIDELENGTH);
    CGPathAddLineToPoint(indicatorPath, NULL, SELF_WIDTH / 2 - INDICATORWIDTH / 2, TOPGUIDELENGTH);
    CGPathAddLineToPoint(indicatorPath, NULL, SELF_WIDTH / 2 + INDICATORWIDTH / 2, TOPGUIDELENGTH);
    CGPathAddLineToPoint(indicatorPath, NULL, SELF_WIDTH / 2, INDICATORWIDTH + TOPGUIDELENGTH);
    
    CGPathAddLineToPoint(indicatorPath, NULL, SELF_WIDTH / 2, SELF_HEIGHT - INDICATORWIDTH);
    CGPathAddLineToPoint(indicatorPath, NULL, SELF_WIDTH / 2 - INDICATORWIDTH / 2, SELF_HEIGHT);
    CGPathAddLineToPoint(indicatorPath, NULL, SELF_WIDTH / 2 + INDICATORWIDTH / 2, SELF_HEIGHT);
    CGPathAddLineToPoint(indicatorPath, NULL, SELF_WIDTH / 2 , SELF_HEIGHT - INDICATORWIDTH);
    
    CGContextAddPath(context, indicatorPath);
    CGPathRelease(indicatorPath);
    CGContextDrawPath(context, kCGPathFillStroke);
    //draw the top and bottom horizontal line 上下边线的颜色
    [DEFAULT_SCALELINE_COLOR setStroke];
    [DEFAULT_SCALELINE_COLOR setFill];
    //上边线的宽度
    CGContextSetLineWidth(context, DEFAULT_SCALE_TOPLINE_WIDTH);
    //绘画上下边线
    for (int i = 0; i < 2; i ++) {
        
        CGMutablePathRef linePath = CGPathCreateMutable();
        
        CGPathMoveToPoint(linePath, NULL, 0, TOPGUIDELENGTH + i * (SELF_HEIGHT - TOPGUIDELENGTH - DEFAULT_SCALE_TOPLINE_WIDTH));
        CGPathAddLineToPoint(linePath, NULL, SELF_WIDTH, TOPGUIDELENGTH + i * (SELF_HEIGHT - TOPGUIDELENGTH - DEFAULT_SCALE_TOPLINE_WIDTH));
        
        CGContextAddPath(context, linePath);
    }
    
    CGContextStrokePath(context);
}

- (NSString *)getScaleLineHourAndMinuteWithTimeInterval:(double)timeInterval {
    NSTimeInterval tim = timeInterval;
    
    NSString *timeStr = [self.hourMinuteFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:(tim - self.secondsFromGMT)]];
    
    return timeStr;
}

- (void)reDraw {
    
    [self setNeedsDisplay];
    
}

@end
