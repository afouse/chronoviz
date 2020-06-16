//
//  AudioVisualizer.h
//  Annotation
//
//  Created by Adam Fouse on 12/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SegmentVisualizer.h"
#import "DataSource.h"
@class AudioExtractor;

@interface AudioVisualizer : SegmentVisualizer <DataSourceDelegate> {

	NSArray *fullsubset;
	NSMutableArray *subset;
	CMTimeRange subsetRange;
	
	CALayer *graphLayer;
	
	CGMutablePathRef graph;
	CMTimeRange graphRange;
	
	AudioExtractor *audioExtractor;
	NSTimer *loadTimer;
	NSTimer *resampleTimer;
	BOOL stopTimer;
	
	NSInteger subsetTargetSize;
}

- (void)createGraph;
- (void)loadData;
//- (void)setData:(NSArray*)array;

@end
