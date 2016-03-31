//
// Copyright (c) 2014-2015, Mirego
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

#import "MRGPagerTitleStrip.h"

@interface MRGPagerTitleStrip ()
@property (nonatomic, readonly) BOOL needsUpdateView;
@property (nonatomic, readonly) BOOL needsUpdateSeparators;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) NSMutableArray *buttons;
@property (nonatomic) NSMutableArray *separators;
@end

@implementation MRGPagerTitleStrip

@synthesize viewControllers = _viewControllers;
@synthesize currentIndex = _currentIndex;
@synthesize delegate = _delegate;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        
        _titleTextAlignment = NSTextAlignmentCenter;
        _titleFont = [UIFont systemFontOfSize:14];
        _titleTextColor = [UIColor colorWithWhite:1 alpha:0.5f];
        _titleHighlightedTextColor = [UIColor whiteColor];
        _titleTextSpacing = 10;
        
        _centerTabs = NO;
        
        _drawSeparator = YES;
        _separatorSize = CGSizeMake(1.0f / [[UIScreen mainScreen] scale], 0.4f);
        _separatorColor = [UIColor colorWithWhite:1 alpha:0.2f];
        
        _scrollView = [[UIScrollView alloc] init];
#if !TARGET_OS_TV
        _scrollView.scrollsToTop = NO;
#endif
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        [self addSubview:_scrollView];
        
        _buttons = [[NSMutableArray alloc] init];
        _separators = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    _scrollView.delegate = nil;
    _delegate = nil;
}

- (void)setNeedsUpdateView {
    _needsUpdateView = YES;
    [self setNeedsLayout];
}

- (void)updateViewIfNeeded {
    if (_needsUpdateView) {
        _needsUpdateView = NO;
        [self updateView];
    }
}

- (void)updateView {
    for (UIButton *button in self.buttons) {
        [button.titleLabel setFont:self.titleFont];
        [button.titleLabel setTextAlignment:self.titleTextAlignment];
        [button setTitleColor:self.titleTextColor forState:UIControlStateNormal];
        [button setTitleColor:self.titleTextColor forState:UIControlStateNormal|UIControlStateHighlighted];
        [button setTitleColor:self.titleHighlightedTextColor forState:UIControlStateSelected];
        [button setTitleColor:self.titleHighlightedTextColor forState:UIControlStateSelected|UIControlStateHighlighted];
        [button setContentEdgeInsets:UIEdgeInsetsMake(self.padding.top, self.titleTextSpacing, self.padding.bottom, self.titleTextSpacing)];
    }
    
    if ([self needsUpdateSeparators] || ((self.buttons.count > 0) && ((self.buttons.count-1) != self.separators.count))) {
        [self updateSeparators];
    }
    
    for (UIView *separator in self.separators) {
        [separator setBackgroundColor:self.separatorColor];
    }
}

- (void)updateSeparators {
    _needsUpdateSeparators = NO;
    
    [self.separators makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.separators removeAllObjects];
    
    if (self.buttons.count > 0) {
        for (NSUInteger index = 0, count = (self.buttons.count - 1); index < count; ++index) {
            UIView *separator = [[UIView alloc] init];
            [self.scrollView insertSubview:separator atIndex:0];
            [self.separators addObject:separator];
        }
    }
}

