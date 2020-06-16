//
//  AnnotationDataAnalysisPlugin.h
//  Annotation
//
//  Created by Adam Fouse on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
@class Annotation;
@class PluginParameter;
@class PluginDataSet;
@class TimeSeriesData;
@class AnnotationCategory;
@class AnnotationDocument;

@interface AnnotationDataAnalysisPlugin : NSObject <NSCoding> {

	NSMutableArray* resultAnnotations;
	NSMutableArray* resultData;
	NSMutableArray* dataParameters;
	NSMutableArray* dataSets;
	NSMutableArray* inputParameters;
	NSMutableArray* requiredDocumentVariables;
	NSString* displayName;
    Class dataVariableClass;
    BOOL shouldShowProgress;
}

@property(retain) NSMutableArray* resultAnnotations;
@property(retain) NSMutableArray* resultData;
@property BOOL shouldShowProgress;

-(void)performAnalysis;

// Results methods
// These create new things to add to the system as a result of running the plugin
-(Annotation*)newAnnotationAtTime:(CMTime)time;
-(Annotation*)newAnnotationAtSeconds:(float)seconds;
-(TimeSeriesData*)newTimeSeries;

// Analysis support
-(AnnotationCategory*)categoryForName:(NSString*)name;
-(AnnotationDocument*)currentDocument;

-(void)clearPluginResults;
-(void)clearPluginAnnotations;

// Setup methods
-(void)setup;
-(NSArray*)dataParameters;
-(NSArray*)inputParameters;
-(NSArray*)documentVariables;
-(void)setDataVariableClass:(NSString*)className;
-(Class)dataVariableClass;
-(PluginDataSet*)addDataVariable:(NSString*)variable;
-(PluginParameter*)addInputParameter:(NSString*)parameter;
-(void)setDisplayName:(NSString*)name;
-(NSString*)displayName;

-(void)addRequiredDocumentVariable:(NSString*)variableName;
-(NSString*)valueOfDocumentVariable:(NSString*)variableName;
-(void)setDocumentVariable:(NSString*)variableName toValue:(NSString*)value;

// Loggging (sends to ChronoViz Console)
-(void)log:(NSString*)stringToLog;

// Legacy support
-(int)addDataParameter:(NSString*)parameter;
-(NSArray*)analyzeData:(NSArray*)data;


@end
