//
//  ECStretchableHeaderView.h
//  StretchableHeaderViewExample
//
//  Created by Eric Castro on 30/07/14.
//  Copyright (c) 2014 cast.ro. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ECStretchableHeaderViewDelegate;

@interface ECStretchableHeaderView : UIView<UIGestureRecognizerDelegate>

@property (assign) CGFloat maxHeight;
@property (assign) CGFloat minHeight;

@property (assign) BOOL tapToExpand;

- (void)attachToScrollView:(UIScrollView *)scrollView inset:(CGFloat)inset;

@end

@protocol ECStretchableHeaderViewDelegate<NSObject>



@end