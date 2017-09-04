//
//  Annotation.h
//  Annotation
//
//  Created by Adam Fouse on 6/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreMedia/CoreMedia.h>
#import "SegmentBoundary.h"
@class AnnotationCategory;

extern NSString * const AnnotationUpdatedNotification;
extern NSString * const AnnotationSelectedNotification;

@interface Annotation : SegmentBoundary {
	
	id document;
	
	BOOL isDuration;
	NSString *title;
	NSURL *image;
	NSString *color;
	NSString *textColor;
	
	NSString *source;
	NSDate *creationDate;
	NSDate *modificationDate;
	NSString *creationUser;
	NSString *modificationUser;
	
	NSString *caption;
	
	NSString *annotation;
	
    CMTime startTime;
	CMTime endTime;
	
	BOOL isCategory;
	BOOL keyframeImage;
	
	NSMutableArray *categories;
	NSMutableArray *keywords;
	
	NSColor *colorObject;
	NSXMLElement *xmlRepresentation;
	NSImage *frameRepresentation;
	BOOL selected;
	
}

@property BOOL keyframeImage;
@property BOOL selected;
@property BOOL isDuration;
@property BOOL isCategory;
@property CMTime startTime;
@property CMTime endTime;
@property(assign) id document;
@property(assign) NSXMLElement *xmlRepresentation;
@property(retain) NSImage *frameRepresentation;
@property(assign) NSString *startTimeString;
@property(assign) NSString *endTimeString;
@property(copy) NSString *title;
@property(retain) NSURL *image;
@property(retain) NSString *color;
@property(retain) NSString *textColor;
@property(retain) AnnotationCategory *category;
@property(retain) NSString *caption;
@property(copy) NSString *annotation;
@property(retain) NSColor *colorObject;
@property(retain) NSString *source;
@property(retain) NSDate *creationDate;
@property(retain) NSDate *modificationDate;
@property(retain) NSString *creationUser;
@property(retain) NSString *modificationUser;

-(id)initWithTimeInterval:(NSTimeInterval)interval;
-(id)initWithStart:(NSDate *)time sinceDate:(NSDate*)referenceDate;
-(id)initWithCMTime:(CMTime)time;
-(id)initWithCMTime:(CMTime)time andTitle:(NSString *)theTitle andAnnotation:(NSString *)theAnnotation;
//-(id)initWithStart:(NSDate *)time andTitle:(NSString *)theTitle andAnnotation:(NSString *)theAnnotation;

-(void)setUpdated;

-(NSArray*)categories;
-(void)addCategory:(AnnotationCategory*)theCategory;
-(void)removeCategory:(AnnotationCategory*)theCategory;
-(void)replaceCategory:(AnnotationCategory*)oldCategory withCategory:(AnnotationCategory*)newCategory;

-(void)addKeyword:(NSString*)keyword;
-(void)removeKeyword:(NSString*)keyword;
-(NSArray*)keywords;
-(void)setKeywords:(NSArray*)theKeywords;

-(CMTimeRange)range;

- (NSTimeInterval)startTimeSeconds;
- (NSTimeInterval)endTimeSeconds;
- (NSColor*)colorObject;
- (void)setColorObject:(NSColor*)colorObj;

+ (NSColor*)colorForString:(NSString*)colorName;

@end
