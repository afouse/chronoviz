//
//  TimeCodedDataPoint.h
//  Annotation
//
//  Created by Adam Fouse on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>

@interface TimeCodedDataPoint : NSObject <NSCoding> {
	CMTime time;
	double value;	
}

@property CMTime time;
@property double value;

-(NSString*)csvString;
-(double)numericValue;

-(NSTimeInterval)seconds;

@end
