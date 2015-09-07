//
//  TimeCodedString.m
//  Annotation
//
//  Created by Adam Fouse on 11/4/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TimeCodedString.h"


@implementation TimeCodedString

@synthesize string;

-(NSString*)csvString
{
	return [NSString stringWithFormat:@"%@,%@",[super csvString],string];
}

- (void) dealloc
{
	[string release];
	[super dealloc];
}


@end