- (void)layoutSubviews {
    [self updateViewIfNeeded];
    [super layoutSubviews];
    
    CGSize size = self.bounds.size;
    CGSize separatorSize = (self.drawSeparator ? CGSizeMake(self.separatorSize.width, self.separatorSize.height * size.height) : CGSizeZero);

    NSMutableArray *buttonsWidths = [[NSMutableArray alloc] initWithCapacity:self.buttons.count];
    __block CGFloat buttonsWidth = 0;
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        CGFloat width = ((self.titleForcedWidth > 0) ? self.titleForcedWidth : [button sizeThatFits:CGSizeZero].width) + self.titleTextSpacing * 2;
        if (idx > 0) {
            width += separatorSize.width;
        }
        if ((idx+1) < self.buttons.count) {
            width += separatorSize.width;
        }
        
        [buttonsWidths addObject:@(width)];
        buttonsWidth += width;
    }];
    buttonsWidth += (separatorSize.width * self.separators.count);
    
    __block CGFloat buttonLeft = (self.centerTabs ? ((buttonsWidth < CGRectGetWidth(self.bounds)) ? roundf((CGRectGetWidth(self.bounds) - buttonsWidth) * 0.5f) : 0.0f) : 0.0f);
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
        CGFloat buttonWidth = [buttonsWidths[idx] floatValue];
        button.frame = CGRectMake(buttonLeft, 0, buttonWidth, size.height);
        buttonLeft += buttonWidth - separatorSize.width;
    }];
    
    if ((self.separators.count > 0) && (self.separators.count == (self.buttons.count-1))) {
        CGFloat separatorMiddle = (size.height - self.padding.top - self.padding.bottom);
        [self.separators enumerateObjectsUsingBlock:^(UIView *separator, NSUInteger idx, BOOL *stop) {
            CGFloat separatorLeft = CGRectGetMaxX([[self.buttons objectAtIndex:idx] frame]) - separatorSize.width;
            separator.frame = CGRectMake(separatorLeft, self.padding.top + roundf((separatorMiddle - separatorSize.height) * 0.5f), separatorSize.width, separatorSize.height);
        }];
    }
    
    self.scrollView.frame = self.bounds;
    self.scrollView.contentSize = CGSizeMake(((buttonLeft > 0.0f) ? (buttonLeft + separatorSize.width) : 0.0f), size.height);
    
    [self.scrollView layoutIfNeeded];
    [self scrollToIndex:self.currentIndex animated:NO];
    
    [self.delegate pagerStripSizeChanged:self];
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(size.width, self.padding.top + roundf(self.titleFont.lineHeight) + self.padding.bottom);
}

- (void)updateButtonsAnimated:(BOOL)animated {
    [self.buttons makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.buttons removeAllObjects];
    
    for (UIViewController *viewController in self.viewControllers) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:viewController.title forState:UIControlStateNormal];
        [self.scrollView addSubview:button];
        [self.buttons addObject:button];
    }
    
    [self updateView];
    [self scrollToIndex:self.currentIndex animated:animated];
}

- (void)scrollToIndex:(CGFloat)index animated:(BOOL)animated {
    [self updateButtonIndex:index];
    
    if ([self.buttons count] > 0 && (self.scrollView.contentSize.width > CGRectGetWidth(self.scrollView.bounds))) {
        CGFloat offset = 0;
        NSInteger prevButtonIndex = MAX(floorf(index), 0);
        NSInteger nextButtonIndex = MIN(ceilf(index), [self.buttons count] - 1);
        
        for (NSInteger ii = 0, count = MIN(prevButtonIndex, [self.buttons count]); ii < count; ++ii) {
            offset += CGRectGetWidth([self.buttons[ii] bounds]);
            offset += self.separatorSize.width;
        }
        
        if ((prevButtonIndex >= 0) && (prevButtonIndex != nextButtonIndex) && (nextButtonIndex < [self.buttons count])) {
            offset += CGRectGetWidth([self.buttons[(nextButtonIndex-1)] bounds]) * (index - prevButtonIndex);
        }
        
        // Center button
        CGFloat width;
        if (prevButtonIndex != nextButtonIndex) {
            width =
            CGRectGetWidth([self.buttons[nextButtonIndex] bounds]) * (index - prevButtonIndex) +
            CGRectGetWidth([self.buttons[prevButtonIndex] bounds]) * (nextButtonIndex - index);
        } else {
            width = CGRectGetWidth([self.buttons[prevButtonIndex] bounds]);
        }
        offset -= ((CGRectGetWidth(self.scrollView.bounds) - width) * 0.5f);
        
        offset = MIN(MAX(offset, 0), self.scrollView.contentSize.width - CGRectGetWidth(self.scrollView.bounds));
        [self.scrollView setContentOffset:CGPointMake(offset, self.scrollView.contentOffset.y) animated:NO];
        
    } else {
        [self.scrollView setContentOffset:CGPointMake(0, self.scrollView.contentOffset.y) animated:NO];
    }
}

