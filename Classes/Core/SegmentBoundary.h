//
//  VideoKeyframe.h
//  Annotation
//
//  Created by Adam Fouse on 1/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreMedia/CoreMedia.h>

@interface SegmentBoundary : NSObject {
	CMTime mTime;
	
	BOOL autoCreated;
	BOOL highlighted;
}

@property BOOL autoCreated;
@property BOOL highlighted;

-(id)initFromApp:(id)theApp atTime:(CMTime)time;
-(id)initAtTime:(CMTime)time;

-(CMTime)time;


@end
