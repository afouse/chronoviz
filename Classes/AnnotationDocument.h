//
//  AnnotationDocument.h
//  Annotation
//
//  Created by Adam Fouse on 9/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
@class VideoProperties;
@class AnnotationXMLParser;
@class TimeSeriesData;
@class Annotation;
@class AnnotationCategory;
@class DataSource;
@class CompoundDataSource;
@class DPActivityLog;

extern NSString * const MediaChangedNotification;
extern NSString * const DPMediaAddedKey;
extern NSString * const DPMediaRemovedKey;
extern NSString * const CategoriesChangedNotification;

extern int const DPCurrentDocumentFormatVersion;

@interface AnnotationDocument : NSObject {

	NSString *annotationsDirectory;
	NSString *annotationsImageDirectory;
	NSString *annotationsFile;
	NSString *videoInfoFile;
	
	VideoProperties *videoProperties;
	AnnotationXMLParser *xmlParser;
	
	NSMutableArray *mediaProperties;
	NSMutableArray *media;
	
	NSMutableArray *categories;
	NSMutableArray *keywords;
	NSMutableDictionary *documentProperties;
    
    NSMutableDictionary *savedLayouts;
	
	//NSMutableArray *data;
	NSMutableArray *dataSources;
	
	DPActivityLog *activityLog;
	
	BOOL modified;
	BOOL loaded;
}

@property BOOL modified;
@property(retain) DPActivityLog* activityLog;

+ (AnnotationDocument*)currentDocument;

- (id)initForVideo:(NSString*)videoFile;
- (id)initAtFile:(NSString*)filename withVideo:(NSString*)videoFile;
- (id)initFromFile:(NSString*)filename;

- (void)save;
- (BOOL)saveToPackage:(NSString*)filename;

- (void)saveState:(NSData*)stateData;
- (NSData*)stateData;

- (void)saveState:(NSData*)stateData withName:(NSString*)stateName;
- (NSArray*)savedStates;
- (NSData*)stateForName:(NSString*)stateName;
- (void)removeStateNamed:(NSString*)stateName;

- (QTMovie*)setVideoFile:(NSString*)videoFile;
- (BOOL)setDuration:(QTTime)duration;
- (QTTime)duration;

- (void)addAnnotation:(Annotation*)annotation;
- (void)addAnnotations:(NSArray*)annotations;
- (void)removeAnnotation:(Annotation*)annotation;
- (void)removeAnnotations:(NSArray*)annotations;
- (void)saveAnnotations;

- (AnnotationCategory*)categoryForName:(NSString*)categoryName;
- (AnnotationCategory*)categoryForIdentifier:(NSString*)qualifiedCategoryName;
- (AnnotationCategory*)createCategoryWithName:(NSString*)name;
- (AnnotationCategory*)createCategoryForIdentifier:(NSString*)qualifiedCategoryName;
- (AnnotationCategory*)annotationCategoryForKeyEquivalent:(NSString*)key;
- (Annotation*)addAnnotationForCategoryKeyEquivalent:(NSString*)key;
- (NSString*)identifierForCategory:(AnnotationCategory*)category;
- (void)addCategory:(AnnotationCategory*)category;
- (void)addCategory:(AnnotationCategory*)category atIndex:(NSInteger)index;
- (void)moveCategory:(AnnotationCategory*)category toIndex:(NSInteger)index;
- (void)removeCategory:(AnnotationCategory*)category;
- (void)saveCategories;

- (void)addKeyword:(NSString*)keyword;
- (void)removeKeyword:(NSString*)keyword;
- (BOOL)keywordExists:(NSString*)keyword;

- (void)addDataSource:(DataSource*)dataSource;
- (void)removeDataSource:(DataSource*)dataSource;
- (BOOL)hasDataFile:(NSString*)file;
- (CompoundDataSource*)createCompoundDataSource:(NSArray*)sources;
- (DataSource*)dataSourceForAnnotation:(Annotation*)annotation;
- (void)saveData;

//- (VideoProperties*)addMediaFile:(NSString*)mediaFile;
//- (void)removeVideo:(VideoProperties*)properties;
- (void)saveVideoProperties:(VideoProperties*)properties;
- (void)saveMediaFiles;
- (void)saveDocumentProperties;

- (NSArray*)annotations;
- (NSArray*)annotationsForCategory:(AnnotationCategory*)category;
- (NSArray*)categories;
- (NSArray*)keywords;
- (NSArray*)dataSources;
- (QTMovie*)movie;
- (NSArray*)media;
- (NSArray*)mediaProperties;
- (NSArray*)allMediaProperties;
- (NSMutableDictionary*)documentVariables;
- (NSDate*)startDate;

- (NSString*)annotationsDirectory;
- (NSString*)annotationsImageDirectory;
- (NSString*)annotationsFile;
- (NSString*)videoInfoFile;
- (NSString*)resolveFile:(NSString*)file;
- (NSArray*)timeSeriesData;
- (NSArray*)dataSets;
- (NSArray*)dataSetsOfClass:(Class)dataSetClass;
- (VideoProperties*)videoProperties;
- (AnnotationXMLParser*)xmlParser;

@end
