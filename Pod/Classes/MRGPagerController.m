//
// Copyright (c) 2014-2021, Mirego
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
#import "GameController/GCKeyboard.h"

@interface MRGPagerController ()<UIScrollViewDelegate, MRGPagerStripDelegate>

@property (nonatomic, nullable) Class pagerStripClass;
@property (nonatomic) UIView<MRGPagerStrip> *pagerStrip;
@property (nonatomic) UIScrollView *pagerScrollView;
@property (nonatomic) BOOL isLayouting;
@property (nonatomic) BOOL callDidEndScrollingOnNextViewDidLayoutSubviews;
@property (nonatomic) CGSize lastSize;
@property (nonatomic, weak, nullable) UIViewController *lastViewControllerEndedScrollingOn;
@property (nonatomic) UISwipeGestureRecognizer *swipeLeft;
@property (nonatomic) UISwipeGestureRecognizer *swipeRight;
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
    [self removeKeyboardObserver];
}

#pragma mark - lifecyle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pagerStrip = (UIView<MRGPagerStrip> *)[[_pagerStripClass alloc] init];
    if (self.pagerStrip) {
        [self.view addSubview:self.pagerStrip];
        self.pagerStrip.delegate = self;
        self.pagerStrip.pageTitles = [self getPageTitles];
        [self.view addSubview:self.pagerStrip];
    }
    
    self.pagerScrollView = [[UIScrollView alloc] init];
    self.pagerScrollView.delegate = self;
    self.pagerScrollView.scrollsToTop = NO;
    self.pagerScrollView.pagingEnabled = YES;
    self.pagerScrollView.showsHorizontalScrollIndicator = NO;
    self.pagerScrollView.showsVerticalScrollIndicator = NO;
    
    // Need to support external keyboard for accessibility
    // and fix the conflict between keyboard arrow <-> and UIScrollView behavior
    // NOTE 1: Using [GCKeyboard coalescedKeyboard] to detect the keyboard doesn't work because it always returns nil
    // NOTE 2: Haven't found a proper solution to access app.isFullKeyboardAccessEnabled
    [self addKeyboardObserver];
    
    [self.view addSubview:self.pagerScrollView];
    
    [self updateViewControllersWithOldViewControllers:nil newViewControllers:self.viewControllers animated:NO];
}

#pragma mark - Support external keyboard for Accessibility

- (void)addKeyboardObserver {
    if (@available(iOS 14.0, *)) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hardwareKeyboardDidConnect:) name:GCKeyboardDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hardwareKeyboardDidDisonnect:) name:GCKeyboardDidDisconnectNotification object:nil];
    }
}

- (void)removeKeyboardObserver {
    if (@available(iOS 14.0, *)) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:GCKeyboardDidConnectNotification object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:GCKeyboardDidDisconnectNotification object:nil];
    }
}

- (void)hardwareKeyboardDidConnect:(NSNotification *)notification {
    
    // Fix the conflict between keyboard arrow <-> and UIScrollView behavior
    self.pagerScrollView.scrollEnabled = NO;
    
    // Only when an external keyboard is connected
    // The default (Drag gesture) of UIScrollView is disabled
    // and needs to be replaced with a swipe gesture
    [self addGestureRecogniser];
}

- (void)hardwareKeyboardDidDisonnect:(NSNotification *)notification {
    self.pagerScrollView.scrollEnabled = YES;
    [self removeGestureRecogniser];
}

- (void)addGestureRecogniser {
    self.swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
    [self.swipeLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.pagerScrollView addGestureRecognizer:self.swipeLeft];
    
    self.swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    [self.swipeRight setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.pagerScrollView addGestureRecognizer:self.swipeRight];
}

- (void)removeGestureRecogniser {
    [self.pagerScrollView removeGestureRecognizer:self.swipeLeft];
    [self.pagerScrollView removeGestureRecognizer:self.swipeRight];
}

- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)recognizer {
    [self moveToPageIndex: MIN(self.pagerStrip.currentIndex +1, self.viewControllers.count -1)];
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)recognizer
{
    [self moveToPageIndex: MAX(self.pagerStrip.currentIndex -1, 0)];
}

- (void)moveToPageIndex:(NSUInteger)index {
    if (index != self.pagerStrip.currentIndex) {
        [self.pagerStrip setCurrentIndex:index animated:YES];
        [self setCurrentViewController:self.viewControllers[index] animated:YES];
    }
}

#pragma mark - layout

