ECStretchableHeaderView
=======================

A multi-purpose header view that you can attach to a UITableView (or any UIScrollView), allowing you to maximize the scrolling content's screen real state by expanding and contracting the top header upon scrolling down or up, or by delegating the decision on when to do this through a another object.

Useful when such header isn't fully needed, but might have some buttons or some other interactive control that needs to remain visible.

![ECStretchableHeaderView](http://i.imgur.com/RCqO0O9.gif)

# Usage

```objc
	ECStretchableHeaderView *headerView;

    headerView = [[ECStretchableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(parentView.frame), maxHeight)];

	headerView.maxHeight = 320;
    headerView.minHeight = 100;

	NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:pageView
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:1.0
                                                    constant:headerView.maxHeight]];

    [headerView addConstraint:heightConstraint];

    headerView.heightConstraint = heightConstraint;

    [headerView attachToScrollView:self.tableView inset:100.0f];
```

Why do you need to set a height constraint?

Because **ECStretchableHeaderView** is made to be auto-layout friendly, in a way that you can design your header view on your Storyboard, and not let it get your interface builder get full of layout errors and warnings for missing constraints.

The example project contains a **ECStretchableHeaderView** that is not created programatically, but instead created in Interface Builder.

Also because if you aren't using auto layout, well, you should.

# License

This project is MIT licensed. Feel free to contribute :-)