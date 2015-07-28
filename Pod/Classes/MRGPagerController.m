//
// Copyright (c) 2014, Mirego
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// - Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
// - Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// - Neither the name of the Mirego nor the names of its contributors may
//   be used to endorse or promote products derived from this software without
//   specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "MRGPagerController.h"

@interface MRGPagerController ()<UIScrollViewDelegate, MRGPagerStripDelegate>
@property (nonatomic) Class pagerStripClass;
@property (nonatomic) UIView<MRGPagerStrip> *pagerStrip;
@property (nonatomic) UIScrollView *pagerScrollView;
@property (nonatomic) BOOL isRotatingInterfaceOrientation;
@property (nonatomic) BOOL isLayouting;
@property (nonatomic) BOOL callDidEndScrollingOnNextViewDidLayoutSubviews;
@property (nonatomic, weak) UIViewController *lastViewControllerEndedScrollingOn;
@end

@implementation MRGPagerController

- (instancetype)init {
    self = [self initWithPagerStripClass:nil];
    if (self) {
    }
    
    return self;
}

- (instancetype)initWithPagerStripClass:(Class)pagerStripClass {
    self = [super init];
    if (self) {
        _pagerStripClass = pagerStripClass;
        _callDidEndScrollingOnNextViewDidLayoutSubviews = YES;
    }
    
    return self;
}

- (void)dealloc {
    _pagerStrip.delegate = nil;
    _pagerScrollView.delegate = nil;
    _delegate = nil;
}

#pragma mark - lifecyle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pagerStrip = (UIView<MRGPagerStrip> *)[[_pagerStripClass alloc] init];
    if (self.pagerStrip) {
        [self.view addSubview:self.pagerStrip];
        self.pagerStrip.delegate = self;
        self.pagerStrip.viewControllers = self.viewControllers;
        [self.view addSubview:self.pagerStrip];
    }
    
    self.pagerScrollView = [[UIScrollView alloc] init];
    self.pagerScrollView.scrollsToTop = NO;
    self.pagerScrollView.delegate = self;
    self.pagerScrollView.pagingEnabled = YES;
    self.pagerScrollView.showsHorizontalScrollIndicator = NO;
    self.pagerScrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:self.pagerScrollView];
    
    [self updateViewControllersWithOldViewControllers:nil newViewControllers:self.viewControllers animated:NO];
}

#pragma mark - layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    self.isLayouting = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self layoutPager];
    
    if (_currentViewController == nil) {
        _currentViewController = [self.viewControllers firstObject];
    }
    
    [self scrollToCurrentViewControllerAnimated:NO];
    [self hideViewControllersOutsideOfBounds];
    
    if (self.callDidEndScrollingOnNextViewDidLayoutSubviews) {
        self.callDidEndScrollingOnNextViewDidLayoutSubviews = NO;
        [self didEndScrolling];
    }
    
    self.isLayouting = NO;
}

- (void)layoutPager {
    CGSize size = CGSizeMake(CGRectGetWidth(self.view.bounds) - (self.padding.left + self.padding.right),
                             CGRectGetHeight(self.view.bounds) - (self.padding.top + self.padding.bottom));
    
    CGFloat pagerStripBottom;
    if (self.pagerStrip.superview == self.view) {
        self.pagerStrip.frame = CGRectMake(self.padding.left, self.padding.top, size.width, [self.pagerStrip sizeThatFits:size].height);
        [self.pagerStrip layoutIfNeeded];
        pagerStripBottom = CGRectGetMaxY(self.pagerStrip.frame);
    } else {
        pagerStripBottom = self.padding.top;
    }
    
    self.pagerScrollView.frame = CGRectMake(self.padding.left, pagerStripBottom, size.width, ((size.height + self.padding.top) - pagerStripBottom));
    [self.pagerScrollView layoutIfNeeded];
    
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.pagerScrollView.bounds), CGRectGetHeight(self.pagerScrollView.bounds));
    for (UIViewController *viewController in self.viewControllers) {
        viewController.view.frame = frame;
        frame.origin.x += frame.size.width;
    }
    
    self.pagerScrollView.contentSize = CGSizeMake(frame.origin.x, CGRectGetHeight(self.pagerScrollView.bounds));
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.isRotatingInterfaceOrientation = YES;
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if ((viewController != self.currentViewController)) {
            [viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:0];
        }
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.isRotatingInterfaceOrientation = NO;
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if ((viewController != self.currentViewController)) {
            [viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
        }
    }];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self scrollToCurrentViewControllerAnimated:NO];
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if ((viewController != self.currentViewController)) {
            [viewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:0];
        }
    }];
}

#ifdef __IPHONE_8_0
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];

    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if ((viewController != self.currentViewController)) {
            [viewController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        }
    }];
}
#endif

