//
//  MLWXrossTransition.m
//  Pods
//
//  Created by Anton Bukov on 20.03.17.
//
//

#import "MLWXrossTransition.h"

@implementation MLWXrossTransition

- (instancetype)initWithCurrentView:(UIView *)currentView
                           nextView:(UIView *)nextView
                          direction:(MLWXrossDirection)direction {
    self = [super init];
    if (self) {
        _currentView = currentView;
        _nextView = nextView;
        _direction = direction;
        
        currentView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        nextView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        currentView.layer.shouldRasterize = YES;
        nextView.layer.shouldRasterize = YES;
    }
    return self;
}

- (void)finishTransition {
    self.currentView.transform = CGAffineTransformIdentity;
    self.nextView.transform = CGAffineTransformIdentity;
    self.currentView.layer.shouldRasterize = NO;
    self.nextView.layer.shouldRasterize = NO;
}

- (void)updateForProgress:(CGFloat)progress {
    if (self.spacing) {
        self.currentView.transform = CGAffineTransformMakeTranslation(-progress * self.direction.x * self.spacing, -progress * self.direction.y * self.spacing);
        self.nextView.transform = CGAffineTransformMakeTranslation((1.0 - progress) * self.direction.x * self.spacing, (1.0 - progress) * self.direction.y * self.spacing);
    }
    if (self.progressBlock) {
        self.progressBlock(progress);
    }
}

@end
