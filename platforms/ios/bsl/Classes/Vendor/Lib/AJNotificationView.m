//
//  AJNotificationView.m
//  Cube-iOS
//
//  Created by Mr Right on 12-22.
//
//


#import "AJNotificationView.h"
#import <QuartzCore/QuartzCore.h>

@interface AJNotificationView ()

@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *detailDisclosureButton;
@property (nonatomic) AJNotificationType notificationType;
@property (nonatomic) AJLinedBackgroundType backgroundType;
@property (nonatomic,weak) NSTimer* animationTimer;
@property (nonatomic, assign) float moveFactor;
@property(nonatomic,assign) BOOL linedBackground;
@property (nonatomic, copy) void (^responseBlock)(void);
@property (nonatomic, strong) UIView *parentView;
@property (nonatomic, assign) float offset;
@property (nonatomic, assign) NSTimeInterval hideInterval;
@property (nonatomic, assign) BOOL showDetailDisclosure;

- (void)_drawBackgroundInRect:(CGRect)rect;
- (void) showAfterDelay:(NSTimeInterval)delayInterval;

@end

#define PANELHEIGHT  50.0f

static NSMutableArray *notificationQueue = nil;       // Global notification queue

@implementation AJNotificationView

////////////////////////////////////////////////////////////////////////
#pragma mark - View LifeCycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame andResponseBlock:nil];
}

- (id)initWithFrame:(CGRect)frame andResponseBlock:(void (^)(void))response
{
    self = [super initWithFrame:frame];
    if (self) {
        self.alpha = 0.0f;
        _notificationType = AJNotificationTypeDefault;
        _linedBackground = YES;
        _responseBlock = response;
        self.animationTimer = nil;
        
        //Title Label
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 0, self.bounds.size.width -10, PANELHEIGHT)];
        _titleLabel.textColor = [UIColor colorWithWhite:0.2f alpha:1.0f];
        _titleLabel.font = [UIFont fontWithName:@"Helvetica Neue"size:15];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _titleLabel.numberOfLines = 0;
        _titleLabel.alpha = 0.0;
        _titleLabel.textAlignment =UITextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_titleLabel];
        
        // Button
        _detailDisclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        _detailDisclosureButton.frame = CGRectMake(self.bounds.size.width - 10.0 - _detailDisclosureButton.frame.size.width, (PANELHEIGHT - _detailDisclosureButton.frame.size.height) / 2, _detailDisclosureButton.frame.size.width, _detailDisclosureButton.frame.size.height);
        _detailDisclosureButton.hidden = YES;
        [_detailDisclosureButton addTarget:self action:@selector(detailDisclosureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_detailDisclosureButton];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self _drawBackgroundInRect:(CGRect)rect];
}

- (void)detailDisclosureButtonPressed:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"detail_disclosure_button_pressed" object:self];
    [self hide];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Show
////////////////////////////////////////////////////////////////////////

+ (AJNotificationView *)showNoticeInView:(UIView *)view title:(NSString *)title{
    //Use default notification type (gray)
    return [self showNoticeInView:view type:AJNotificationTypeDefault title:title hideAfter:2.5f];
}

+ (AJNotificationView *)showNoticeInView:(UIView *)view title:(NSString *)title hideAfter:(NSTimeInterval)hideInterval{
    //Use default notification type (gray)
    return [self showNoticeInView:view type:AJNotificationTypeDefault title:title hideAfter:hideInterval];
}

+ (AJNotificationView *)showNoticeInView:(UIView *)view type:(AJNotificationType)type title:(NSString *)title hideAfter:(NSTimeInterval)hideInterval{
    return [self showNoticeInView:view type:type title:title linedBackground:AJLinedBackgroundTypeStatic hideAfter:hideInterval];
}

+ (AJNotificationView *)showNoticeInView:(UIView *)view type:(AJNotificationType)type title:(NSString *)title linedBackground:(AJLinedBackgroundType)backgroundType hideAfter:(NSTimeInterval)hideInterval{
    return [self showNoticeInView:view type:type title:title linedBackground:backgroundType hideAfter:hideInterval response:nil];
}

