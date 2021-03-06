//
//  ImageScroller.m
//  cube-ios
//
//  Created by apple2310 on 13-9-10.
//
//

#import "ImageScroller.h"
#import "AsyncImageView.h"
#import "ServerAPI.h"
#import <QuartzCore/QuartzCore.h>

@implementation ImageScroller

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled=YES;
        imageView=[[AsyncImageView alloc] initWithFrame:self.bounds];
        imageView.contentMode=UIViewContentModeScaleAspectFit;
        [self addSubview:imageView];
        
        self.backgroundColor=[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.75f];
    }
    return self;
}


-(void)showInView:(UIView*)view{
    [view addSubview:self];
    
    
    CAKeyframeAnimation * animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 0.3;
    animation.removedOnCompletion = YES;
    animation.fillMode = kCAFillModeForwards;
    NSMutableArray *values = [NSMutableArray array];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    animation.values = values;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    [imageView.layer addAnimation:animation forKey:nil];

    self.alpha=0.0f;
    [UIView animateWithDuration:0.1f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        
        self.alpha=1.0f;
    } completion:^(BOOL finish){
        
    }];

    
}

-(void)showImage:(NSString*)imageFile{
    if([imageFile length]>0){
        
        if([[NSFileManager defaultManager] fileExistsAtPath:imageFile]){
            imageView.image=[UIImage imageWithContentsOfFile:imageFile];
        }
        else{
            NSString *url = [ServerAPI urlForAttachmentId:imageFile];
            
            url=[url stringByAppendingFormat:@"?sessionKey=%@&appKey=%@",[[NSUserDefaults standardUserDefaults] objectForKey:@"token"],kAPPKey];
            [imageView loadImageWithURLString:url];
        }

    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    [UIView animateWithDuration:0.3f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
    
        self.alpha=0.0f;
    } completion:^(BOOL finish){
    
        [self removeFromSuperview];
    }];
}

@end
