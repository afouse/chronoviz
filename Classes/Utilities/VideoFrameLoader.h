//
//  VideoFrameLoader.h
//  Annotation
//
//  Created by Adam Fouse on 7/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
@class TimelineMarker;


@interface VideoFrameLoader : NSObject {

	NSOperationQueue *queue;
	
	NSDictionary *CIImageDict;
	
	NSMutableDictionary *imagecache;
	NSMutableDictionary *frameMovies;
	NSMutableDictionary *frameSettings;
	NSMutableDictionary *movieIntervals;
	int targetFrameCount;
	CGFloat targetHeight;
	
	NSTimer *timer;
	NSMutableArray *array;
	
	QTMovie* video;
}

- (void)loadCIImage:(TimelineMarker*)marker immediately:(BOOL)now;

- (void)setVideo:(QTMovie*)video;

- (void)loadAllFramesForMovie:(QTMovie*)movie;

@end
