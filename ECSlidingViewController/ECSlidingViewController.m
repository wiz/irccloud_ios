//
//  ECSlidingViewController.m
//  ECSlidingViewController
//
//  Created by Michael Enriquez on 1/23/12.
//  Copyright (c) 2012 EdgeCase. All rights reserved.
//

#import "ECSlidingViewController.h"

NSString *const ECSlidingViewUnderRightWillAppear    = @"ECSlidingViewUnderRightWillAppear";
NSString *const ECSlidingViewUnderLeftWillAppear     = @"ECSlidingViewUnderLeftWillAppear";
NSString *const ECSlidingViewUnderLeftWillDisappear  = @"ECSlidingViewUnderLeftWillDisappear";
NSString *const ECSlidingViewUnderRightWillDisappear = @"ECSlidingViewUnderRightWillDisappear";
NSString *const ECSlidingViewTopDidAnchorLeft        = @"ECSlidingViewTopDidAnchorLeft";
NSString *const ECSlidingViewTopDidAnchorRight       = @"ECSlidingViewTopDidAnchorRight";
NSString *const ECSlidingViewTopWillReset            = @"ECSlidingViewTopWillReset";
NSString *const ECSlidingViewTopDidReset             = @"ECSlidingViewTopDidReset";

@interface ECSlidingViewController()

@property (nonatomic, strong) UIView *topViewSnapshot;
@property (nonatomic, assign) CGFloat initialTouchPositionX;
@property (nonatomic, assign) CGFloat initialHoizontalCenter;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *resetTapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *topViewSnapshotPanGesture;
@property (nonatomic, assign) BOOL underLeftShowing;
@property (nonatomic, assign) BOOL underRightShowing;
@property (nonatomic, assign) BOOL topViewIsOffScreen;

- (NSUInteger)autoResizeToFillScreen;
- (UIView *)topView;
- (UIView *)underLeftView;
- (UIView *)underRightView;
- (void)adjustLayout;
- (void)updateTopViewHorizontalCenterWithRecognizer:(UIPanGestureRecognizer *)recognizer;
- (void)updateTopViewHorizontalCenter:(CGFloat)newHorizontalCenter;
- (void)topViewHorizontalCenterWillChange:(CGFloat)newHorizontalCenter;
- (void)topViewHorizontalCenterDidChange:(CGFloat)newHorizontalCenter;
- (void)addTopViewSnapshot;
- (void)removeTopViewSnapshot;
- (CGFloat)anchorRightTopViewCenter;
- (CGFloat)anchorLeftTopViewCenter;
- (CGFloat)resettedCenter;
- (void)underLeftWillAppear;
- (void)underRightWillAppear;
- (void)topDidReset;
- (BOOL)topViewHasFocus;
- (void)updateUnderLeftLayout;
- (void)updateUnderRightLayout;

@end

@implementation UIViewController(SlidingViewExtension)

- (ECSlidingViewController *)slidingViewController
{
  UIViewController *viewController = self.parentViewController;
  while (!(viewController == nil || [viewController isKindOfClass:[ECSlidingViewController class]])) {
    viewController = viewController.parentViewController;
  }
  
  return (ECSlidingViewController *)viewController;
}

@end

@implementation ECSlidingViewController

// public properties
@synthesize underLeftViewController  = _underLeftViewController;
@synthesize underRightViewController = _underRightViewController;
@synthesize topViewController        = _topViewController;
@synthesize anchorLeftPeekAmount;
@synthesize anchorRightPeekAmount;
@synthesize anchorLeftRevealAmount;
@synthesize anchorRightRevealAmount;
@synthesize underRightWidthLayout = _underRightWidthLayout;
@synthesize underLeftWidthLayout  = _underLeftWidthLayout;
@synthesize shouldAllowPanningPastAnchor;
@synthesize shouldAllowUserInteractionsWhenAnchored;
@synthesize shouldAddPanGestureRecognizerToTopViewSnapshot;
@synthesize resetStrategy = _resetStrategy;

