//
//  ECStretchableHeaderView.m
//  StretchableHeaderViewExample
//
//  Created by Eric Castro on 30/07/14.
//  Copyright (c) 2014 cast.ro. All rights reserved.
//
#import <pop/POP.h>
#import <HTDelegateProxy/HTDelegateProxy.h>

#import "ECStretchableHeaderView.h"

@implementation ECStretchableHeaderView
{
    UIPanGestureRecognizer *_panGestureRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;

    CGPoint _lastPanLocation;

    BOOL _touchesStartedOnSelf;

    CGFloat _inset;

    HTDelegateProxy *_delegateProxy;
    id _originalScrollViewDelegate;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _setupView];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _setupView];
    }
    return self;
}

- (void)_setupView
{
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self addGestureRecognizer:_panGestureRecognizer];
    _panGestureRecognizer.delegate = self;

    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [self addGestureRecognizer:_tapGestureRecognizer];
    _tapGestureRecognizer.delegate = self;

    self.clipsToBounds = YES;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    _minHeight = 0.0;
    _maxHeight = CGRectGetHeight(self.frame);
    _touchesStartedOnSelf = NO;
    _tapToExpand = NO;
    _compensateBottomScrollingArea = NO;
    _resizingEnabled = YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}

- (void)didTap:(id)sender
{
    CGPoint newOffset = self.attachedScrollView.contentOffset;
    newOffset.y -= self.maxHeight - CGRectGetHeight(self.frame);
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [self.attachedScrollView setContentOffset:newOffset animated:YES];
    } completion:nil];
}
- (void)didPan:(id)sender
{
    CGPoint currentLocation = [_panGestureRecognizer locationInView:self];

    if (_panGestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        _lastPanLocation = currentLocation;
        [self.attachedScrollView pop_removeAllAnimations];
        [self.attachedScrollView setContentOffset:self.attachedScrollView.contentOffset animated:NO];
    }

    if (_panGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        CGFloat heightDiff = currentLocation.y - _lastPanLocation.y;

        if (self.attachedScrollView.contentOffset.y <= -self.attachedScrollView.contentInset.top)
        {
            heightDiff = heightDiff/3;
        }
        self.attachedScrollView.contentOffset = CGPointMake(self.attachedScrollView.contentOffset.x, self.attachedScrollView.contentOffset.y - heightDiff);
    }

    if (
            _panGestureRecognizer.state == UIGestureRecognizerStateEnded ||
            _panGestureRecognizer.state == UIGestureRecognizerStateCancelled||
            _panGestureRecognizer.state == UIGestureRecognizerStateFailed)
    {
        if (self.attachedScrollView.contentOffset.y <= -self.attachedScrollView.contentInset.top)
        {
            _touchesStartedOnSelf = YES;
            [self _performBounceBackToTopAnimation];
        }
        else
        {
            _touchesStartedOnSelf = YES;
            CGPoint velocity = [_panGestureRecognizer velocityInView:self];

            if (self.attachedScrollView.bounds.size.width >= self.attachedScrollView.contentSize.width) velocity.x = 0;
            //if (self.attachedScrollView.bounds.size.height >= self.attachedScrollView.contentSize.height) velocity.y = 0;

            velocity.x = -velocity.x;
            velocity.y = -velocity.y;

            [self _performDecelerateAnimationWithVelocity:velocity completionBlock:^{
                _touchesStartedOnSelf = NO;
            }];
        }
    }

    _lastPanLocation = currentLocation;
}

