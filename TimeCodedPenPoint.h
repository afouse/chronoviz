//
//  TimeCodedPenPoint.h
//  DataPrism
//
//  Created by Adam Fouse on 2/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeCodedDataPoint.h"

@interface TimeCodedPenPoint : TimeCodedDataPoint {
	
	CGFloat x;
	CGFloat y;
	float force;
	
}

@property CGFloat x;
@property CGFloat y;
@property float force;

@end