// category properties
@synthesize topViewSnapshot;
@synthesize initialTouchPositionX;
@synthesize initialHoizontalCenter;
@synthesize panGesture = _panGesture;
@synthesize resetTapGesture;
@synthesize underLeftShowing   = _underLeftShowing;
@synthesize underRightShowing  = _underRightShowing;
@synthesize topViewIsOffScreen = _topViewIsOffScreen;
@synthesize topViewSnapshotPanGesture = _topViewSnapshotPanGesture;

- (void)setTopViewController:(UIViewController *)theTopViewController
{
  CGRect topViewFrame = _topViewController ? _topViewController.view.frame : self.view.bounds;
  
  [self removeTopViewSnapshot];
  [_topViewController.view removeFromSuperview];
  [_topViewController willMoveToParentViewController:nil];
  [_topViewController removeFromParentViewController];
  
  _topViewController = theTopViewController;
  
  [self addChildViewController:self.topViewController];
  [self.topViewController didMoveToParentViewController:self];
  
  [_topViewController.view setAutoresizingMask:self.autoResizeToFillScreen];
  [_topViewController.view setFrame:topViewFrame];
  _topViewController.view.layer.shadowOffset = CGSizeZero;
  _topViewController.view.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;
  
  [self.view addSubview:_topViewController.view];
}

- (void)setUnderLeftViewController:(UIViewController *)theUnderLeftViewController
{
  [_underLeftViewController.view removeFromSuperview];
  [_underLeftViewController willMoveToParentViewController:nil];
  [_underLeftViewController removeFromParentViewController];
  
  _underLeftViewController = theUnderLeftViewController;
  
  if (_underLeftViewController) {
    [self addChildViewController:self.underLeftViewController];
    [self.underLeftViewController didMoveToParentViewController:self];
    
    _underLeftViewController.view.hidden = YES;
    [self.view insertSubview:_underLeftViewController.view belowSubview:self.topView];
    [self updateUnderLeftLayout];
  }
}

- (void)setUnderRightViewController:(UIViewController *)theUnderRightViewController
{
  [_underRightViewController.view removeFromSuperview];
  [_underRightViewController willMoveToParentViewController:nil];
  [_underRightViewController removeFromParentViewController];
  
  _underRightViewController = theUnderRightViewController;
  
  if (_underRightViewController) {
    [self addChildViewController:self.underRightViewController];
    [self.underRightViewController didMoveToParentViewController:self];
    
    _underRightViewController.view.hidden = YES;
    [self.view insertSubview:_underRightViewController.view belowSubview:self.topView];
    [self updateUnderRightLayout];
  }
}

- (void)setUnderLeftWidthLayout:(ECViewWidthLayout)underLeftWidthLayout
{
  if (underLeftWidthLayout == ECVariableRevealWidth && self.anchorRightPeekAmount <= 0) {
    [NSException raise:@"Invalid Width Layout" format:@"anchorRightPeekAmount must be set"];
  } else if (underLeftWidthLayout == ECFixedRevealWidth && self.anchorRightRevealAmount <= 0) {
    [NSException raise:@"Invalid Width Layout" format:@"anchorRightRevealAmount must be set"];
  }
  
  _underLeftWidthLayout = underLeftWidthLayout;
}

- (void)setUnderRightWidthLayout:(ECViewWidthLayout)underRightWidthLayout
{
  if (underRightWidthLayout == ECVariableRevealWidth && self.anchorLeftPeekAmount <= 0) {
    [NSException raise:@"Invalid Width Layout" format:@"anchorLeftPeekAmount must be set"];
  } else if (underRightWidthLayout == ECFixedRevealWidth && self.anchorLeftRevealAmount <= 0) {
    [NSException raise:@"Invalid Width Layout" format:@"anchorLeftRevealAmount must be set"];
  }
  
  _underRightWidthLayout = underRightWidthLayout;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.shouldAllowPanningPastAnchor = YES;
  self.shouldAllowUserInteractionsWhenAnchored = NO;
  self.shouldAddPanGestureRecognizerToTopViewSnapshot = NO;
  self.resetTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resetTopView)];
  _panGesture          = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateTopViewHorizontalCenterWithRecognizer:)];
  _panGesture.delegate = self;
  self.resetTapGesture.enabled = NO;
  self.resetStrategy = ECTapping | ECPanning;
  
  self.topViewSnapshot = [[UIView alloc] initWithFrame:self.topView.bounds];
  [self.topViewSnapshot setAutoresizingMask:self.autoResizeToFillScreen];
  [self.topViewSnapshot addGestureRecognizer:self.resetTapGesture];
}

