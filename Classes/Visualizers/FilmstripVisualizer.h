//
//  FilmstripVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 8/5/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "SegmentVisualizer.h"
@class VideoFrameLoader;

@interface FilmstripVisualizer : SegmentVisualizer {
	
	int autoSegmentPadding;
	BOOL builtMarkers;
}


-(void)buildMarkers;

@end
