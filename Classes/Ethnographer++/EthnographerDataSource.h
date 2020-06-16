//
//  EthnographerDataSource.h
//  ChronoViz
//
//  Created by Adam Fouse on 1/22/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataSource.h"
@class AnotoNotesData;
@class Annotation;
@class AnnotationCategory;
@class AnnotationSet;
@class EthnographerTemplate;

@interface EthnographerDataSource : DataSource {
	
	NSMutableArray *sessions;
    NSMutableDictionary *sessionAnnotations;
	NSMutableSet *pages;
    NSMutableDictionary *pageRotations;
	NSMutableDictionary *anotoPages;
	
	NSXMLDocument *sessionXMLDoc;
	NSXMLElement *currentNotesElement;
	AnotoNotesData *currentSession;
	AnnotationSet *currentAnnotations;
	AnnotationCategory *currentAnnotationCategory;
	NSMutableArray *currentTraces;
	NSMutableArray *currentTraceBuffer;
	NSTimer *currentSaveTimer;
	
	NSDateFormatter *xmlDateFormatter;
	NSTimeInterval startTime;
	long long rtcAdjustment;
	
	BOOL mappingsImported;
	
	EthnographerTemplate *backgroundTemplate;
	
}

@property BOOL mappingsImported;
@property(retain) EthnographerTemplate *backgroundTemplate;
@property(readonly) AnnotationSet *currentAnnotations;

- (NSArray*)sessions;
- (NSSet*)pages;
- (NSDictionary*)pageRotations;
- (NSArray*)anotoPages;

- (NSUInteger)rotationForPage:(NSString*)pageNumber;
- (void)setRotation:(NSUInteger)rotationValue forPage:(NSString*)pageNumber;

- (NSString*)livescribePageForAnotoPage:(NSString*)anotoPage;

- (Annotation*)createAnnotationFromTraces:(NSArray*)currentTraces;
- (Annotation*)createAnnotationFromTraces:(NSArray*)currentTraces saveImage:(BOOL)saveImage;
- (Annotation*)createAnnotationFromTraces:(NSArray*)currentTraces saveImage:(BOOL)saveImage scale:(CGFloat)scale;
- (NSImage*)imageForTraces:(NSArray*)imageTraces;
- (NSImage*)imageForTraces:(NSArray*)imageTraces withRotation:(NSUInteger)rotation andScale:(CGFloat)scale;

- (AnotoNotesData*)currentSession;
- (AnotoNotesData*)newSession;
- (NSArray*)addFileToCurrentSession:(NSString*)file atTimeRange:(CMTimeRange)timeRange onPage:(NSString*)setPage;
- (NSArray*)tracesFromFile:(NSString *)file overTimeRange:(CMTimeRange)timeRange onPage:(NSString*)setPage;
- (NSArray*)tracesFromFile:(NSString *)file;
- (BOOL)saveTraces:(NSArray*)tracesArray toFile:(NSString *)file;
- (void)reloadSessionXML;
- (void)updateSessionFile:(id)sender;
- (void)updateAnotoMappings;

@end
