//
//  MLWXrossScrollView.m
//  Xross
//
//  Created by Anton Bukov on 18.12.15.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>

#import <JRSwizzle/JRSwizzle.h>
#import <libextobjc/extobjc.h>

#import "UIResponder+MLWCurrentFirstResponder.h"
#import "UIScrollView+MLWNotScrollSuperview.h"
#import "UIScrollView+MLWStickyKeyboard.h"
#import "MLWXrossScrollView.h"

//

// Negative value of one of insets means boincing started to that direction
static UIEdgeInsets MLWScrollViewBouncingInsetsForContentOffset(UIScrollView *scrollView, CGPoint contentOffset) {
    CGFloat topOffset = contentOffset.y + scrollView.contentInset.top;
    CGFloat leftOffset = contentOffset.x + scrollView.contentInset.left;
    CGFloat bottomOffset = contentOffset.y + CGRectGetHeight(scrollView.bounds)
                         - scrollView.contentInset.bottom - scrollView.contentSize.height;
    CGFloat rightOffset = contentOffset.x + CGRectGetWidth(scrollView.bounds)
                        - scrollView.contentInset.right - scrollView.contentSize.width;
    return UIEdgeInsetsMake(topOffset, leftOffset, -bottomOffset, -rightOffset);
}

static void ViewSetFrameWithoutRelayoutIfPossible(UIView *view, CGRect frame) {
    CGRect bounds = (CGRect){view.bounds.origin, frame.size};
    if (!CGSizeEqualToSize(view.bounds.size, bounds.size)) {
        view.bounds = bounds;
    }
    CGPoint center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    if (!CGPointEqualToPoint(view.center, center)) {
        view.center = center;
    }
}

//

@interface UIScrollView () <UIGestureRecognizerDelegate>

@end

//

@interface MLWXrossScrollView ()

@property (strong, nonatomic) NSHashTable<UIScrollView *> *innerScrollViews;
@property (assign, nonatomic) BOOL delegateRespondsToScrollViewWillScrollToContentOffset;
@property (assign, nonatomic) BOOL avoidInnerScrollViewRecursiveCall;
@property (assign, nonatomic) BOOL skipSetContentOffsetCalls;

@end

@implementation MLWXrossScrollView

@dynamic delegate;

+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    MLWXrossScrollView *this;
    return @{
        @keypath(this.originOffset):[NSSet setWithArray:@[
            @keypath(this.originOffsetInSteps),
            @keypath(this.bounds.size),
        ]],
        @keypath(this.relativeContentOffset):[NSSet setWithArray:@[
            @keypath(this.contentOffset),
            @keypath(this.originOffset),
        ]],
    }[key] ?: [super keyPathsForValuesAffectingValueForKey:key];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.showsHorizontalScrollIndicator = NO;
        self.showsVerticalScrollIndicator = NO;
        self.directionalLockEnabled = YES;
        self.delaysContentTouches = NO;
        self.pagingEnabled = YES;
        self.scrollsToTop = NO;
        
        self.mlw_stickyKeyboard = YES;
        self.mlw_notScrollableBySubviews = YES;
        
        _innerScrollViews = [NSHashTable weakObjectsHashTable];
        
        [self updateInsets];
    }
    return self;
}

- (BOOL)isKindOfClass:(Class)aClass {
    if (aClass == [UIScrollView class]) {
        return NO;
    }
    return [super isKindOfClass:aClass];
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view {
    if ([view.class conformsToProtocol:@protocol(XrossScrollable)]) {
        return [(UIView<XrossScrollable> *)view allowXrossScrolling];
    }
    
    return [super touchesShouldCancelInContentView:view]
    || [view isKindOfClass:[UITextField class]];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self updateInsets];
    if (self.nextView == nil) {
        [super setContentOffset:self.originOffset];
        if (self.centerView) {
            CGRect frame = (CGRect){self.originOffset, self.bounds.size};
            ViewSetFrameWithoutRelayoutIfPossible(self.centerView, frame);
        }
    }
}

- (void)layoutSubviews {
    if (self.nextView == nil) {
        [super layoutSubviews];
    }
}