-(NSUInteger)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return [self.topViewController shouldAutorotateToInterfaceOrientation:orientation];
}

- (BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)recognizer {
    CGPoint velocity = [recognizer velocityInView:self.view];
    return ABS(velocity.x) > ABS(velocity.y);
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.topView.layer.shadowOffset = CGSizeZero;
  self.topView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;
  [self adjustLayout];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  self.topView.layer.shadowPath = nil;
  self.topView.layer.shouldRasterize = YES;
  
  if(![self topViewHasFocus]){
    [self removeTopViewSnapshot];
  }
  
  [self adjustLayout];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
  self.topView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.view.layer.bounds].CGPath;
  self.topView.layer.shouldRasterize = NO;
  
  if(![self topViewHasFocus]){
    [self addTopViewSnapshot];
  }
}

- (void)setResetStrategy:(ECResetStrategy)theResetStrategy
{
  _resetStrategy = theResetStrategy;
  if (_resetStrategy & ECTapping) {
    self.resetTapGesture.enabled = YES;
  } else {
    self.resetTapGesture.enabled = NO;
  }
}

- (void)adjustLayout
{
  self.topViewSnapshot.frame = self.topView.bounds;
  
  if ([self underRightShowing] && ![self topViewIsOffScreen]) {
    [self updateUnderRightLayout];
    [self updateTopViewHorizontalCenter:self.anchorLeftTopViewCenter];
  } else if ([self underRightShowing] && [self topViewIsOffScreen]) {
    [self updateUnderRightLayout];
    [self updateTopViewHorizontalCenter:-self.resettedCenter];
  } else if ([self underLeftShowing] && ![self topViewIsOffScreen]) {
    [self updateUnderLeftLayout];
    [self updateTopViewHorizontalCenter:self.anchorRightTopViewCenter];
  } else if ([self underLeftShowing] && [self topViewIsOffScreen]) {
    [self updateUnderLeftLayout];
    [self updateTopViewHorizontalCenter:self.view.bounds.size.width + self.resettedCenter];
  }
}

- (void)updateTopViewHorizontalCenterWithRecognizer:(UIPanGestureRecognizer *)recognizer
{
    static BOOL underLeftWasShowing = NO;
    static BOOL underRightWasShowing = NO;
  CGPoint currentTouchPoint     = [recognizer locationInView:self.view];
  CGFloat currentTouchPositionX = currentTouchPoint.x;
  
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    self.initialTouchPositionX = currentTouchPositionX;
    self.initialHoizontalCenter = self.topView.center.x;
  } else if (recognizer.state == UIGestureRecognizerStateChanged) {
    CGFloat panAmount = self.initialTouchPositionX - currentTouchPositionX;
    CGFloat newCenterPosition = self.initialHoizontalCenter - panAmount;
    
    if ((newCenterPosition < self.resettedCenter && (self.anchorLeftTopViewCenter == NSNotFound || self.underRightViewController == nil)) ||
        (newCenterPosition > self.resettedCenter && (self.anchorRightTopViewCenter == NSNotFound || self.underLeftViewController == nil))) {
      newCenterPosition = self.resettedCenter;
    }
    
      if((newCenterPosition > self.resettedCenter && underRightWasShowing) || (newCenterPosition < self.resettedCenter && underLeftWasShowing)) {
          newCenterPosition = self.resettedCenter;
      }
          
      
    BOOL newCenterPositionIsOutsideAnchor = newCenterPosition < self.anchorLeftTopViewCenter || self.anchorRightTopViewCenter < newCenterPosition;
    
    if ((newCenterPositionIsOutsideAnchor && self.shouldAllowPanningPastAnchor) || !newCenterPositionIsOutsideAnchor) {
      [self topViewHorizontalCenterWillChange:newCenterPosition];
      [self updateTopViewHorizontalCenter:newCenterPosition];
      [self topViewHorizontalCenterDidChange:newCenterPosition];
        if(self.underLeftShowing)
            underLeftWasShowing = self.underLeftShowing;
        
        if(self.underRightShowing)
            underRightWasShowing = self.underRightShowing;
    }
  } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
      underLeftWasShowing = NO;
      underRightWasShowing = NO;
    CGFloat panAmount            = currentTouchPositionX - self.initialTouchPositionX;
    CGPoint currentVelocityPoint = [recognizer velocityInView:self.view];
    CGFloat currentVelocityX     = currentVelocityPoint.x;
        
    if ([self underLeftShowing] && (currentVelocityX > 50 || (currentVelocityX >= 0 && panAmount >= anchorRightRevealAmount/6.0f))) {
      [self anchorTopViewTo:ECRight];
    } else if ([self underRightShowing] && (currentVelocityX < -50 || (currentVelocityX <= 0 && panAmount <= -anchorLeftRevealAmount/6.0))) {
      [self anchorTopViewTo:ECLeft];
    } else {
      [self resetTopView];
    }
  }
}

