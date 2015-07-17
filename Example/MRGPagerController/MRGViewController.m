//
// Copyright (c) 2015, Mirego
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

#import "MRGViewController.h"
#import "MRGPagerController.h"
#import "MRGPagerTabStrip.h"
#import "MRGDemoController.h"
#import "MRGDemoTabStrip.h"

@interface MRGViewController ()
@property (nonatomic) MRGPagerController *pagerController;
@end

@implementation MRGViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.pagerController = [[MRGPagerController alloc] initWithPagerStripClass:[MRGDemoTabStrip class]];
    
    [self addChildViewController:self.pagerController];
    [self.view addSubview:self.pagerController.view];
    self.pagerController.view.frame = self.view.bounds;
    self.pagerController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.pagerController didMoveToParentViewController:self];
    
    [self configurePager];
}

- (void)configurePager {

    NSArray *tabs = @[
            [[MRGDemoController alloc] initWithTitle:@"1" text:@"1"],
            [[MRGDemoController alloc] initWithTitle:@"2" text:@"2"],
            [[MRGDemoController alloc] initWithTitle:@"3" text:@"3"],
            [[MRGDemoController alloc] initWithTitle:@"4" text:@"4"],
            [[MRGDemoController alloc] initWithTitle:@"5" text:@"5"],
            [[MRGDemoController alloc] initWithTitle:@"6" text:@"6"],
            [[MRGDemoController alloc] initWithTitle:@"7" text:@"7"],
            [[MRGDemoController alloc] initWithTitle:@"8" text:@"8"],
            [[MRGDemoController alloc] initWithTitle:@"9" text:@"9"]
    ];

    self.pagerController.viewControllers = tabs;
    self.pagerController.currentViewController = tabs[7];
}

@end
