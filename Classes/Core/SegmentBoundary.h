//
//  VideoKeyframe.h
//  Annotation
//
//  Created by Adam Fouse on 1/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface SegmentBoundary : NSObject {
	QTTime mTime;
	
	BOOL autoCreated;
	BOOL highlighted;
}

@property BOOL autoCreated;
@property BOOL highlighted;

-(id)initFromApp:(id)theApp atTime:(QTTime)time;
-(id)initAtTime:(QTTime)time;

-(QTTime)time;


@end
