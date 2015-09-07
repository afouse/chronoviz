//
//  NSStringUUID.m
//  ChronoViz
//
//  Created by Adam Fouse on 3/18/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "NSStringUUID.h"


@implementation NSString (UUID)

+ (NSString*) stringWithUUID {
	CFUUIDRef	uuidObj = CFUUIDCreate(nil);//create a new UUID
	//get the string representation of the UUID
	NSString	*uuidString = (NSString*)CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	return [uuidString autorelease];
}

@end
