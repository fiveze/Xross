//
//  MLWXrossViewController.h
//  Xross
//
//  Created by Anton Bukov on 24.11.15.
//  Copyright © 2015 MachineLearningWorks. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class MLWXrossViewController;
@class MLWXrossTransition;

typedef NS_ENUM(NSUInteger, MLWTransitionType) {
    MLWTransitionTypeDefault,
    MLWTransitionTypeCube,
    MLWTransitionTypeCubeTo,
    MLWTransitionTypeCubeFrom,
    MLWTransitionTypeStackPop,
    MLWTransitionTypeStackPush,
    MLWTransitionTypeStackPopWithSwing,
    MLWTransitionTypeStackPushWithSwing,
    MLWTransitionTypeStackPopFlat,
    MLWTransitionTypeStackPushFlat,
    MLWTransitionTypeFadeIn,
    MLWTransitionTypeFadeOut,
};

typedef struct {
    NSInteger x;
    NSInteger y;
} MLWXrossDirection;

typedef MLWXrossDirection MLWXrossPosition;

extern MLWXrossDirection MLWXrossDirectionNone;
extern MLWXrossDirection MLWXrossDirectionTop;
extern MLWXrossDirection MLWXrossDirectionBottom;
extern MLWXrossDirection MLWXrossDirectionLeft;
extern MLWXrossDirection MLWXrossDirectionRight;

MLWXrossDirection MLWXrossDirectionMake(CGFloat x, CGFloat y);
MLWXrossDirection MLWXrossDirectionFromOffset(CGPoint offset);
BOOL MLWXrossDirectionIsNone(MLWXrossDirection direction);
BOOL MLWXrossDirectionIsHorizontal(MLWXrossDirection direction);
BOOL MLWXrossDirectionIsVertical(MLWXrossDirection direction);
BOOL MLWXrossDirectionEquals(MLWXrossDirection direction, MLWXrossDirection direction2);

MLWXrossTransition *MLWXrossTransitionForTransitionType(MLWTransitionType transitionType, UIView *currentView, UIView *nextView, MLWXrossDirection direction);

// Data Source

@protocol MLWXrossViewControllerDataSource <NSObject>

- (nullable UIViewController *)xross:(MLWXrossViewController *)xross viewControllerForDirection:(MLWXrossDirection)direction;

@end

// Delegate

@protocol MLWXrossViewControllerDelegate <NSObject>

@optional
- (void)xross:(MLWXrossViewController *)xross didMoveToDirection:(MLWXrossDirection)direction;
- (BOOL)xross:(MLWXrossViewController *)xross shouldBounceToDirection:(MLWXrossDirection)direction;
- (void)xross:(MLWXrossViewController *)xross removedViewController:(UIViewController *)viewController;
- (void)xross:(MLWXrossViewController *)xross didScrollToDirection:(MLWXrossDirection)direction progress:(CGFloat)progress;
- (BOOL)xross:(MLWXrossViewController *)xross shouldApplyInsetToDirection:(MLWXrossDirection)direction progress:(CGFloat)progress;
- (nullable MLWXrossTransition *)xross:(MLWXrossViewController *)xross transitionToDirection:(MLWXrossDirection)direction;
- (MLWTransitionType)xross:(MLWXrossViewController *)xross transitionTypeToDirection:(MLWXrossDirection)direction;

@end

// Xross

@interface MLWXrossViewController<__covariant ChildViewControllerType : UIViewController *> : UIViewController

@property (nullable, weak, nonatomic) id<MLWXrossViewControllerDataSource> dataSource;
@property (nullable, weak, nonatomic) id<MLWXrossViewControllerDelegate> delegate;
@property (nullable, readonly, nonatomic) ChildViewControllerType viewController;
@property (nullable, readonly, nonatomic) ChildViewControllerType nextViewController;
@property (readonly, nonatomic) UIScrollView *scrollView;
@property (assign, nonatomic) BOOL bounces;
@property (assign, nonatomic, getter=isMovingDisabled) BOOL movingDisabled;
@property (readonly, nonatomic, getter=isMoving) BOOL moving;

+ (Class)xrossViewClass;
- (void)reloadData;
- (void)moveToDirection:(MLWXrossDirection)direction;
- (void)moveToDirection:(MLWXrossDirection)direction completion:(void (^_Nullable)(void))completion;
- (void)moveToDirection:(MLWXrossDirection)direction viewController:(nullable UIViewController *)viewController;
- (void)moveToDirection:(MLWXrossDirection)direction viewController:(nullable UIViewController *)viewController completion:(void (^_Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
