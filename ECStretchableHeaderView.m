//
//  ECStretchableHeaderView.m
//  StretchableHeaderViewExample
//
//  Created by Eric Castro on 30/07/14.
//  Copyright (c) 2014 cast.ro. All rights reserved.
//
#import <POP.h>

#import "ECStretchableHeaderView.h"

@implementation ECStretchableHeaderView
{
    UIPanGestureRecognizer *_panGestureRecognizer;
    UITapGestureRecognizer *_tapGestureRecognizer;

    CGPoint _lastPanLocation;

    BOOL _touchesStartedOnSelf;

    UIScrollView *_attachedScrollView;
    CGFloat _inset;
}
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
        [self addGestureRecognizer:_panGestureRecognizer];
        _panGestureRecognizer.delegate = self;

        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
        [self addGestureRecognizer:_tapGestureRecognizer];
        _tapGestureRecognizer.delegate = self;

        _minHeight = 0.0;
        _maxHeight = CGRectGetHeight(frame);
        _touchesStartedOnSelf = NO;
        _tapToExpand = NO;
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return NO;
}
- (void)didTap:(id)sender
{
    NSLog(@"hi mom!");
    CGPoint newOffset =_attachedScrollView.contentOffset;
    newOffset.y -= self.maxHeight - CGRectGetHeight(self.frame);
    [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionCurveEaseOut animations:^{
        [_attachedScrollView setContentOffset:newOffset animated:YES];
    } completion:nil];
}
- (void)didPan:(id)sender
{
    CGPoint currentLocation = [_panGestureRecognizer locationInView:self];

    if (_panGestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        _lastPanLocation = currentLocation;
        [_attachedScrollView setContentOffset:_attachedScrollView.contentOffset animated:NO];

    }


    if (_panGestureRecognizer.state == UIGestureRecognizerStateChanged)
    {
        CGFloat heightDiff = currentLocation.y - _lastPanLocation.y;

        if (_attachedScrollView.contentOffset.y <= -_attachedScrollView.contentInset.top)
        {
            heightDiff = heightDiff/3;
        }
        _attachedScrollView.contentOffset = CGPointMake(_attachedScrollView.contentOffset.x, _attachedScrollView.contentOffset.y - heightDiff);
    }

    if (
            _panGestureRecognizer.state == UIGestureRecognizerStateEnded ||
            _panGestureRecognizer.state == UIGestureRecognizerStateCancelled||
            _panGestureRecognizer.state == UIGestureRecognizerStateFailed)
    {
        if (_attachedScrollView.contentOffset.y <= -_attachedScrollView.contentInset.top)
        {
            _touchesStartedOnSelf = YES;
            [self _performBounceBackAnimation];
        }
        else
        {
            _touchesStartedOnSelf = YES;
            CGPoint velocity = [_panGestureRecognizer velocityInView:self];

            if (_attachedScrollView.bounds.size.width >= _attachedScrollView.contentSize.width) velocity.x = 0;
            if (_attachedScrollView.bounds.size.height >= _attachedScrollView.contentSize.height) velocity.y = 0;

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
            CGFloat boundsCheck = values[1] + CGRectGetHeight(self.frame) + _inset;
            CGFloat velocityThreshold = ((NSValue *)decayAnimation.velocity).CGPointValue.y / 10.0f * 0.2f;
            if (boundsCheck < velocityThreshold)
            {
                [_attachedScrollView pop_removeAllAnimations];
                _touchesStartedOnSelf = YES;
                tempBounds.origin.y = - CGRectGetHeight(self.frame) - _inset + boundsCheck;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self _performBounceBackAnimation];
                });
            }
            else
                tempBounds.origin.y = values[1];

            [obj setBounds:tempBounds];
        };
        // dynamics threshold
        prop.threshold = 0.01;
    }];

    decayAnimation.property = prop;
    decayAnimation.velocity = [NSValue valueWithCGPoint:velocity];
    decayAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) { if (completionBlock) completionBlock(); };
    [_attachedScrollView pop_addAnimation:decayAnimation forKey:@"decelerate"];
}
- (void)_performBounceBackAnimation
{
    NSLog(@"bouncing back now");

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
    basicAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(_attachedScrollView.contentOffset.x, - CGRectGetHeight(self.frame) - _inset)];
    basicAnimation.duration = 0.3f;
    basicAnimation.completionBlock = ^(POPAnimation *anim, BOOL finished) {
        _touchesStartedOnSelf = NO;
    };
    [_attachedScrollView pop_addAnimation:basicAnimation forKey:@"bounceBack"];
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

    self.frame = frame;
    
    return YES;
}

- (void)attachToScrollView:(UIScrollView *)scrollView inset:(CGFloat)inset
{
    _inset = inset;
    _attachedScrollView = scrollView;
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld context:NULL];

    CGRect frame = self.frame;
    frame.origin.x = scrollView.frame.origin.x;
    frame.origin.y = scrollView.frame.origin.y + inset;
    frame.size.width = CGRectGetWidth(scrollView.frame);
    self.frame = frame;


    [scrollView.superview addSubview:self];
    UIEdgeInsets contentInset = scrollView.contentInset;
    contentInset.top = CGRectGetHeight(self.frame);
    scrollView.contentInset = contentInset;
    scrollView.scrollIndicatorInsets = contentInset;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    UIScrollView *scrollView = object;

    NSValue *value = [change valueForKey:@"old"];
    CGFloat oldYOffset = value.CGPointValue.y;
    CGFloat newYOffset = scrollView.contentOffset.y;
    CGFloat offsetDiff = oldYOffset-newYOffset;

    CGRect frame = self.frame;
    frame.origin.y = newYOffset + _inset;
    //self.frame = frame;

    if (_touchesStartedOnSelf)
    {
        [_attachedScrollView pop_removeAllAnimations];
        return;
    }

    if(scrollView.contentOffset.y <= -scrollView.contentInset.top)
    {
        [self changeHeightBy:self.maxHeight - CGRectGetHeight(frame)];
    }
    else
    {
        [self changeHeightBy:offsetDiff];
    }
    if( scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.size.height + scrollView.contentInset.bottom )
    {
        NSLog( @"bounce right" );
    }
}
@end
