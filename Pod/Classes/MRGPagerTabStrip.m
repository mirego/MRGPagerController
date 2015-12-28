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

#import "MRGPagerTabStrip.h"

@interface MRGPagerTabStrip () <UIScrollViewDelegate>
@property (nonatomic) UIView *tabIndicatorView;
@end

@implementation MRGPagerTabStrip

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSParameterAssert(self.scrollView.delegate == nil);
        self.scrollView.delegate = self;
        
        _drawFullUnderline = YES;
        _tabIndicatorColor = [UIColor whiteColor];
    }
    return self;
}

- (void)updateView {
    [super updateView];
    
    if (self.drawFullUnderline) {
        if (self.tabIndicatorView == nil) {
            self.tabIndicatorView = [[UIView alloc] init];
            [self.scrollView addSubview:self.tabIndicatorView];
        }
        
        self.tabIndicatorView.backgroundColor = self.tabIndicatorColor;
        
    } else {
        if ([self tabIndicatorView]) {
            [self.tabIndicatorView removeFromSuperview];
        }
    }
}

- (void)updateTabIndicatorAnimated:(BOOL)animated {
    if (self.tabIndicatorView == nil) {
        return;
    }
    
    if (self.buttons.count == 0) {
        self.tabIndicatorView.frame = CGRectMake(0, CGRectGetHeight(self.bounds) - 2, 0, 2);
        return;
    }
    
    CGFloat separatorWidth = (self.drawSeparator ? self.separatorSize.width : 0.0f);
    NSUInteger currentIndex = ((self.currentIndex > 0) ? ((self.currentIndex < (self.buttons.count-1)) ? floorf(self.currentIndex) : (self.buttons.count-1)) : 0);
    CGFloat left = CGRectGetMinX([[self.buttons objectAtIndex:currentIndex] frame]);
    CGFloat width = CGRectGetWidth([[self.buttons objectAtIndex:currentIndex] bounds]);
    
    if (currentIndex > 0) {
        width -= separatorWidth;
    }
    
    CGFloat nextWidth = 0;
    if ((currentIndex+1) < self.buttons.count) {
        width -= separatorWidth;
        nextWidth = CGRectGetWidth([[self.buttons objectAtIndex:(currentIndex+1)] bounds]);
    }

    CGFloat progress = ((self.currentIndex > 0) ? ((self.currentIndex < (self.buttons.count-1)) ? (self.currentIndex - floorf(self.currentIndex)) : 0.0f) : 0.0f);
    left += (width * progress);
    
    width = CGRectGetWidth([[self.buttons objectAtIndex:currentIndex] bounds]);
    width = (width * (1.0f - progress)) + (nextWidth * progress);
    
    self.tabIndicatorView.frame = CGRectMake(left, CGRectGetHeight(self.bounds) - 2, width, 2);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self updateTabIndicatorAnimated:NO];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateTabIndicatorAnimated:NO];
}

#pragma mark - get/set

- (void)setPageTitles:(NSArray *)pageTitles animated:(BOOL)animated {
    [super setPageTitles:pageTitles animated:animated];
    
    [self.buttons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger index, BOOL *stop) {
        [button setTag:index];
        [button setBackgroundImage:[self backgroundImageWithColor:self.tabIndicatorColor] forState:UIControlStateNormal|UIControlStateHighlighted];
        [button setBackgroundImage:[button backgroundImageForState:UIControlStateNormal|UIControlStateHighlighted] forState:UIControlStateSelected|UIControlStateHighlighted];
        [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (UIImage *)backgroundImageWithColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), YES, 0.0f);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(currentContext, [color CGColor]);
    CGContextFillRect(currentContext, CGRectMake(0, 0, 1, 1));
    UIImage *backgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return backgroundImage;
}

- (void)buttonTapped:(UIButton *)button {
    NSUInteger index = button.tag;
    if (index < self.pageTitles.count) {
        [self.delegate pagerStrip:self didSelectPageAtIndex:index];
    }
}

- (void)setDrawFullUnderline:(BOOL)drawFullUnderline {
    if (_drawFullUnderline != drawFullUnderline) {
        _drawFullUnderline = drawFullUnderline;
        [self setNeedsUpdateView];
    }
}

- (void)setTabIndicatorColor:(UIColor *)tabIndicatorColor {
    if (_tabIndicatorColor != tabIndicatorColor) {
        _tabIndicatorColor = tabIndicatorColor;
        [self setNeedsUpdateView];
    }
}

- (void)setCurrentIndex:(CGFloat)currentIndex animated:(BOOL)animated {
    [super setCurrentIndex:currentIndex animated:animated];
    [self updateTabIndicatorAnimated:animated];
}

@end
