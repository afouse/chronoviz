//
//  TimeCodedSpatialPoint.h
//  ChronoViz
//
//  Created by Adam Fouse on 6/16/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeCodedDataPoint.h"

@interface TimeCodedSpatialPoint : TimeCodedDataPoint {

	CGFloat x;
	CGFloat y;
	
}

@property CGFloat x;
@property CGFloat y;

@end
