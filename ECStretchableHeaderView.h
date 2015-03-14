//
//  ECStretchableHeaderView.h
//  StretchableHeaderViewExample
//
//  Created by Eric Castro on 30/07/14.
//  Copyright (c) 2014 cast.ro. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ECStretchableHeaderViewDelegate;

@interface ECStretchableHeaderView : UIView<UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (assign) CGFloat maxHeight;
@property (assign) CGFloat minHeight;
@property (assign) CGFloat minOffset;
@property (assign) BOOL compensateBottomScrollingArea;
@property (assign) BOOL resizingEnabled;

@property (strong) NSLayoutConstraint *heightConstraint;

@property (assign) BOOL tapToExpand;

@property(nonatomic, strong) UIScrollView *attachedScrollView;

- (void)attachToScrollView:(UIScrollView *)scrollView inset:(CGFloat)inset;

- (void)attachToScrollView:(UIScrollView *)scrollView parentView:(UIView *)parentView inset:(CGFloat)inset;

@end

@protocol ECStretchableHeaderViewDelegate<NSObject>


@end