//
//  TimeCodedString.h
//  Annotation
//
//  Created by Adam Fouse on 11/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeCodedDataPoint.h"

@interface TimeCodedString : TimeCodedDataPoint {

	NSString* string;
	
}

@property(retain) NSString* string;

@end
