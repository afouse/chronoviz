//
//  GeographicTimeSeriesData.h
//  Annotation
//
//  Created by Adam Fouse on 8/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeSeriesData.h"

@interface GeographicTimeSeriesData : TimeSeriesData {

	float maxLat;
	float maxLon;
	float minLat;
	float minLon;
	
	NSString *lonVariableName;
	
}

@property(retain) NSString* lonVariableName;

// Initialize with an array of values evenly distributed over a range
-(id)initWithLatitudes:(NSArray*)latitudes andLongitudes:(NSArray*)longitudes overRange:(CMTimeRange)range;

- (float) maxLat;
- (float) maxLon;
- (float) minLat;
- (float) minLon;

- (NSString*)latVariableName;

@end