+ (AJNotificationView *)showNoticeInView:(UIView *)view type:(AJNotificationType)type title:(NSString *)title linedBackground:(AJLinedBackgroundType)backgroundType hideAfter:(NSTimeInterval)hideInterval detailDisclosure:(BOOL)show {
    return [self showNoticeInView:view type:type title:title linedBackground:backgroundType hideAfter:hideInterval offset:0.0 delay:0.0 detailDisclosure:show response:nil];
}

+ (AJNotificationView *)showNoticeInView:(UIView *)view type:(AJNotificationType)type title:(NSString *)title linedBackground:(AJLinedBackgroundType)backgroundType hideAfter:(NSTimeInterval)hideInterval response:(void (^)(void))response {
    
    return [self showNoticeInView:view type:type title:title linedBackground:backgroundType hideAfter:hideInterval offset:0.0 delay:0.0 detailDisclosure:NO response:response];
}

+ (AJNotificationView *)showNoticeInView:(UIView *)view type:(AJNotificationType)type title:(NSString *)title linedBackground:(AJLinedBackgroundType)backgroundType hideAfter:(NSTimeInterval)hideInterval offset:(float)offset {
    
    return [self showNoticeInView:view type:type title:title linedBackground:backgroundType hideAfter:hideInterval offset:offset delay:0.0 detailDisclosure:NO response:nil];
}

+ (AJNotificationView *)showNoticeInView:(UIView *)view type:(AJNotificationType)type title:(NSString *)title linedBackground:(AJLinedBackgroundType)backgroundType hideAfter:(NSTimeInterval)hideInterval offset:(float)offset delay:(NSTimeInterval)delayInterval response:(void (^)(void))response {
    
    return [self showNoticeInView:view type:type title:title linedBackground:backgroundType hideAfter:hideInterval offset:offset delay:delayInterval detailDisclosure:NO response:response];
}


+ (AJNotificationView *)showNoticeInView:(UIView *)view type:(AJNotificationType)type title:(NSString *)title linedBackground:(AJLinedBackgroundType)backgroundType hideAfter:(NSTimeInterval)hideInterval offset:(float)offset delay:(NSTimeInterval)delayInterval detailDisclosure:(BOOL)show response:(void (^)(void))response {
    
    AJNotificationView *noticeView = [[self alloc] initWithFrame:CGRectMake(0, 0, view.bounds.size.width, 1) andResponseBlock:response];
    noticeView.notificationType = type;
    noticeView.titleLabel.text = title;
    noticeView.linedBackground = backgroundType == AJLinedBackgroundTypeDisabled ? NO : YES;
    noticeView.parentView = view;
    noticeView.backgroundType = backgroundType;
    noticeView.offset = offset;
    noticeView.hideInterval = hideInterval;
    noticeView.showDetailDisclosure = show;
    
    if(notificationQueue == nil) {
        
        notificationQueue = [[NSMutableArray alloc] init];
    }
    
    [notificationQueue addObject:noticeView];
    
    if([notificationQueue count] == 1) {
        
        // Since this notification is the only one in the queue, it can be shown and its delay interval can be honored.
        [noticeView showAfterDelay:delayInterval];
    }
    
    return noticeView;
}