- (CGPoint)originOffset {
    return CGPointMake(self.originOffsetInSteps.x * CGRectGetWidth(self.bounds),
                       self.originOffsetInSteps.y * CGRectGetHeight(self.bounds));
}

- (CGPoint)relativeContentOffset {
    return CGPointMake(self.contentOffset.x - self.originOffset.x,
                       self.contentOffset.y - self.originOffset.y);
}

- (void)setOriginOffsetInSteps:(CGPoint)originOffsetInSteps {
    _originOffsetInSteps = originOffsetInSteps;
    [self updateInsets];
}

- (void)setNextDirection:(CGPoint)nextDirection {
    _nextDirection = nextDirection;
    [self updateInsets];
}

- (void)updateInsets {
    CGPoint savedContentOffset = self.contentOffset;
    
    self.skipSetContentOffsetCalls = YES;
    self.contentSize = self.bounds.size;
    self.contentInset = UIEdgeInsetsMake(
        ((self.nextDirection.y < 0) - self.originOffsetInSteps.y) * CGRectGetHeight(self.bounds) + 1,
        ((self.nextDirection.x < 0) - self.originOffsetInSteps.x) * CGRectGetWidth(self.bounds) + 1,
        ((self.nextDirection.y > 0) + self.originOffsetInSteps.y) * CGRectGetHeight(self.bounds) + 1,
        ((self.nextDirection.x > 0) + self.originOffsetInSteps.x) * CGRectGetWidth(self.bounds) + 1);
    self.skipSetContentOffsetCalls = NO;
    
    [super setContentOffset:savedContentOffset];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self updateInsets];
    self.contentOffset = self.originOffset;
}

- (void)setCenterView:(UIView *)centerView {
    if (centerView) {
        if (centerView.superview != self) {
            [centerView removeFromSuperview];
            
            CGRect frame = (CGRect){self.originOffset, self.bounds.size};
            ViewSetFrameWithoutRelayoutIfPossible(centerView, frame);
            [self addSubview:centerView];
        }
    }
    else {
        [_centerView removeFromSuperview];
    }
    
    _centerView = centerView;
}

- (void)setNextView:(UIView *)nextView toDirection:(CGPoint)direction {
    if (nextView) {
        if (nextView.superview != self) {
            [nextView removeFromSuperview];
            
            NSAssert(self.centerView, @"centerView should exist when setting nextView");
            CGRect frame = (CGRect){self.originOffset, self.bounds.size};
            frame.origin.x += direction.x * CGRectGetWidth(self.bounds);
            frame.origin.y += direction.y * CGRectGetHeight(self.bounds);
            ViewSetFrameWithoutRelayoutIfPossible(nextView, frame);
            [self addSubview:nextView];
        }
    }
    else {
        [_nextView removeFromSuperview];
    }
    
    _nextView = nextView;
}

- (void)willRemoveSubview:(UIView *)subview {
    [super willRemoveSubview:subview];
    
    if (_centerView == subview) {
        _centerView = _nextView;
        _nextView = nil;
    }
    
    if (_nextView == subview) {
        _nextView = nil;
    }
}

- (void)setDelegate:(id<MLWXrossScrollViewDelegate>)delegate {
    self.delegateRespondsToScrollViewWillScrollToContentOffset = [delegate respondsToSelector:@selector(scrollView:willScrollToContentOffset:)];
    [super setDelegate:delegate];
}

