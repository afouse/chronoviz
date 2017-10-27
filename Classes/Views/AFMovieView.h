//
//  AFMovieView.h
//  Annotation
//
//  Created by Adam Fouse on 2/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
@class AppController;
@class MovieViewerController;
@class VideoProperties;
@class Annotation;

@interface AFMovieView : NSView {
	IBOutlet AppController *mAppController;
	
	MovieViewerController* localController;
	
	Annotation *lastAddedAnnotation;
	
	NSMutableArray *movies;
	NSMutableArray *movieLayers;
	NSMutableSet *controlLayers;
	
	BOOL setup;
	
	int resizeMovieIndex;
	NSPoint resizeMoviePoint;
	
	AVAsset *dragMovie;
	
	NSCursor *magnifyCursor;
	
	CGColorRef controlBackground;
	CGColorRef controlBackgroundActive;
	CALayer *activeControlLayer;
	NSArray *inactiveVideoFilters;
}

- (void)setLocalControl:(MovieViewerController*)controller;

- (void)setMovie:(AVAsset*)movie;
- (void)addMovie:(AVAsset*)movie;
- (void)removeMovie:(AVAsset*)movie;
- (AVAsset*)movie;
- (NSArray*)movies;

- (void)zoomInMovie:(AVAsset*)movie;
- (void)zoomOutMovie:(AVAsset*)movie;
- (void)zoomInMovie:(AVAsset*)movie toPoint:(CGPoint)pt;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

- (void)toggleMute:(id)sender;

@end
