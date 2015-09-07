//
//  DPMaskedSelectionArea.h
//  ChronoViz
//
//  Created by Adam Fouse on 10/8/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DPMaskedSelectionArea : NSObject {
    CGRect area;
    NSString *guid;
    NSString *name;
    NSColor *color;
}

@property CGRect area;
@property(readonly) NSString* guid;
@property(copy) NSString* name;
@property(retain) NSColor* color;

@end