- (void)setContentOffset:(CGPoint)contentOffset {
    if (self.skipSetContentOffsetCalls) {
        return;
    }
    
    if (self.avoidInnerScrollViewRecursiveCall) {
        [super setContentOffset:contentOffset];
        return;
    }
    
    // Avoid simultaneous scrolling of both views
    UIEdgeInsets insets = MLWScrollViewBouncingInsetsForContentOffset(self, contentOffset);
    for (UIScrollView *innerScrollView in [self.innerScrollViews copy]) {
        if (!innerScrollView.isTracking &&
            !innerScrollView.isDragging &&
            !innerScrollView.isDecelerating) {
            
            [self.innerScrollViews removeObject:innerScrollView];
            continue;
        }
        
        UIEdgeInsets innerInset = MLWScrollViewBouncingInsetsForContentOffset(innerScrollView, innerScrollView.contentOffset);
        if (innerScrollView.isZooming ||
            (insets.top < 1 && round(innerInset.top) > 0) ||
            (insets.left < 1 && round(innerInset.left) > 0) ||
            (insets.right < 1 && round(innerInset.right) > 0) ||
            (insets.bottom < 1 && round(innerInset.bottom) > 0)) {
            contentOffset = self.contentOffset;
            [self.panGestureRecognizer setTranslation:CGPointZero inView:self];
            break;
        }
    }

    self.avoidInnerScrollViewRecursiveCall = YES;
    {
        if (self.delegateRespondsToScrollViewWillScrollToContentOffset &&
            !CGPointEqualToPoint(contentOffset, self.contentOffset)) {
            contentOffset = [self.delegate scrollView:self willScrollToContentOffset:contentOffset];
        }
        [super setContentOffset:contentOffset];
    }
    self.avoidInnerScrollViewRecursiveCall = NO;
}

// Avoid UITextField to scroll superview to become visible on becoming first responder
- (void)setContentOffset:(CGPoint)contentOffset animated:(BOOL)animated {
    // Do nothing
}

- (void)setContentOffsetTo:(CGPoint)contentOffset animated:(BOOL)animated {
    [super setContentOffset:contentOffset animated:animated];
}

#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    
    // Allows inner UITableView swipe-to-delete gesture
    if ([otherGestureRecognizer.view.superview isKindOfClass:[UITableView class]]) {
        return YES;
    }
    
    if ([[MLWXrossScrollView superclass] instancesRespondToSelector:_cmd]) {
        return [super gestureRecognizer:gestureRecognizer shouldRequireFailureOfGestureRecognizer:otherGestureRecognizer];
    }
    
    return NO;
}

- (BOOL)askOtherGestureRecognizersDelegateToRecognizeSimultaneously:(UIGestureRecognizer *)otherGestureRecognizer {
    id<MLWXrossGestureRecognizerDelegate> delegate = (id)otherGestureRecognizer.delegate;
    BOOL whatOtherGestureRecognizerWants = [delegate gestureRecognizer:otherGestureRecognizer allowXrossPanGestureRecognizerToWorkSimultaneously:self.panGestureRecognizer];
    return whatOtherGestureRecognizerWants;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer != self.panGestureRecognizer) {
        return YES;
    }
    
    // Deny simultaneous non-scroll pan gesture recognizers
    if ([otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        ![otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        
        BOOL result = NO;
        if ([otherGestureRecognizer.delegate respondsToSelector:@selector(gestureRecognizer:allowXrossPanGestureRecognizerToWorkSimultaneously:)]) {
            result = [self askOtherGestureRecognizersDelegateToRecognizeSimultaneously:otherGestureRecognizer];
        }
    
        return result;
    }
    
    // Allow simultateous scrolling with inner scroll views
    if (otherGestureRecognizer.view != self &&
        [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
        [otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        
        BOOL result = YES;
        if ([otherGestureRecognizer.delegate respondsToSelector:@selector(gestureRecognizer:allowXrossPanGestureRecognizerToWorkSimultaneously:)]) {
            result = [self askOtherGestureRecognizersDelegateToRecognizeSimultaneously:otherGestureRecognizer];
        }
        
        if (result) {
            otherGestureRecognizer.state = UIGestureRecognizerStateBegan;
            [otherGestureRecognizer addTarget:self action:@selector(otherGestureRecognizerStateChanged:)];
            [self.innerScrollViews addObject:(id)otherGestureRecognizer.view];
        }
        return result;
    }
    
    return YES;
}

- (void)otherGestureRecognizerStateChanged:(UIPanGestureRecognizer *)otherGestureRecognizer {
    if (otherGestureRecognizer.state == UIGestureRecognizerStateEnded ||
        otherGestureRecognizer.state == UIGestureRecognizerStateCancelled ||
        otherGestureRecognizer.state == UIGestureRecognizerStateFailed) {
        [self.innerScrollViews removeObject:(id)otherGestureRecognizer.view];
        [otherGestureRecognizer removeTarget:self action:_cmd];
    }
}

@end