- (void)_performDecelerateAnimationWithVelocity:(CGPoint)velocity completionBlock:(void (^)())completionBlock
{
    POPDecayAnimation *decayAnimation = [POPDecayAnimation animation];

    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"com.rounak.boundsY" initializer:^(POPMutableAnimatableProperty *prop) {
        // read value, feed data to Pop
        prop.readBlock = ^(id obj, CGFloat values[]) {
            values[0] = [obj bounds].origin.x;
            values[1] = [obj bounds].origin.y;
        };
        // write value, get data from Pop, and apply it to the view
        prop.writeBlock = ^(id obj, const CGFloat values[]) {

            CGRect tempBounds = [obj bounds];
            tempBounds.origin.x = values[0];
            CGFloat topBoundCheck = values[1] + CGRectGetHeight(self.frame) + _inset;
            CGFloat velocityThreshold = ((NSValue *)decayAnimation.velocity).CGPointValue.y / 10.0f * 0.2f;

            if (velocityThreshold < 0 && topBoundCheck < velocityThreshold && values[1] < self.maxHeight)
            {
                [self.attachedScrollView pop_removeAllAnimations];
                _touchesStartedOnSelf = YES;
                tempBounds.origin.y = - CGRectGetHeight(self.frame) - _inset + topBoundCheck;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self _performBounceBackToTopAnimation];
                });
            }
            else if (tempBounds.origin.y > _attachedScrollView.contentSize.height - _attachedScrollView.frame.size.height + _attachedScrollView.contentInset.bottom + velocityThreshold)
            {
                [self.attachedScrollView pop_removeAllAnimations];
                _touchesStartedOnSelf = YES;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self _performBounceBackToBottomAnimation];
                });
            }
            else
                tempBounds.origin.y = values[1];

            [self _scrollView:_attachedScrollView offsetChanged:@{@"new":[NSValue valueWithCGSize:CGSizeMake(0.0f, values[1])], @"old":[NSValue valueWithCGSize:CGSizeMake(0.0f, values[1])]}];
            [obj setBounds:tempBounds];
        };
        // dynamics threshold
        prop.threshold = 0.01;

    }];

    decayAnimation.property = prop;
    decayAnimation.velocity = [NSValue valueWithCGPoint:velocity];
    decayAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) { if (completionBlock) completionBlock(); };
    [self.attachedScrollView pop_addAnimation:decayAnimation forKey:@"decelerate"];
}
- (POPBasicAnimation *)_bounceBackAnimation
{
    POPBasicAnimation *basicAnimation = [POPBasicAnimation animation];
    POPAnimatableProperty *prop = [POPAnimatableProperty propertyWithName:@"com.rounak.boundsY" initializer:^(POPMutableAnimatableProperty *prop) {
        prop.readBlock = ^(id obj, CGFloat values[]) {
            values[0] = [obj bounds].origin.x;
            values[1] = [obj bounds].origin.y;
        };
        prop.writeBlock = ^(id obj, const CGFloat values[]) {
            CGRect tempBounds = [obj bounds];
            tempBounds.origin.x = values[0];
            tempBounds.origin.y = values[1];
            [obj setBounds:tempBounds];
        };
        // dynamics threshold
        prop.threshold = 0.01;
    }];
    basicAnimation.property = prop;
    basicAnimation.duration = 0.3f;
    basicAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        _touchesStartedOnSelf = NO;
    };
    return basicAnimation;

}
- (void)_performBounceBackToTopAnimation
{
    POPBasicAnimation *basicAnimation = [self _bounceBackAnimation];
    basicAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.attachedScrollView.contentOffset.x, - CGRectGetHeight(self.frame) - _inset)];
    [self.attachedScrollView pop_addAnimation:basicAnimation forKey:@"bounceBack"];
}

- (void)_performBounceBackToBottomAnimation
{
    POPBasicAnimation *basicAnimation = [self _bounceBackAnimation];

    if (self.attachedScrollView.contentSize.height < self.attachedScrollView.frame.size.height) //fixes weird jump bug
    {
        basicAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.attachedScrollView.contentOffset.x, 0.0f)];
    }
    else
    {
        basicAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.attachedScrollView.contentOffset.x,self.attachedScrollView.contentSize.height - self.attachedScrollView.bounds.size.height)];
    }

    [self.attachedScrollView pop_addAnimation:basicAnimation forKey:@"bounceBack"];
}
- (BOOL)changeHeightBy:(CGFloat)heightDiff
{
    CGRect frame = self.frame;

    if (frame.size.height + heightDiff > self.maxHeight)
        frame.size.height = self.maxHeight;

    else if (frame.size.height + heightDiff < self.minHeight)
        frame.size.height = self.minHeight;

    else
        frame.size.height += heightDiff;

    if (self.heightConstraint)
    {
        self.heightConstraint.constant = frame.size.height;
    }
    else
    {
        self.frame = frame;
    }

    
    return YES;
}