- (UIPanGestureRecognizer *)panGesture
{
  return _panGesture;
}

- (void)anchorTopViewTo:(ECSide)side
{
  [self anchorTopViewTo:side animations:nil onComplete:nil];
}

- (void)anchorTopViewTo:(ECSide)side animations:(void (^)())animations onComplete:(void (^)())complete
{
  CGFloat newCenter = self.topView.center.x;
  
  if (side == ECLeft) {
    newCenter = self.anchorLeftTopViewCenter;
  } else if (side == ECRight) {
    newCenter = self.anchorRightTopViewCenter;
  }
  
  [self topViewHorizontalCenterWillChange:newCenter];
  
  [UIView animateWithDuration:0.15f animations:^{
    if (animations) {
      animations();
    }
    [self updateTopViewHorizontalCenter:newCenter];
  } completion:^(BOOL finished){
    if (_resetStrategy & ECPanning) {
      self.panGesture.enabled = YES;
    } else {
      self.panGesture.enabled = NO;
    }
    if (complete) {
      complete();
    }
    _topViewIsOffScreen = NO;
    [self addTopViewSnapshot];
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString *key = (side == ECLeft) ? ECSlidingViewTopDidAnchorLeft : ECSlidingViewTopDidAnchorRight;
      [[NSNotificationCenter defaultCenter] postNotificationName:key object:self userInfo:nil];
      (side == ECRight) ? [_underLeftViewController viewDidAppear:NO] : [_underRightViewController viewDidAppear:NO];
    });
  }];
}

- (void)anchorTopViewOffScreenTo:(ECSide)side
{
  [self anchorTopViewOffScreenTo:side animations:nil onComplete:nil];
}

- (void)anchorTopViewOffScreenTo:(ECSide)side animations:(void(^)())animations onComplete:(void(^)())complete
{
  CGFloat newCenter = self.topView.center.x;
  
  if (side == ECLeft) {
    newCenter = -self.resettedCenter;
  } else if (side == ECRight) {
    newCenter = self.view.bounds.size.width + self.resettedCenter;
  }
  
  [self topViewHorizontalCenterWillChange:newCenter];
  
  [UIView animateWithDuration:0.15f animations:^{
    if (animations) {
      animations();
    }
    [self updateTopViewHorizontalCenter:newCenter];
  } completion:^(BOOL finished){
    if (complete) {
      complete();
    }
    _topViewIsOffScreen = YES;
    [self addTopViewSnapshot];
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString *key = (side == ECLeft) ? ECSlidingViewTopDidAnchorLeft : ECSlidingViewTopDidAnchorRight;
      [[NSNotificationCenter defaultCenter] postNotificationName:key object:self userInfo:nil];
    });
  }];
}

- (void)resetTopView
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewTopWillReset object:self userInfo:nil];
  });
  [self resetTopViewWithAnimations:nil onComplete:nil];
}

- (void)resetTopViewWithAnimations:(void(^)())animations onComplete:(void(^)())complete
{
  [self topViewHorizontalCenterWillChange:self.resettedCenter];
  
  [UIView animateWithDuration:0.15f animations:^{
    if (animations) {
      animations();
    }
    [self updateTopViewHorizontalCenter:self.resettedCenter];
  } completion:^(BOOL finished) {
    if (complete) {
      complete();
    }
    [self topViewHorizontalCenterDidChange:self.resettedCenter];
  }];
}

