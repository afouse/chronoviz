//
//  VideoProperties.h
//  Annotation
//
//  Created by Adam Fouse on 6/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
@class AnnotationCategory;

extern NSString * const DPVideoPropertiesPasteboardType;

@interface VideoProperties : NSObject <NSCoding> {

    NSString *uuid;
    
	NSString *videoFile;
	AVPlayer* movie;
    AVPlayerItem *playerItem;
    AVPlayer *player;
	BOOL loaded;
	NSArray* audioSubset;
	
	BOOL enabled;
	BOOL localVideo;
	
	NSString *title;
	NSString *description;
	NSDate *startDate;
	CMTime offset;
	NSTimeInterval startTime;
    
	NSArray *categories;
    
    BOOL isSeekInProgress;
    CMTime chaseTime;
    AVPlayerItemStatus playerItemStatus;
}

@property(readonly) NSString *uuid;
@property(retain) NSArray *audioSubset;
@property(retain) NSString *videoFile;
@property(retain) NSString *title;
@property(retain) NSString *description;
@property(retain) NSDate *startDate;
@property(retain) AVPlayer *movie;
@property(retain) AVPlayerItem *playerItem;
@property(retain) AVPlayer *player;
@property BOOL enabled;
@property BOOL muted;
@property BOOL localVideo;
@property CMTime offset;
@property NSTimeInterval startTime;

- (id)initWithVideoFile:(NSString*)videoFile;
- (id)initFromFile:(NSString*)file;
- (void)saveToFile:(NSString*)file;

- (AVPlayer*)loadMovie;
- (BOOL)hasVideo;
- (BOOL)hasAudio;

// Video Playback Control

- (void)seekToTime:(CMTime)seektime;
- (CMTime)currentTime;

// Legacy File Support

- (NSArray*)categories;
- (void)setCategories:(NSArray*)array;

@end
