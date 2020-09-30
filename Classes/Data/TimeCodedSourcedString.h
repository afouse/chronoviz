//
//  TimeCodedSourcedString.h
//  DataPrism
//
//  Created by Adam Fouse on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeCodedString.h"

@interface TimeCodedSourcedString : TimeCodedString {

	NSString* source;
	BOOL interpolated;
	CMTime duration;

}

@property(retain) NSString* source;
@property BOOL interpolated;
@property CMTime duration;

@end
