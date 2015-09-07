//
//  InteractionLog.h
//  Annotation
//
//  Created by Adam Fouse on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
@class Annotation;
@class Interaction;
@class InteractionSpeedChange;
@class InteractionAddSegment;
@class InteractionJump;
@class InteractionAnnotationEdit;

extern int const AFInteractionType;
extern int const AFInteractionTypeSpeedChange;
extern int const AFInteractionTypeAddSegment;
extern int const AFInteractionTypeJump;
extern int const AFInteractionTypeTimelineClick;
extern int const AFInteractionTypeNextPrompt;
extern int const AFInteractionTypeAnnotationEdit;

@interface InteractionLog : NSObject {
	NSMutableArray* interactions;
	NSDate* startTime;
	
	int timeScale;

	NSTimer *timer;
	NSDate* playbackStart;
	double currentPlaybackTime;
	double playbackDuration;
	int interactionIndex;
	int visualizerType;
	
	BOOL isPlaying;
}

@property BOOL isPlaying;
@property(readonly) double playbackDuration;
@property(readonly) double currentPlaybackTime;

- (void)addInteraction:(Interaction*)interaction;
- (InteractionSpeedChange*)addSpeedChange:(float)speed atTime:(QTTime)time;
- (InteractionAddSegment*)addSegmentationPoint:(QTTime)time;
- (InteractionJump*)addJumpFrom:(QTTime)time to:(QTTime)time;

- (InteractionAnnotationEdit*)addEditOfAnnotation:(Annotation*)annotation forAttribute:(NSString*)attribute withTime:(QTTime)value;
- (InteractionAnnotationEdit*)addEditOfAnnotation:(Annotation*)annotation forAttribute:(NSString*)attribute withValue:(NSObject*)value;

- (NSArray *)getSegmentationPoints;

- (NSMutableArray*)interactions;

- (void)startClock;
- (double)sessionTime;
- (void)reset;

// Disabled for now
//- (void)playback:(AppController *)app;
//- (void)stopPlayback;

- (void)setTimeScale:(int)scale;

+ (NSString*)defaultLogsDirectory;
- (BOOL)saveToDefaultFile;
- (BOOL)saveToFile:(NSString*) filename;
- (void)readFromFile:(NSString*) filename;

@end