- (NSUInteger)autoResizeToFillScreen
{
  return (UIViewAutoresizingFlexibleWidth |
          UIViewAutoresizingFlexibleHeight);
}

- (UIView *)topView
{
  return self.topViewController.view;
}

- (UIView *)underLeftView
{
  return self.underLeftViewController.view;
}

- (UIView *)underRightView
{
  return self.underRightViewController.view;
}

- (void)updateTopViewHorizontalCenter:(CGFloat)newHorizontalCenter
{
  CGPoint center = self.topView.center;
  center.x = newHorizontalCenter;
  self.topView.layer.position = center;
}

- (void)topViewHorizontalCenterWillChange:(CGFloat)newHorizontalCenter
{
  CGPoint center = self.topView.center;
  
	if (center.x >= self.resettedCenter && newHorizontalCenter == self.resettedCenter) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewUnderLeftWillDisappear object:self userInfo:nil];
		});
	}
	
	if (center.x <= self.resettedCenter && newHorizontalCenter == self.resettedCenter) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewUnderRightWillDisappear object:self userInfo:nil];
		});
	}
	
  if (center.x <= self.resettedCenter && newHorizontalCenter > self.resettedCenter) {
    [self underLeftWillAppear];
  } else if (center.x >= self.resettedCenter && newHorizontalCenter < self.resettedCenter) {
    [self underRightWillAppear];
  }  
}

- (void)topViewHorizontalCenterDidChange:(CGFloat)newHorizontalCenter
{
  if (newHorizontalCenter == self.resettedCenter) {
    [self topDidReset];
  }
}

- (void)addTopViewSnapshot
{
  if (!self.topViewSnapshot.superview && !self.shouldAllowUserInteractionsWhenAnchored) {
    topViewSnapshot.layer.contents = (id)[UIImage imageWithUIView:self.topView].CGImage;
    
    if (self.shouldAddPanGestureRecognizerToTopViewSnapshot && (_resetStrategy & ECPanning)) {
      if (!_topViewSnapshotPanGesture) {
        _topViewSnapshotPanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(updateTopViewHorizontalCenterWithRecognizer:)];
      }
      [topViewSnapshot addGestureRecognizer:_topViewSnapshotPanGesture];
    }
    self.topViewSnapshot.frame = self.topView.bounds;
    [self.topView addSubview:self.topViewSnapshot];
  }
}

- (void)removeTopViewSnapshot
{
  if (self.topViewSnapshot.superview) {
    [self.topViewSnapshot removeFromSuperview];
  }
}

- (CGFloat)anchorRightTopViewCenter
{
  if (self.anchorRightPeekAmount) {
    return self.view.bounds.size.width + self.resettedCenter - self.anchorRightPeekAmount;
  } else if (self.anchorRightRevealAmount) {
    return self.resettedCenter + self.anchorRightRevealAmount;
  } else {
    return NSNotFound;
  }
}

- (CGFloat)anchorLeftTopViewCenter
{
  if (self.anchorLeftPeekAmount) {
    return -self.resettedCenter + self.anchorLeftPeekAmount;
  } else if (self.anchorLeftRevealAmount) {
    return -self.resettedCenter + (self.view.bounds.size.width - self.anchorLeftRevealAmount);
  } else {
    return NSNotFound;
  }
}

- (CGFloat)resettedCenter
{
  return (self.view.bounds.size.width / 2);
}

- (void)underLeftWillAppear
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewUnderLeftWillAppear object:self userInfo:nil];
  });
  [self updateUnderLeftLayout];
  self.underRightView.hidden = YES;
  self.underLeftView.hidden = NO;
  _underLeftShowing  = YES;
  _underRightShowing = NO;
}

- (void)underRightWillAppear
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewUnderRightWillAppear object:self userInfo:nil];
  });
  [self updateUnderRightLayout];
  self.underRightView.hidden = NO;
  self.underLeftView.hidden = YES;
  _underLeftShowing  = NO;
  _underRightShowing = YES;
}

