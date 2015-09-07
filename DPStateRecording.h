//
//  DPStateRecording.h
//  ChronoViz
//
//  Created by Adam Fouse on 1/3/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol DPStateRecording

- (NSData*)currentState:(NSDictionary*)stateFlags;
- (BOOL)setState:(NSData*)stateData;

@optional

- (NSDictionary*)currentStateDictionary:(NSDictionary*)stateFlags;
- (BOOL)setStateDictionary:(NSDictionary*)stateDictionary;

@end
