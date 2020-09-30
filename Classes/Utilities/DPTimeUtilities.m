//
//  DPTimeUtilities.c
//  ChronoViz
//
//  Created by Adam Fouse on 11/18/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPTimeUtilities.h"
#import <AVKit/AVKit.h>

int dpCMTimeValueSort( id obj1, id obj2, void *context ) {
	
	CMTime time1 = [(NSValue*)obj1 CMTimeValue];
	CMTime time2 = [(NSValue*)obj2 CMTimeValue];
	
	return CMTimeCompare(time1,time2);
}