- (void)updateButtonIndex:(CGFloat)index {
    NSUInteger currentIndex = roundf(index);
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger buttonIndex, BOOL *stop) {
        [button setSelected:(buttonIndex == currentIndex)];
    }];
}

#pragma mark - get/set

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    if (_viewControllers != viewControllers) {
        _viewControllers = [viewControllers copy];
        
        [self updateButtonsAnimated:animated];
        [self setNeedsUpdateView];
    }
}

- (void)setViewControllers:(NSArray *)viewControllers {
    [self setViewControllers:viewControllers animated:NO];
}

- (void)setCurrentIndex:(CGFloat)currentIndex animated:(BOOL)animated {
    if (!(fabs(_currentIndex - currentIndex) < FLT_EPSILON)) {
        _currentIndex = currentIndex;
        
        [self scrollToIndex:self.currentIndex animated:YES];
    }
}

- (void)setCurrentViewControllerIndex:(CGFloat)index {
    [self setCurrentIndex:index animated:NO];
}

- (void)setTitleTextAlignment:(NSTextAlignment)titleTextAlignment {
    if (_titleTextAlignment != titleTextAlignment) {
        _titleTextAlignment = titleTextAlignment;
        [self setNeedsUpdateView];
    }
}

- (void)setTitleFont:(UIFont *)titleFont {
    if (_titleFont != titleFont) {
        _titleFont = titleFont;
        [self setNeedsUpdateView];
    }
}

- (void)setTitleTextColor:(UIColor *)titleTextColor {
    if (_titleTextColor != titleTextColor) {
        _titleTextColor = titleTextColor;
        [self setNeedsUpdateView];
    }
}

- (void)setTitleHighlightedTextColor:(UIColor *)titleHighlightedTextColor {
    if (_titleHighlightedTextColor != titleHighlightedTextColor) {
        _titleHighlightedTextColor = titleHighlightedTextColor;
        [self setNeedsUpdateView];
    }
}

- (void)setTitleTextSpacing:(CGFloat)titleTextSpacing {
    if (_titleTextSpacing != titleTextSpacing) {
        _titleTextSpacing = titleTextSpacing;
        [self setNeedsUpdateView];
    }
}

- (void)setCenterTabs:(BOOL)centerTabs {
    if (_centerTabs != centerTabs) {
        _centerTabs = centerTabs;
        [self setNeedsUpdateView];
    }
}

- (void)setPadding:(UIEdgeInsets)padding {
    if (UIEdgeInsetsEqualToEdgeInsets(_padding, padding) == NO) {
        _padding = padding;
        [self setNeedsUpdateView];
    }
}

- (void)setTitleForcedWidth:(CGFloat)titleForcedWidth {
    if (!(fabs(_titleForcedWidth - titleForcedWidth) < FLT_EPSILON)) {
        _titleForcedWidth = titleForcedWidth;
        [self setNeedsUpdateView];
    }
}

- (void)setDrawSeparator:(BOOL)drawSeparator {
    if (_drawSeparator != drawSeparator) {
        _drawSeparator = drawSeparator;
        _needsUpdateSeparators = YES;
        [self setNeedsUpdateView];
    }
}

- (void)setSeparatorSize:(CGSize)separatorSize {
    if (CGSizeEqualToSize(_separatorSize, separatorSize) == NO) {
        _separatorSize = separatorSize;
        [self setNeedsUpdateView];
    }
}

- (void)setSeparatorColor:(UIColor *)separatorColor {
    if (_separatorColor != separatorColor) {
        _separatorColor = separatorColor;
        [self setNeedsUpdateView];
    }
}

@end
