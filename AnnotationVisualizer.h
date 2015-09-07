//
//  AnnotationVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 8/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SegmentDualVisualizer.h"
@class AnnotationCategory;

@interface AnnotationVisualizer : SegmentDualVisualizer {

	BOOL lineUpCategories;
	BOOL inlinePointAnnotations;
	BOOL drawLabels;
	
	NSMutableDictionary *categoryTracks;
	NSMutableDictionary *tracks;
	NSMutableDictionary *trackLayers;
	
	AnnotationCategory *dragCategory;
	NSMutableArray *dragCategoryMarkers;
    
    CALayer *overflowLayer;
    CGFloat minMarkerY;
}

@property BOOL lineUpCategories;
@property BOOL inlinePointAnnotations;
@property BOOL drawLabels;

-(void)sortMarkers;
-(void)clearTracks;

-(void)toggleAlignCategories;
-(void)toggleShowLabels;

@end