- (void) showAfterDelay:(NSTimeInterval)delayInterval {
    
    [self.parentView addSubview:self];
    
    [self setNeedsDisplay];
    
    BOOL animated = self.backgroundType == AJLinedBackgroundTypeAnimated ? YES : NO;
    
    if (animated){
        if (nil == self.animationTimer)
        {
            self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30
                                                                         target:self
                                                                       selector:@selector(setNeedsDisplay)
                                                                       userInfo:nil
                                                                        repeats:YES];
        }
    }
    else{
        if (self.animationTimer && self.animationTimer.isValid)
            [self.animationTimer invalidate];
        
        self.animationTimer = nil;
    }
    
    //if parent view is a UIWindow, check if the status bar is showing (and offset the view accordingly)
    double statusBarOffset = ([self.parentView isKindOfClass:[UIWindow class]] && (! [[UIApplication sharedApplication] isStatusBarHidden])) ? [[UIApplication sharedApplication] statusBarFrame].size.height : 0.0;
    
    if ([self.parentView isKindOfClass:[UIView class]] && ![self.parentView isKindOfClass:[UIWindow class]]) {
        
        statusBarOffset = 0.0;
    }
    self.offset = fmax(self.offset, statusBarOffset);
    
    //Change label width if detail disclosure is active
    if(self.showDetailDisclosure)
        _titleLabel.frame = CGRectMake(10.0, 0, self.bounds.size.width -50, PANELHEIGHT);

    //Animation
    [UIView animateWithDuration:0.5f
                          delay:delayInterval
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.alpha = 1.0;
                         self.frame = CGRectMake(0.0,
                                                       0.0 + self.offset,
                                                       self.frame.size.width,
                                                       PANELHEIGHT);
                         self.titleLabel.alpha = 1.0;
                     }
                     completion:^(BOOL finished) {
                         if (finished){
                             if (self.showDetailDisclosure) {
                                 self.detailDisclosureButton.hidden = !self.showDetailDisclosure;
                             }
                             
                             //Hide
                             if (self.hideInterval > 0)
                                 [self performSelector:@selector(hide) withObject:self.parentView afterDelay:self.hideInterval];
                         }
                     }];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Hide
////////////////////////////////////////////////////////////////////////

- (void)hide{
    if ([self.animationTimer isValid]){
        [self.animationTimer invalidate];
        self.animationTimer = nil;
    }
    
    [UIView animateWithDuration:0.4f
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.alpha = 0.0;
                         self.frame = CGRectMake(0.0,
                                                 0.0,
                                                 self.frame.size.width,
                                                 1.0);
                         self.titleLabel.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         if (finished){
                             [self performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:0.1f];
                             
                             // Remove this notification from the queue
                             [notificationQueue removeObjectIdenticalTo:self];
                             
                             // Show the next notification in the queue
                             if([notificationQueue count] > 0) {
                                 
                                 AJNotificationView *nextNotification = [notificationQueue objectAtIndex:0];
                                 [nextNotification showAfterDelay:0];
                             }
                         }
                     }];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Touch events
