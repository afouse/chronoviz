//
//  MultiTimelineWindowController.h
//  ChronoViz
//
//  Created by Adam Fouse on 9/9/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AnnotationViewController.h"
@class MultiTimelineView;

@interface MultiTimelineWindowController : NSWindowController <NSWindowDelegate, AnnotationViewController> {
    
    MultiTimelineView *multiTimelineView;
    
    NSUInteger numTimelines;
    
}
@property (assign) IBOutlet MultiTimelineView *multiTimelineView;

@end
