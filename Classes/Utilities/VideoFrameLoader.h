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
	
	AVPlayer* video;
}

- (void)loadCIImage:(TimelineMarker*)marker immediately:(BOOL)now;

- (void)setVideo:(AVPlayer*)video;

- (void)loadAllFramesForMovie:(AVPlayer*)movie;


+ (CGImageRef)generateImageAt:(CMTime)requestedTime for:(AVPlayer*)player error:(NSError**)error;

@end
