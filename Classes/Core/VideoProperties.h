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
	QTMovie* movie;
	BOOL loaded;
	NSArray* audioSubset;
	
	BOOL enabled;
	BOOL muted;
	BOOL localVideo;
	
	NSString *title;
	NSString *description;
	NSDate *startDate;
	CMTime offset;
	NSTimeInterval startTime;
    
	NSArray *categories;

}

@property(readonly) NSString *uuid;
@property(retain) NSArray *audioSubset;
@property(retain) NSString *videoFile;
@property(retain) NSString *title;
@property(retain) NSString *description;
@property(retain) NSDate *startDate;
@property(retain) AVAsset *movie;
@property BOOL enabled;
@property BOOL muted;
@property BOOL localVideo;
@property CMTime offset;
@property NSTimeInterval startTime;

- (id)initWithVideoFile:(NSString*)videoFile;
- (id)initFromFile:(NSString*)file;
- (void)saveToFile:(NSString*)file;

- (QTMovie*)loadMovie;
- (BOOL)hasVideo;
- (BOOL)hasAudio;

// Legacy File Support

- (NSArray*)categories;
- (void)setCategories:(NSArray*)array;

- (NSTimeInterval)computeAlignment:(VideoProperties*)otherProps;

@end
