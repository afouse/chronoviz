//
//  VideoFrameLoader.m
//  Annotation
//
//  Created by Adam Fouse on 7/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VideoFrameLoader.h"
#import "TimelineMarker.h"
#import "TimelineView.h"
#import "SegmentVisualizer.h"
#import "CGImageWrapper.h"
#import "AppController.h"
#import "ImageSequenceView.h"
#import "VideoProperties.h"
#import <AVKit/AVKit.h>

// =================================
// = Interface for hidden methods
// =================================
@interface VideoFrameLoader (hidden)

- (void)loadMarkerCIImage:(id)data;
- (void)loadImages:(NSTimer*)theTimer;

@end

// =====================================
// = Implementation of hidden methods
// =====================================
@implementation VideoFrameLoader (hidden)

// This is the method that does the actual work of the task.
- (void)loadImages:(NSTimer*)theTimer
{
	if([array count] > 0)
	{
		[self loadMarkerCIImage:[array objectAtIndex:0]];
		[array removeObjectAtIndex:0];
	}
	else
	{
		[timer invalidate];
		timer = nil;
	}
}

- (void)loadMarkerCIImage:(id)data
{
	TimelineMarker *marker = (TimelineMarker*)data;
	if([marker visualizer]) // && ([[marker timeline] movie] == [[AppController currentApp] movie]))
	{
		BOOL exact = NO;
		
		AVPlayer *playbackMovie = [[marker visualizer] movie];
        NSURL *url = [[[playbackMovie currentItem] asset] URL]; // TODO: Check that this replacement is ok.
		
		CMTime time = [[marker boundary] time];
		NSTimeInterval timeInterval;
		timeInterval = CMTimeGetSeconds(time);
		
		NSString *identifier;
		if(exact)
		{
			identifier = [NSString stringWithFormat:@"%p-%f-cg",[[marker visualizer] movie],timeInterval];
		}
		else
		{
			float interval = [[movieIntervals objectForKey:url] floatValue];
			int bin = floor(timeInterval/interval);
			identifier = [NSString stringWithFormat:@"%p-%i-cg",[[marker visualizer] movie],bin];	
		}
		
		CGImageWrapper *imageWrap = [imagecache objectForKey:identifier];
		if(!imageWrap)
		{
			CGImageRef theImage;
			if([[[marker visualizer] videoProperties] localVideo] && [[[AppController currentApp] mainView] isKindOfClass:[ImageSequenceView class]])
			{
				ImageSequenceView* images = (ImageSequenceView*)[[AppController currentApp] mainView];
				theImage = [images cgImageAtTime:time];
			}
			else
			{
				AVPlayer *frameVideo = video;
				NSDictionary *frameDict = CIImageDict;
				if(!frameVideo)
				{
					
					frameVideo = [frameMovies objectForKey:url];
					frameDict = [frameSettings objectForKey:url];
					
					if(!frameVideo)
					{
						frameVideo = [AVPlayer playerWithURL:url];
						[frameMovies setObject:frameVideo forKey:url];
						
						NSTimeInterval duration;
						duration = CMTimeGetSeconds([[frameVideo currentItem] duration]);
						float interval = duration/targetFrameCount;
						
						[movieIntervals setObject:[NSNumber numberWithFloat:interval] forKey:url];

                        AVAsset *asset = [[frameVideo currentItem] asset];
                        NSSize contentSize = (NSSize)[[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
						float ratio = contentSize.width/contentSize.height;
						contentSize.width = (targetHeight *  ratio);
						contentSize.height = targetHeight;
						
						/*
                        frameDict = [NSDictionary
                                     dictionaryWithObjectsAndKeys:
                                     QTMovieFrameImageTypeCGImageRef,QTMovieFrameImageType,
                                     [NSValue valueWithSize:contentSize],QTMovieFrameImageSize,
                                     nil];
                        */
                        frameDict = [NSDictionary dictionary]; // TODO: Reimplement storing of information in frameDict.
                        
						[frameSettings setObject:frameDict forKey:url];
						
					}
				}
				
				CMTime offset = ([[marker visualizer] videoProperties]) ? [[[marker visualizer] videoProperties] offset] : CMTimeMake(0, 1);
				//NSLog(@"Offset: %i",(int)offset.value);
                
                AVAsset *asset = [[frameVideo currentItem] asset];
                CMTime frameTime = CMTimeAdd([[marker boundary] time], offset);
                NSError *imageError;
                theImage = [self generateImageAt:frameTime for:asset error:&imageError];
                
			}
			imageWrap = [[CGImageWrapper alloc] initWithImage:theImage];
			[imagecache setObject:imageWrap forKey:identifier];
			[imageWrap release];
		}
		//[[marker layer] setNeedsDisplay];
		//[[marker layer] setContents:[imageWrap image]];
		[marker setImage:[imageWrap image]];
		[marker setDate:[NSDate date]];
		[[marker layer] setNeedsDisplay];
	}
	else
	{
		//NSLog(@"Bad frame load");
	}
}

- (CGImageRef)generateImageAt:(CMTime)requestedTime for:(AVAsset*)asset error:(NSError * _Nullable *)error {
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    imageGenerator.requestedTimeToleranceBefore = CMTimeMakeWithSeconds(1, 600);
    imageGenerator.requestedTimeToleranceAfter = CMTimeMakeWithSeconds(1, 600);
    return [imageGenerator copyCGImageAtTime:requestedTime actualTime:nil error:error];
}


@end


@implementation VideoFrameLoader

- (id) init
{
	self = [super init];
	if (self != nil) {
		timer = nil;
		video = nil;
		array = [[NSMutableArray alloc] init];
		//queue = [[NSOperationQueue alloc] init];
		//[queue setMaxConcurrentOperationCount:1];
		imagecache = [[NSMutableDictionary alloc] init];
		frameMovies = [[NSMutableDictionary alloc] init];
		movieIntervals = [[NSMutableDictionary alloc] init];
		frameSettings = [[NSMutableDictionary alloc] init];
		targetFrameCount = 200;
		targetHeight = 200;
		
		/*
        CIImageDict = [[NSDictionary
								   dictionaryWithObjectsAndKeys:
								   QTMovieFrameImageTypeCGImageRef,QTMovieFrameImageType,
								   nil] retain];
        */
        // TODO: Reintroduce proper dictionary.
        CIImageDict = [[NSDictionary dictionary] retain];
		

	}
	return self;
}

- (void) dealloc
{
	[video release];
	[queue release];
	[CIImageDict release];
	
	[imagecache release];
	[frameMovies release];
	[movieIntervals release];
	[frameSettings release];
	
	[super dealloc];
}

- (void)loadCIImage:(TimelineMarker*)marker immediately:(BOOL)now
{
//   NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
//																		selector:@selector(loadMarkerCIImage:) object:marker];
//	[queue addOperation:theOp];
//	[theOp release];
	
	if(now)
	{
		[self loadMarkerCIImage:marker];
	}
	else
	{	
		[array addObject:marker];
		if(!timer)
		{
			[NSTimer scheduledTimerWithTimeInterval:0.001
													 target:self
												   selector:@selector(loadImages:)
												   userInfo:nil
													repeats:NO];
		}
	}
}

- (void)setVideo:(AVPlayer*)theVideo
{
	[theVideo retain];
	[video release];
	video = theVideo;
}

- (void)loadAllFramesForMovie:(AVPlayer*)movie
{
	AVPlayer *playbackMovie = movie;
    NSURL *url = [[[playbackMovie currentItem] asset] URL]; // TODO: Check that this replacement is ok.
	
	AVPlayer *frameVideo = [frameMovies objectForKey:url];
	NSDictionary *frameDict = [frameSettings objectForKey:url];

	NSTimeInterval duration;
	duration = CMTimeGetSeconds([[movie currentItem] duration]);
	
	if(!frameVideo)
	{
		NSError *error = nil;
		frameVideo = [AVPlayer playerWithURL:url];
		[frameMovies setObject:frameVideo forKey:url];

		float interval = duration/targetFrameCount;
		
		[movieIntervals setObject:[NSNumber numberWithFloat:interval] forKey:url];

        AVAsset *asset = [[frameVideo currentItem] asset];
        NSSize contentSize = (NSSize)[[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
		float ratio = contentSize.width/contentSize.height;
		contentSize.width = (targetHeight *  ratio);
		contentSize.height = targetHeight;
		
		/*
        frameDict = [NSDictionary
					 dictionaryWithObjectsAndKeys:
					 QTMovieFrameImageTypeCGImageRef,QTMovieFrameImageType,
					 [NSValue valueWithSize:contentSize],QTMovieFrameImageSize,
					 nil];
        */
        frameDict = [NSDictionary dictionary]; // TODO: Reimplement storing of information in frameDict.
        
		[frameSettings setObject:frameDict forKey:url];
		
	}
	
	NSMutableDictionary *betterFrameDict = [NSMutableDictionary dictionaryWithDictionary:frameDict];
	
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
	BOOL tensix = NO;
	if ((version.majorVersion == 10 && version.minorVersion >= 6) || version.majorVersion >= 11) {
		tensix = YES;
		[betterFrameDict setObject:[NSNumber numberWithBool:YES] forKey:@"QTMovieFrameImageSessionMode"];
	}
	
	float interval = [[movieIntervals objectForKey:url] floatValue];
	
	NSTimeInterval time;
	for(time = 0; time < duration; time += interval)
	{
		int bin = floor(time/interval);
		if((bin % 10) == 0)
		{
			NSLog(@"Loading frame %i",bin);
		}
		NSString *identifier = [NSString stringWithFormat:@"%p-%i-cg",movie,bin];
		CGImageWrapper *imageWrap = [imagecache objectForKey:identifier];
		if(!imageWrap)
		{
            AVAsset *asset = [[frameVideo currentItem] asset];
            CMTime frameTime = CMTimeMakeWithSeconds(time, 600);
            NSError *imageError;
            CGImageRef theImage = [self generateImageAt:frameTime for:asset error:&imageError];

			imageWrap = [[CGImageWrapper alloc] initWithImage:theImage];
			[imagecache setObject:imageWrap forKey:identifier];
			[imageWrap release];
		}	
	}
	
	if(tensix)
	{
		[betterFrameDict setObject:[NSNumber numberWithBool:NO] forKey:@"QTMovieFrameImageSessionMode"];AVAsset *asset = [[frameVideo currentItem] asset];
        CMTime frameTime = CMTimeMakeWithSeconds(time, 600);
        NSError *imageError;
        [self generateImageAt:frameTime for:asset error:&imageError];
		//CGImageRelease(theImage);
	}
	

}


@end
