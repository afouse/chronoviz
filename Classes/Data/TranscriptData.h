//
//  TranscriptData.h
//  DataPrism
//
//  Created by Adam Fouse on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeSeriesData.h"

@interface TranscriptData : TimeCodedData {

	NSMutableArray *strings;
	float frameRate;
}

@property float frameRate;

- (id) initWithTimeCodedStrings:(NSArray*)theStrings;

- (NSArray*)timeCodedStrings;

@end
