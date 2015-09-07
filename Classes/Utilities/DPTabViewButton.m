//
//  DPTabViewButton.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/12/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPTabViewButton.h"
#import "DPTabViewButtonCell.h"

@implementation DPTabViewButton

+ (Class)cellClass
{
    return [DPTabViewButtonCell class];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBezelStyle:NSRoundRectBezelStyle];
        [(NSButtonCell*)[self cell] setBackgroundStyle:NSBackgroundStyleRaised];
        //[[self cell] setHighlightsBy:NSPushInCellMask];
        //[self setBordered:NO];
    }
    return self;
}


@end