////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [self hide];
    if(self.responseBlock != nil) {
        self.responseBlock();
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)_drawBackgroundInRect:(CGRect)rect{
    
    self.moveFactor = self.moveFactor > 14.0f ? 0.0f : ++self.moveFactor;
    
    UIColor *firstColor = nil;
    UIColor *secondColor = nil;
    UIColor *toplineColor = nil;
    
    switch (self.notificationType) {
        case AJNotificationTypeDefault: { //Gray
            firstColor = RGBA(210, 210, 210, 1.0);
            secondColor = RGBA(180, 180, 180, 1.0);
            toplineColor = RGBA(230, 230, 230, 1.0);
            break;
        }
        case AJNotificationTypeBlue: { //Blue
            firstColor = RGBA(0, 193, 254, 1.0);
            secondColor = RGBA(0, 129, 182, 1.0);
            toplineColor = RGBA(20, 230, 255, 1.0);
            self.titleLabel.textColor = [UIColor whiteColor];
            break;
        }
        case AJNotificationTypeGreen: { //Green
            firstColor = RGBA(147, 207, 11, 1.0);
            secondColor = RGBA(99, 168, 1, 1.0);
            toplineColor = RGBA(167, 227, 31, 1.0);
            self.titleLabel.textColor = [UIColor whiteColor];
            break;
        }
        case AJNotificationTypeRed: { //Red
            firstColor = RGBA(204, 53, 60, 1.0);
            secondColor = RGBA(149, 30, 42, 1.0);
            toplineColor = RGBA(224, 73, 80, 1.0);
            self.titleLabel.textColor = [UIColor whiteColor];
            break;
        }
        case AJNotificationTypeOrange: { //Orange
            firstColor = RGBA(246, 141, 0, 1.0);
            secondColor = RGBA(232, 90, 6, 1.0);
            toplineColor = RGBA(266, 161, 20, 1.0);
            self.titleLabel.textColor = [UIColor whiteColor];
            break;
        }
        case AJNotificationTypeWhite: { //White
            firstColor = RGBA(248, 248, 248, 1.0);
            secondColor = RGBA(245, 245, 245, 1.0);
            toplineColor = RGBA(250, 250, 250, 1.0);
            break;
        }
        default: { //Gray
            firstColor = RGBA(210, 210, 210, 1.0);
            secondColor = RGBA(180, 180, 180, 1.0);
            toplineColor = RGBA(230, 230, 230, 1.0);
            break;
        }
    }
    
    //gradient
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    NSArray *colors = [NSArray arrayWithObjects:(id)firstColor.CGColor, (id)secondColor.CGColor, nil];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    CGPoint startPoint1 = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint1 = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGContextSaveGState(ctx);
    CGContextAddRect(ctx, rect);
    CGContextClip(ctx);
    CGContextDrawLinearGradient(ctx, gradient, startPoint1, endPoint1, 0);
    CGContextRestoreGState(ctx);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    //top line
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    if ([toplineColor respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [toplineColor getRed:&red green:&green blue:&blue alpha:&alpha];
    } else {
        const CGFloat *components = CGColorGetComponents(toplineColor.CGColor);
        red = components[0];
        green = components[1];
        blue = components[2];
        alpha = components[3];
    }
    CGContextSaveGState(ctx);
    CGContextSetRGBFillColor(ctx, 0.9f, 0.9f, 0.9f, 1.0f);
    CGContextFillRect(ctx, CGRectMake(0, 0, self.bounds.size.width, 1));
    CGContextSetLineWidth(ctx, 1.5f);
    CGContextSetRGBStrokeColor(ctx, red, green, blue, alpha);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 0, 0);
    CGContextAddLineToPoint(ctx, rect.size.width, 0);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    
    //bottom line
    CGContextSaveGState(ctx);
    CGContextSetRGBFillColor(ctx, 0.1f, 0.1f, 0.1f, 1.0f);
    CGContextFillRect(ctx, CGRectMake(0, PANELHEIGHT, self.bounds.size.width, 1));
    CGContextSetLineWidth(ctx, 1.5f);
    CGContextSetRGBStrokeColor(ctx, 0.4f, 0.4f, 0.4f, 1.0f);
    CGContextBeginPath(ctx);
    CGContextMoveToPoint(ctx, 0, PANELHEIGHT);
    CGContextAddLineToPoint(ctx, rect.size.width, PANELHEIGHT);
    CGContextStrokePath(ctx);
    CGContextRestoreGState(ctx);
    
    //shadow
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.5f;
    self.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.layer.shadowRadius = 2.0f;
    
    
    if (self.linedBackground){
        //Lines
        CGContextSaveGState(ctx);
        CGContextClipToRect(ctx, self.bounds);
        CGMutablePathRef path = CGPathCreateMutable();
        int lines = (self.bounds.size.width/16.0f + self.bounds.size.height);
        for(int i=1; i<=lines; i++) {
            CGPathMoveToPoint(path, NULL, 16.0f * i + -self.moveFactor, 1.0f);
            CGPathAddLineToPoint(path, NULL, 1.0f, 16.0f * i + -self.moveFactor);
        }
        CGContextAddPath(ctx, path);
        CGPathRelease(path);
        CGContextSetLineWidth(ctx, 6.0f);
        CGContextSetLineCap(ctx, kCGLineCapRound);
        if (self.notificationType == AJNotificationTypeWhite)
            CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:20.f green:20.f blue:20.f alpha:0.45f].CGColor);
        else
            CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.1].CGColor);
        CGContextDrawPath(ctx, kCGPathStroke);
        CGContextRestoreGState(ctx);
    }
    
}
@end