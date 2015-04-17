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
@property (nonatomic, weak) MRGPagerController *pager;
@end

@implementation MRGViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    MRGPagerController *pagerController = [[MRGPagerController alloc] initWithPagerStripClass:[MRGDemoTabStrip class]];
    [self.view addSubview:pagerController.view];
    [self addChildViewController:pagerController];
    [self configurePager:pagerController];

    self.pager = pagerController;
}

- (void)configurePager:(MRGPagerController *)controller {

    NSArray *tabs = @[
            [[MRGDemoController alloc] initWithTitle:@"Controller 1" text:@"label 1"],
            [[MRGDemoController alloc] initWithTitle:@"Controller 2" text:@"label 2"],
            [[MRGDemoController alloc] initWithTitle:@"Controller 3" text:@"label 3"],
            [[MRGDemoController alloc] initWithTitle:@"Controller 4" text:@"label 4"],
            [[MRGDemoController alloc] initWithTitle:@"Controller 5" text:@"label 5"],
            [[MRGDemoController alloc] initWithTitle:@"Controller 6" text:@"label 6"],
            [[MRGDemoController alloc] initWithTitle:@"Controller 7" text:@"label 7"],
            [[MRGDemoController alloc] initWithTitle:@"Controller 8" text:@"label 8"],
            [[MRGDemoController alloc] initWithTitle:@"Controller 9" text:@"label 9"]
    ];

    controller.viewControllers = tabs;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.pager.view.frame = self.view.frame;
}

@end
