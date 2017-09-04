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

-(id)initFromApp:(id)theApp atTime:(CMTime)time
{
	self = [super init];
	if (self != nil)
	{
		if(time.value < 0)
			time.value = 0;
		mTime = time;
		self.autoCreated = NO;
	}
	return self;
}

-(id)initAtTime:(CMTime)time
{
	return [self initFromApp:nil atTime:time];
}

- (void) dealloc
{
	[super dealloc];
}


-(CMTime)time
{
	return mTime;
}



@end
