//
//  PluginConfiguration.h
//  Annotation
//
//  Created by Adam Fouse on 9/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class AnnotationDataAnalysisPlugin;
@class TimeCodedData;
@class PluginParameter;
@class PluginAnnotationSet;
@class AnnotationFilter;

@interface PluginConfiguration : NSObject <NSCoding> {

	AnnotationDataAnalysisPlugin *plugin;
	NSString* description;
	NSMutableArray *dataSets;
	NSMutableArray *dataSetsNames;
	NSArray *inputValues;
}

@property(retain) NSString* description;

-(id)initWithPlugin:(AnnotationDataAnalysisPlugin*)thePlugin;

-(BOOL)runPlugin:(id)sender;

-(void)setDataSet:(TimeCodedData*)dataSet forIndex:(NSUInteger)index;
-(TimeCodedData*)dataSetForIndex:(NSUInteger)index;

-(void)setInputValue:(CGFloat)value forIndex:(NSUInteger)index;
-(PluginParameter*)inputValueForIndex:(NSUInteger)index;

-(void)setAnnotationFilter:(AnnotationFilter*)filter forIndex:(NSUInteger)index;
-(PluginAnnotationSet*)annotationSetForIndex:(NSUInteger)index;

-(AnnotationDataAnalysisPlugin*)plugin;

@end
