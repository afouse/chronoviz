//
//  AnnotationDataAnalysisPlugin.m
//  Annotation
//
//  Created by Adam Fouse on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationDataAnalysisPlugin.h"
#import "TimeSeriesData.h"
#import "TimeCodedDataPoint.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "PluginParameter.h"
#import "PluginDataSet.h"
#import "PluginManager.h"
#import "PluginDataSource.h"
#import "AnnotationSet.h"
#import "AnnotationDocument.h"
#import "DPConsole.h"

@implementation AnnotationDataAnalysisPlugin

@synthesize resultAnnotations;
@synthesize resultData;
@synthesize shouldShowProgress;

- (id) init
{
	self = [super init];
	if (self != nil) {
		dataParameters = [[NSMutableArray alloc] init];
		dataSets = [[NSMutableArray alloc] init];
		inputParameters = [[NSMutableArray alloc] init];
		requiredDocumentVariables = [[NSMutableArray alloc] init];
        dataVariableClass = [TimeSeriesData class];
		[self setup];
	}
	return self;
}

- (void) dealloc
{
	[requiredDocumentVariables release];
	[resultAnnotations release];
	[resultData release];
	[dataParameters release];
	[inputParameters release];
	[dataSets release];
	[displayName release];
	[super dealloc];
}

-(void)performAnalysis
{
    NSLog(@"Warning: running plugin without overriding performAnalysis");
}

-(NSArray*)analyzeData:(NSArray*)data
{	
    [self performAnalysis];
	return nil;
}

#pragma mark Setup

-(void)setup
{
	[self setDisplayName:@"Default Plugin"];
}

-(void)setDataVariableClass:(NSString*)className
{
    Class variableClass = NSClassFromString(className);
    if(variableClass)
    {
        dataVariableClass = variableClass;
    }
}

-(Class)dataVariableClass
{
    return dataVariableClass;
}

-(int)addDataParameter:(NSString*)parameter
{
	PluginDataSet *dataSet = [[PluginDataSet alloc] init];
	dataSet.name = parameter;
	dataSet.defaultVariable = @"";
	[dataSets addObject:dataSet];
	[dataSet release];
	
	[dataParameters addObject:parameter];
	return ([dataParameters count] - 1);
}

-(PluginDataSet*)addDataVariable:(NSString*)variable
{
	PluginDataSet *dataSet = [[PluginDataSet alloc] init];
	dataSet.defaultVariable = variable;
	dataSet.name = variable;
	[dataSets addObject:dataSet];
	[dataSet release];
	
	[dataParameters addObject:variable];
	
	return dataSet;
}

-(PluginParameter*)addInputParameter:(NSString*)parameter
{
	PluginParameter *param = [[PluginParameter alloc] init];
	[param setParameterName:parameter];
	param.maxValue = 100;
	param.minValue = 0;
	[inputParameters addObject:param];
	[param release];
	return param;
}

#pragma mark Results

-(Annotation*)newAnnotationAtTime:(CMTime)time
{
	if(!resultAnnotations)
	{
		resultAnnotations = [[NSMutableArray alloc] init];
	}
	Annotation* annotation = [[Annotation alloc] initWithQTTime:time];
    // Better to do this at the end of the run in PluginConfiguration
	// [[AnnotationDocument currentDocument] addAnnotation:annotation];
	[resultAnnotations addObject:annotation];
	return annotation;
}

-(Annotation*)newAnnotationAtSeconds:(float)seconds
{
	return [self newAnnotationAtTime:CMTimeMakeWithSeconds(seconds, 600)];
}

-(TimeSeriesData*)newTimeSeries
{
	if(!resultData)
	{
		resultData = [[NSMutableArray alloc] init];
	}
	TimeSeriesData* data = [[TimeSeriesData alloc] init];
    [data setName:[[self displayName] stringByAppendingString:@" Data"]];
	[resultData addObject:data];
	return data;
}

#pragma mark Analysis Support

-(AnnotationCategory*)categoryForName:(NSString*)name
{
	AnnotationCategory *category = [[AnnotationDocument currentDocument] categoryForName:name];
	if(category == nil)
	{
		category = [[AnnotationDocument currentDocument] createCategoryWithName:name];
	}
	return category;
}

-(AnnotationDocument*)currentDocument
{
    return [AnnotationDocument currentDocument];
}

-(void)clearPluginAnnotations
{
    PluginDataSource *source = [[PluginManager defaultPluginManager] dataSourceForPlugin:self];
    if(source)
    {
        NSArray *sourceDataSets = [[source dataSets] copy];
        for(NSObject *data in sourceDataSets)
        {
            if([data isKindOfClass:[AnnotationSet class]])
            {
                AnnotationSet *annotations = (AnnotationSet*)data;
                [[AnnotationDocument currentDocument] removeAnnotations:[annotations annotations]];
                [source removeDataSet:annotations];
            }
        }
        [sourceDataSets release];
    }
}

-(void)clearPluginResults
{
    PluginDataSource *source = [[PluginManager defaultPluginManager] dataSourceForPlugin:self];
    if(source)
    {
        NSArray *sourceDataSets = [[source dataSets] copy];
        for(TimeCodedData *data in sourceDataSets)
        {
            if([data isKindOfClass:[AnnotationSet class]])
            {
                AnnotationSet *annotations = (AnnotationSet*)data;
                [[AnnotationDocument currentDocument] removeAnnotations:[annotations annotations]];
            }
            [source removeDataSet:data];
        }
        [sourceDataSets release];
    } 
}

-(NSArray*)dataParameters
{
	return dataSets;
}

-(NSArray*)inputParameters
{
	return inputParameters;
}

-(NSArray*)documentVariables
{
	return requiredDocumentVariables;
}

-(void)setDisplayName:(NSString *)name
{
	[name retain];
	[displayName release];
	displayName = name;
}

-(NSString*)displayName
{
	if(displayName)
	{
		return displayName;
	}
	else
	{
		return @"Default Plugin";
	}
}

-(void)addRequiredDocumentVariable:(NSString*)variableName
{
	[requiredDocumentVariables addObject:variableName];
}

-(NSString*)valueOfDocumentVariable:(NSString*)variableName
{
	NSString *value = [[[AnnotationDocument currentDocument] documentVariables] valueForKey:variableName];
	if(!value)
	{
		value = @"";
	}
	return value;
}

-(void)setDocumentVariable:(NSString*)variableName toValue:(NSString*)value
{
	[[[AnnotationDocument currentDocument] documentVariables] setObject:value forKey:variableName];
}

-(void)log:(NSString*)stringToLog
{
	NSLog(@"Plugin Log: %@",stringToLog);
	[[DPConsole defaultConsole] addConsoleEntry:[NSString stringWithFormat:@"Plugin %@:%@",[self displayName],stringToLog]]; 
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		dataParameters = [[NSMutableArray alloc] init];
		dataSets = [[NSMutableArray alloc] init];
		inputParameters = [[NSMutableArray alloc] init];
		[self setup];
	}
    return self;
}

@end
