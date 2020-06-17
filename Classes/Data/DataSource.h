//
//  DataSource.h
//  Annotation
//
//  Created by Adam Fouse on 10/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
@class TimeSeriesData;
@class Annotation;
@class TimeCodedData;

@protocol DataSourceDelegate

-(void)dataSourceLoadStart;
-(void)dataSourceLoadStatus:(CGFloat)percentage;
-(BOOL)dataSourceCancelLoad;
-(void)dataSourceLoadFinished;

@end

extern NSString * const DataSourceUpdatedNotification;
extern NSString * const DPDataSetAddedNotification;
extern NSString * const DPDataSetRemovedNotification;

extern NSString * const DataTypeTimeSeries;
extern NSString * const DataTypeGeographicLat;
extern NSString * const DataTypeGeographicLon;
extern NSString * const DataTypeSpatialX;
extern NSString * const DataTypeSpatialY;
extern NSString * const DataTypeImageSequence;
extern NSString * const DataTypeAnnotationTime;
extern NSString * const DataTypeAnnotationEndTime;
extern NSString * const DataTypeAnnotationTitle;
extern NSString * const DataTypeAnnotationCategory;
extern NSString * const DataTypeAnnotation;
extern NSString * const DataTypeAudio;
extern NSString * const DataTypeTranscript;

enum DataPrismTimeCoding {
	DataPrismTimeCodingInteger,
	DataPrismTimeCodingFloat,
	DataPrismTimeCodingHoursMinutesSeconds,
	DataPrismTimeCodingDate
};

@interface DataSource : NSObject <NSCoding> {

	NSString *uuid;
	
	NSString *dataFile;
	NSString *name;
	BOOL directoryDataFile;
	
	BOOL predefinedTimeCode;
	BOOL timeCoded;
	BOOL absoluteTime;
	NSUInteger timeColumn;
	enum DataPrismTimeCoding timeCoding;
	
	NSArray *dataArray;
	CMTimeRange range;
	CMTime timeEncodingOffset;
	
	NSMutableArray *dataSets;
    NSMutableDictionary *linkedVariables;
	
	NSObject <DataSourceDelegate> *delegate;
	
	BOOL imported;
	BOOL local;
}

@property(readonly) NSString* uuid;
@property(retain) NSString* name;
@property BOOL predefinedTimeCode;
@property BOOL absoluteTime;
@property BOOL timeCoded;
@property BOOL local;
@property BOOL imported;
@property BOOL directoryDataFile;
@property NSUInteger timeColumn;
@property(retain) NSArray* dataArray;
@property(readonly) NSDictionary* linkedVariables;

-(id)initWithPath:(NSString*)thePath;

+(NSString*)dataTypeName;
+(NSString*)defaultsIdentifier;
+(BOOL)validateFileName:(NSString*)fileName;

-(NSArray*)possibleDataTypes;
-(NSString*)defaultDataType:(NSString*)variableName;
-(BOOL)lockedDataType:(NSString*)variableName;
-(NSArray*)defaultVariablesToImport;
-(NSArray*)variables;
-(NSArray*)importVariables:(NSArray*)variables asTypes:(NSArray*)types;

-(void)load;
-(void)reset;
-(void)addDataSet:(TimeCodedData*)dataSet;
-(void)removeDataSet:(TimeCodedData*)dataSet;
-(CMTime)timeForRowArray:(NSArray*)row;
-(TimeSeriesData*)timeSeriesDataFromColumn:(NSUInteger)columnIndex;


-(NSDate*)startDate;
-(void)setRange:(CMTimeRange)newRange;
-(CMTimeRange)range;

-(NSString*)dataFile;
-(void)setDataFile:(NSString*)theDataFile;
-(NSArray*)dataSets;

-(void)addAnnotation:(Annotation*)annotation;

- (NSObject <DataSourceDelegate>*)delegate;
- (void)setDelegate:(NSObject<DataSourceDelegate>*)new_delegate;

@end
