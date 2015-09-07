//
//  DPTabViewBar.h
//  ChronoViz
//
//  Created by Adam Fouse on 12/9/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DPTabViewBar : NSView <NSTabViewDelegate> {
    NSTabView *tabView;
    
    NSMutableArray *buttons;
}

@property(retain) IBOutlet NSTabView *tabView;

@end
