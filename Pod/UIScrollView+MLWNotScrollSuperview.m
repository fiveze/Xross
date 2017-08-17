//
//  UIScrollView+MLWNotScrollSuperview.m
//  Xross
//
//  Created by Anton Bukov on 26.01.16.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <JRSwizzle/JRSwizzle.h>
#import <libextobjc/extobjc.h>

#import "UIScrollView+MLWNotScrollSuperview.h"

static NSString *selectorOfInterest() {
    NSString *result = [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[@"_" stringByAppendingString:@"a"]
                                                                 stringByAppendingString:@"t"]
                                                                stringByAppendingString:@"t"]
                                                               stringByAppendingString:@"e"]
                                                              stringByAppendingString:@"m"]
                                                             stringByAppendingString:@"p"]
                                                            stringByAppendingString:@"t"]
                                                           stringByAppendingString:@"T"]
                                                          stringByAppendingString:@"o"]
                                                         stringByAppendingString:@"D"]
                                                        stringByAppendingString:@"r"]
                                                       stringByAppendingString:@"a"]
                                                      stringByAppendingString:@"g"]
                                                     stringByAppendingString:@"P"]
                                                    stringByAppendingString:@"a"]
                                                   stringByAppendingString:@"r"]
                                                  stringByAppendingString:@"e"]
                                                 stringByAppendingString:@"n"]
                                                stringByAppendingString:@"t"]
                                               stringByAppendingString:@":"]
                                              stringByAppendingString:@"f"]
                                             stringByAppendingString:@"o"]
                                            stringByAppendingString:@"r"]
                                           stringByAppendingString:@"N"]
                                          stringByAppendingString:@"e"]
                                         stringByAppendingString:@"w"]
                                        stringByAppendingString:@"B"]
                                       stringByAppendingString:@"o"]
                                      stringByAppendingString:@"u"]
                                     stringByAppendingString:@"n"]
                                    stringByAppendingString:@"d"]
                                   stringByAppendingString:@"s"]
                                  stringByAppendingString:@":"]
                                 stringByAppendingString:@"o"]
                                stringByAppendingString:@"l"]
                               stringByAppendingString:@"d"]
                              stringByAppendingString:@"B"]
                             stringByAppendingString:@"o"]
                            stringByAppendingString:@"u"]
                           stringByAppendingString:@"n"]
                          stringByAppendingString:@"d"]
                         stringByAppendingString:@"s"]
                        stringByAppendingString:@":"];
    
    NSCAssert([result isEqualToString:@"_attemptToDragParent:forNewBounds:oldBounds:"], @"");
    return result;
}

//

@interface UIScrollView (MLWNotScrollSuperview_Private)

@property (strong, nonatomic) NSNumber *mlw_notScrollSuperview_obj;
@property (strong, nonatomic) NSNumber *mlw_notScrollableBySubviews_obj;
@property (strong, nonatomic) UIScrollView *mlw_isInsideAttemptToDragParent_obj;

@end

@implementation UIScrollView (MLWNotScrollSuperview_Private)

@synthesizeAssociation(UIScrollView, mlw_notScrollSuperview_obj);
@synthesizeAssociation(UIScrollView, mlw_notScrollableBySubviews_obj);
@synthesizeAssociation(UIScrollView, mlw_isInsideAttemptToDragParent_obj);

@end

//

@implementation UIScrollView (KYNotScrollSuperview)

- (BOOL)mlw_notScrollSuperview {
    return self.mlw_notScrollSuperview_obj.boolValue;
}

- (void)setMlw_notScrollSuperview:(BOOL)mlw_notScrollSuperview {
    self.mlw_notScrollSuperview_obj = @(mlw_notScrollSuperview);
}

- (BOOL)mlw_notScrollableBySubviews {
    return self.mlw_notScrollableBySubviews_obj.boolValue;
}

- (void)setMlw_notScrollableBySubviews:(BOOL)mlw_notScrollableBySubviews {
    self.mlw_notScrollableBySubviews_obj = @(mlw_notScrollableBySubviews);
}

- (UIScrollView *)mlw_isInsideAttemptToDragParent {
    return self.mlw_isInsideAttemptToDragParent_obj;
}

+ (void)load {
    assert([self jr_swizzleMethod:NSSelectorFromString(selectorOfInterest())
                       withMethod:@selector(xxx_selectorOfInterest:newBounds:oldBounds:)
                            error:NULL]);
}

- (void)xxx_selectorOfInterest:(UIScrollView *)arg1 newBounds:(CGRect)arg2 oldBounds:(CGRect)arg3 {
    if (!self.mlw_notScrollSuperview && !arg1.mlw_notScrollableBySubviews) {
        arg1.mlw_isInsideAttemptToDragParent_obj = self;
        [self xxx_selectorOfInterest:arg1 newBounds:arg2 oldBounds:arg3];
        arg1.mlw_isInsideAttemptToDragParent_obj = nil;
    }
}

@end