- (void)viewWillLayoutSubviews {
    self.isLayouting = YES;
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (!CGSizeEqualToSize(self.lastSize, self.view.bounds.size)) {
        [self layoutViewControllers];
    }
    
    self.isLayouting = NO;
}

- (void)layoutViewControllers {
    self.lastSize = self.view.bounds.size;
    
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

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-implementations"

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if ((viewController != self.currentViewController)) {
            [viewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:0];
        }
    }];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if ((viewController != self.currentViewController)) {
            [viewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
        }
    }];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if ((viewController != self.currentViewController)) {
            [viewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:0];
        }
    }];
}

#pragma GCC diagnostic pop

#ifdef __IPHONE_8_0

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    BOOL sizeChanged = !CGSizeEqualToSize(self.view.bounds.size, size);
    if (sizeChanged) {
        
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
        
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
            
        } completion:NULL];
    }
    
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        if ((viewController != self.currentViewController)) {
            [viewController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
        }
    }];
}

#endif

- (void)updateViewControllersWithOldViewControllers:(NSArray<UIViewController *> *)oldViewControllers newViewControllers:(NSArray<UIViewController *> *)newViewControllers animated:(BOOL)animated {
    if ([self isViewLoaded] == NO) {
        return;
    }
    
    NSMutableOrderedSet<UIViewController *> *removeViewControllers = [[NSMutableOrderedSet alloc] initWithArray:oldViewControllers];
    [removeViewControllers minusSet:[[NSSet alloc] initWithArray:newViewControllers]];
    for (UIViewController *viewController in removeViewControllers) {
        [viewController willMoveToParentViewController:nil];
        if ([viewController.view superview] != nil) {
            [viewController beginAppearanceTransition:NO animated:NO];
            [viewController.view removeFromSuperview];
            [viewController endAppearanceTransition];
        }
        [viewController removeFromParentViewController];
    }
    
    NSMutableOrderedSet<UIViewController *> *addViewControllers = [[NSMutableOrderedSet alloc] initWithArray:newViewControllers];
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
    CGRect frame = CGRectMake(0, 0, CGRectGetWidth(self.pagerScrollView.bounds), CGRectGetHeight(self.pagerScrollView.bounds));
    
    if (frame.size.width > 0 && frame.size.height > 0) {
        for (UIViewController *viewController in self.viewControllers) {
            UIView *viewControllerView = viewController.view;
            if (!CGRectIntersectsRect(frame, self.pagerScrollView.bounds)) {
                if ([viewControllerView superview] != nil) {
                    [viewController beginAppearanceTransition:NO animated:NO];
                    [viewControllerView removeFromSuperview];
                    [viewController endAppearanceTransition];
                }
                
            } else {
                if ([viewControllerView superview] == nil) {
                    [viewController beginAppearanceTransition:YES animated:NO];
                    [self.pagerScrollView addSubview:viewControllerView];
                    [viewController endAppearanceTransition];
                }
            }
            
            frame.origin.x += frame.size.width;
        }
        
    } else {
        for (UIViewController *viewController in self.viewControllers) {
            UIView *viewControllerView = viewController.view;
            if ([viewControllerView superview] != nil) {
                [viewController beginAppearanceTransition:NO animated:NO];
                [viewControllerView removeFromSuperview];
                [viewController endAppearanceTransition];
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
    
    if (!self.isLayouting) {
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

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    if (_viewControllers != viewControllers) {
        NSArray<UIViewController *> *oldViewControllers = self.viewControllers;
        _viewControllers = [viewControllers copy];
        
        [self.pagerStrip setPageTitles:[self getPageTitles] animated:animated];
        [self updateViewControllersWithOldViewControllers:oldViewControllers newViewControllers:self.viewControllers animated:animated];
        
        if ((self.pagerScrollView != nil)) {
            [self scrollViewDidScroll:self.pagerScrollView];
        }
        
        [self layoutViewControllers];
    }
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers {
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

- (NSArray<NSString *> *)getPageTitles {
    NSMutableArray<NSString *> *titles = [NSMutableArray arrayWithCapacity:self.viewControllers.count];
    for (UIViewController *viewController in self.viewControllers) {
        [titles addObject:viewController.title ?: @""];
    }
    return titles;
}

#pragma mark - MRGPagerStripDelegate

- (void)pagerStripSizeChanged:(id<MRGPagerStrip>)pagerStrip {
    [self.view setNeedsLayout];
}

- (void)pagerStrip:(id <MRGPagerStrip>)pagerStrip didSelectPageAtIndex:(NSUInteger)pageIndex {
    [self setCurrentViewController:self.viewControllers[pageIndex] animated:YES];
}

@end