- (void)updateViewControllersWithOldViewControllers:(NSArray *)oldViewControllers newViewControllers:(NSArray *)newViewControllers animated:(BOOL)animated {
    if ([self isViewLoaded] == NO) {
        return;
    }
    
    NSMutableOrderedSet *removeViewControllers = [[NSMutableOrderedSet alloc] initWithArray:oldViewControllers];
    [removeViewControllers minusSet:[[NSSet alloc] initWithArray:newViewControllers]];
    for (UIViewController *viewController in removeViewControllers) {
        [viewController willMoveToParentViewController:nil];
        [viewController.view removeFromSuperview];
        [viewController removeFromParentViewController];
    }
    
    NSMutableOrderedSet *addViewControllers = [[NSMutableOrderedSet alloc] initWithArray:newViewControllers];
    [addViewControllers minusSet:[[NSSet alloc] initWithArray:oldViewControllers]];
    for (UIViewController *viewController in addViewControllers) {
        [self addChildViewController:viewController];
        
        UIView *viewControllerView = viewController.view;
        viewControllerView.autoresizingMask = UIViewAutoresizingNone;
        [viewController didMoveToParentViewController:self];
    }
    
    [self.view setNeedsLayout];
}

- (void)hideViewControllersOutsideOfBounds {
    for (UIViewController *viewController in self.viewControllers) {
        UIView *viewControllerView = viewController.view;
        if (!CGRectIntersectsRect(viewControllerView.frame, self.pagerScrollView.bounds)) {
            if ([viewControllerView superview] != nil) {
                [viewControllerView removeFromSuperview];
            }
        } else {
            if ([viewControllerView superview] == nil) {
                [self.pagerScrollView addSubview:viewControllerView];
            }
        }
    }
}

- (void)scrollToCurrentViewControllerAnimated:(BOOL)animated {
    NSUInteger index = [self.viewControllers indexOfObject:self.currentViewController];
    CGPoint contentOffset = CGPointMake(index != NSNotFound ? index * CGRectGetWidth(self.pagerScrollView.bounds) : 0, 0);
    [self.pagerScrollView setContentOffset:contentOffset animated:animated];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat index = (CGRectGetWidth(scrollView.bounds) > 0) ? (scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds)) : 0;
    [self.pagerStrip setCurrentIndex:index animated:NO];
    
    if (!self.isRotatingInterfaceOrientation && !self.isLayouting) {
        if (self.viewControllers.count > 0) {
            NSUInteger currentIndex = roundf(index);
            currentIndex = ((currentIndex > 0) ? (currentIndex < (self.viewControllers.count - 1)) ? currentIndex : (self.viewControllers.count - 1) : 0);
            _currentViewController = [self.viewControllers objectAtIndex:currentIndex];
        } else {
            _currentViewController = [self.viewControllers firstObject];
        }
        
        [self hideViewControllersOutsideOfBounds];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self didEndScrolling];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self didEndScrolling];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self didEndScrolling];
}

- (void)didEndScrolling {
    if (self.lastViewControllerEndedScrollingOn != self.currentViewController) {
        self.lastViewControllerEndedScrollingOn = self.currentViewController;
        [self.delegate pagerController:self didEndScrollingOnViewController:self.lastViewControllerEndedScrollingOn];
    }
}

#pragma mark - get/set

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    if (_viewControllers != viewControllers) {
        NSArray *oldViewControllers = self.viewControllers;
        _viewControllers = [viewControllers copy];
        
        [self.pagerStrip setViewControllers:self.viewControllers animated:animated];
        [self updateViewControllersWithOldViewControllers:oldViewControllers newViewControllers:self.viewControllers animated:animated];
        
        if ((self.pagerScrollView != nil)) {
            [self scrollViewDidScroll:self.pagerScrollView];
        }
    }
}

- (void)setViewControllers:(NSArray *)viewControllers {
    [self setViewControllers:viewControllers animated:NO];
}

- (void)setCurrentViewController:(UIViewController *)currentViewController animated:(BOOL)animated {
    if (_currentViewController != currentViewController) {
        _currentViewController = currentViewController ?: [self.viewControllers firstObject];
        
        if ([self isViewLoaded] && !self.callDidEndScrollingOnNextViewDidLayoutSubviews) {
            [self scrollToCurrentViewControllerAnimated:animated];
            
            if (!animated) {
                [self didEndScrolling];
            }
        }
    }
}

- (void)setCurrentViewController:(UIViewController *)currentViewController {
    [self setCurrentViewController:currentViewController animated:NO];
}

- (void)setPadding:(UIEdgeInsets)padding {
    _padding = padding;
    
    if ([self isViewLoaded]) {
        [self.view setNeedsLayout];
    }
}

#pragma mark - MRGPagerStripDelegate

- (void)pagerStripSizeChanged:(id<MRGPagerStrip>)pagerStrip {
    [self.view setNeedsLayout];
}

- (void)pagerStrip:(id<MRGPagerStrip>)pagerStrip didSelectViewController:(UIViewController *)viewController {
    [self setCurrentViewController:viewController animated:YES];
}

@end