- (void)attachToScrollView:(UIScrollView *)scrollView inset:(CGFloat)inset
{
    [self attachToScrollView:scrollView parentView:scrollView.superview inset:inset];
}
- (void)attachToScrollView:(UIScrollView *)scrollView parentView:(UIView *)parentView inset:(CGFloat)inset
{
    _inset = inset;

    CGRect frame = self.frame;
    frame.origin.x = parentView.frame.origin.x;
    frame.origin.y = parentView.frame.origin.y + inset;
    frame.size.width = CGRectGetWidth(parentView.frame);
    self.frame = frame;

    [parentView addSubview:self];

    self.attachedScrollView = scrollView;

}

- (void)setAttachedScrollView:(UIScrollView *)attachedScrollView
{
    if (_attachedScrollView)
    {
        _attachedScrollView.delegate = _originalScrollViewDelegate==[NSNull null] ? nil : _originalScrollViewDelegate;
        [_attachedScrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
    _attachedScrollView = attachedScrollView;
    _originalScrollViewDelegate = _attachedScrollView.delegate ? _attachedScrollView.delegate : [NSNull null];
    _delegateProxy = [[HTDelegateProxy alloc] initWithDelegates:@[_originalScrollViewDelegate, self]];

    _attachedScrollView.delegate = (id<UIScrollViewDelegate>)_delegateProxy;

    UIEdgeInsets contentInset = attachedScrollView.contentInset;
    contentInset.top = self.maxHeight;
    attachedScrollView.contentInset = contentInset;
    attachedScrollView.scrollIndicatorInsets = contentInset;
    attachedScrollView.contentOffset = CGPointMake(attachedScrollView.contentOffset.x, -CGRectGetHeight(self.frame));
    [attachedScrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    [attachedScrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:NULL];
    [self _scrollView:attachedScrollView sizeChanged:@{@"new":[NSValue valueWithCGSize:attachedScrollView.contentSize]}];

    _minOffset = 0.0f;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    UIScrollView *scrollView = object;

    if ([keyPath isEqualToString:@"contentOffset"])
    {
        [self _scrollView:scrollView offsetChanged:change];
    }

    if ([keyPath isEqualToString:@"contentSize"])
    {
        [self _scrollView:scrollView sizeChanged:change];
    }
}

- (void)_scrollView:(UIScrollView *)scrollView offsetChanged:(NSDictionary *)change
{
    if (!self.resizingEnabled) return;

    NSValue *oldValue = [change valueForKey:@"old"];
    NSValue *newValue = [change valueForKey:@"new"];

    CGFloat oldYOffset = oldValue.CGPointValue.y;
    CGFloat newYOffset = newValue.CGPointValue.y;
    CGFloat offsetDiff = oldYOffset-newYOffset;

    CGRect frame = self.frame;
    frame.origin.y = newYOffset + _inset;
    //self.frame = frame;

    if (newYOffset > scrollView.contentSize.height - scrollView.frame.size.height + scrollView.contentInset.bottom)
    {
        //bouncing at the bottom; do nothing
    }

    CGFloat relativePosition = newYOffset + self.maxHeight - self.minOffset;
    CGFloat heightCheck = self.maxHeight - relativePosition;

    if (relativePosition >= 0.0f)
    {
        if (heightCheck < self.minHeight)
            self.heightConstraint.constant = self.minHeight;
        else
            self.heightConstraint.constant = self.maxHeight - relativePosition;
    }
    else
        self.heightConstraint.constant = self.maxHeight;


}

- (void)_scrollView:(UIScrollView *)scrollView sizeChanged:(NSDictionary *)change
{
    if (!self.resizingEnabled) return;

    NSValue *newValue = [change valueForKey:@"new"];

    UIEdgeInsets contentInset = scrollView.contentInset;

    if (scrollView.contentSize.height < scrollView.frame.size.height)
    {
        contentInset.bottom = (scrollView.frame.size.height - newValue.CGSizeValue.height) ;
    }
    else
    {
        contentInset.bottom = (_compensateBottomScrollingArea ? self.maxHeight : 0.0f);
    }

    scrollView.contentInset = contentInset;

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.attachedScrollView pop_removeAllAnimations];
}
- (void)dealloc
{
    [self.attachedScrollView removeObserver:self forKeyPath:@"contentSize"];
    [self.attachedScrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end
