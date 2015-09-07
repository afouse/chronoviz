//
//  VideoKeyframe.m
//  Annotation
//
//  Created by Adam Fouse on 1/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SegmentBoundary.h"
#import "Annotation.h"

@implementation SegmentBoundary

@synthesize autoCreated;
@synthesize highlighted;

-(id)initFromApp:(id)theApp atTime:(QTTime)time
{
	self = [super init];
	if (self != nil)
	{
		if(time.timeValue < 0)
			time.timeValue = 0;
		mTime = time;
		self.autoCreated = NO;
	}
	return self;
}

-(id)initAtTime:(QTTime)time
{
	return [self initFromApp:nil atTime:time];
}

- (void) dealloc
{
	[super dealloc];
}


-(QTTime)time
{
	return mTime;
}



@end
