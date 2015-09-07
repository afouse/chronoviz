//
//  AnotoTrace.h
//  DataPrism
//
//  Created by Adam Fouse on 2/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeSeriesData.h"
@class TimeCodedPenPoint;

@interface AnotoTrace : TimeSeriesData {

	NSString* page;
	
	CGFloat maxX;
	CGFloat maxY;
	CGFloat minX;
	CGFloat minY;
	
}

@property(retain) NSString* page;

- (CGFloat) maxX;
- (CGFloat) maxY;
- (CGFloat) minX;
- (CGFloat) minY;

@end
