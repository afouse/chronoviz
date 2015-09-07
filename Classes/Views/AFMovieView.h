//
//  AFMovieView.h
//  Annotation
//
//  Created by Adam Fouse on 2/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
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
	
	QTMovie *dragMovie;
	
	NSCursor *magnifyCursor;
	
	CGColorRef controlBackground;
	CGColorRef controlBackgroundActive;
	CALayer *activeControlLayer;
	NSArray *inactiveVideoFilters;
}

- (void)setLocalControl:(MovieViewerController*)controller;

- (void)setMovie:(QTMovie*)movie;
- (void)addMovie:(QTMovie*)movie;
- (void)removeMovie:(QTMovie*)movie;
- (QTMovie*)movie;
- (NSArray*)movies;

- (void)zoomInMovie:(QTMovie*)movie;
- (void)zoomOutMovie:(QTMovie*)movie;
- (void)zoomInMovie:(QTMovie*)movie toPoint:(CGPoint)pt;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

- (void)toggleMute:(id)sender;

@end
