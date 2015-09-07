//
//  MultiTimelineWindowController.m
//  ChronoViz
//
//  Created by Adam Fouse on 9/9/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "MultiTimelineWindowController.h"
#import "MultiTimelineView.h"

@implementation MultiTimelineWindowController
@synthesize multiTimelineView;

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        numTimelines = 3;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    

}

- (id<AnnotationView>)annotationView
{
    return self.multiTimelineView;
}

- (void)windowDidResize:(NSNotification *)notification
{
    
}


@end