- (void)topDidReset
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:ECSlidingViewTopDidReset object:self userInfo:nil];
  });
  [self.topView removeGestureRecognizer:self.resetTapGesture];
  [self removeTopViewSnapshot];
  self.panGesture.enabled = YES;
  self.underRightView.hidden = YES;
  self.underLeftView.hidden = YES;
  _underLeftShowing   = NO;
  _underRightShowing  = NO;
  _topViewIsOffScreen = NO;
}

- (BOOL)topViewHasFocus
{
  return !_underLeftShowing && !_underRightShowing && !_topViewIsOffScreen;
}

- (void)updateUnderLeftLayout
{
    if (self.underLeftWidthLayout == ECFullWidth) {
        [self.underLeftView setAutoresizingMask:self.autoResizeToFillScreen];
        [self.underLeftView setFrame:self.view.bounds];
    } else if (self.underLeftWidthLayout == ECVariableRevealWidth && !self.topViewIsOffScreen) {
        CGRect frame = self.view.bounds;

        frame.size.width = frame.size.width - self.anchorRightPeekAmount;
        self.underLeftView.frame = frame;
    } else if (self.underLeftWidthLayout == ECFixedRevealWidth) {
        CGRect frame = self.view.bounds;

        frame.size.width = self.anchorRightRevealAmount;
        self.underLeftView.frame = frame;
    } else {
        [NSException raise:@"Invalid Width Layout" format:@"underLeftWidthLayout must be a valid ECViewWidthLayout"];
    }
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        int sbheight = [UIApplication sharedApplication].statusBarFrame.size.height;
        int sbwidth = [UIApplication sharedApplication].statusBarFrame.size.width;
        if(sbheight > 20)
            sbheight -= 20;
        if(sbwidth > 20)
            sbwidth -= 20;
        CGRect frame = self.underLeftView.frame;
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) || [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
            frame.origin.y = sbheight;
            frame.size.height = self.view.bounds.size.height - sbheight;
        } else {
            frame.origin.y = sbwidth;
            frame.size.height = self.view.bounds.size.height - sbwidth;
        }
        self.underLeftView.frame = frame;
    }
}

- (void)updateUnderRightLayout
{
    if (self.underRightWidthLayout == ECFullWidth) {
        [self.underRightViewController.view setAutoresizingMask:self.autoResizeToFillScreen];
        self.underRightView.frame = self.view.bounds;
    } else if (self.underRightWidthLayout == ECVariableRevealWidth) {
        CGRect frame = self.view.bounds;

        CGFloat newLeftEdge;
        CGFloat newWidth = frame.size.width;

        if (self.topViewIsOffScreen) {
          newLeftEdge = 0;
        } else {
          newLeftEdge = self.anchorLeftPeekAmount;
          newWidth   -= self.anchorLeftPeekAmount;
        }

        frame.origin.x   = newLeftEdge;
        frame.size.width = newWidth;

        self.underRightView.frame = frame;
    } else if (self.underRightWidthLayout == ECFixedRevealWidth) {
        CGRect frame = self.view.bounds;

        CGFloat newLeftEdge = frame.size.width - self.anchorLeftRevealAmount;
        CGFloat newWidth = self.anchorLeftRevealAmount;

        frame.origin.x   = newLeftEdge;
        frame.size.width = newWidth;

        self.underRightView.frame = frame;
    } else {
        [NSException raise:@"Invalid Width Layout" format:@"underRightWidthLayout must be a valid ECViewWidthLayout"];
    }
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        int sbheight = [UIApplication sharedApplication].statusBarFrame.size.height;
        int sbwidth = [UIApplication sharedApplication].statusBarFrame.size.width;
        if(sbheight > 20)
            sbheight -= 20;
        if(sbwidth > 20)
            sbwidth -= 20;
        CGRect frame = self.underRightView.frame;
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) || [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
            frame.origin.y = sbheight;
            frame.size.height = self.view.bounds.size.height - sbheight;
        } else {
            frame.origin.y = sbwidth;
            frame.size.height = self.view.bounds.size.height - sbwidth;
        }
        self.underRightView.frame = frame;
    }
}

@end
