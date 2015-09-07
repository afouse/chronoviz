//
//  ActivityFramesConfigurationController.h
//  ChronoViz
//
//  Created by Adam Fouse on 10/26/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ActivityFramesVisualizer.h"

@interface ActivityFramesConfigurationController : NSWindowController {
    ActivityFramesVisualizer *visualizer;
    
}

- (id)initForVisualizer:(ActivityFramesVisualizer*)vis;

- (IBAction)changeVisMethodAction:(id)sender;

@end
