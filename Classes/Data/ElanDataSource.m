//
//  ElanDataSource.m
//  DataPrism
//
//  Created by Adam Fouse on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ElanDataSource.h"
#import "AnnotationSet.h"
#import "AnnotationCategory.h"
#import "Annotation.h"
#import "AnnotationDocument.h"
#import <AVKit/AVKit.h>

@interface ElanDataSource (Parsing)

- (void)parseElanXML:(NSString*)filename;
- (void)convertToCategoryValues:(AnnotationSet*)set;

@end

@implementation ElanDataSource

@synthesize separateCategories;

+(NSString*)dataTypeName
{
	return @"ELAN";
}

+(BOOL)validateFileName:(NSString*)fileName
{
	return ([[fileName pathExtension] caseInsensitiveCompare:@"eaf"] == NSOrderedSame);
}

-(id)initWithPath:(NSString *)directory
{	
	self = [super initWithPath:directory];
	
	if (self != nil) {
		self.predefinedTimeCode = YES;
		self.timeCoded = YES;
		range = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
		separateCategories = YES;
		
		currentTier = nil;
		currentTierCategory = nil;
		currentStringValue = nil;
		currentAnnotation = nil;
		elanParser = nil;
		timeSlots = nil;
		tiers = nil;
		tierCategories = nil;
		
		timeScale = 1000.0;
		
	}
	return self;
}

- (void) dealloc
{
	[elanParser release];
	[tierCategories release];
	[tiers release];
	[super dealloc];
}


-(NSArray*)possibleDataTypes
{
	return [NSArray arrayWithObjects:
			DataTypeAnnotation,
			nil];
}

-(NSArray*)dataArray
{	
	if(!dataArray)
	{		
		[delegate dataSourceLoadStart];
		[delegate dataSourceLoadStatus:0];

		NSLog(@"Load file:%@",dataFile);
			
		[delegate dataSourceLoadStatus:0.25];
			
		[self parseElanXML:dataFile];
			
		NSMutableArray *variables = [NSMutableArray arrayWithCapacity:[tiers count]];
		NSMutableArray *count = [NSMutableArray arrayWithCapacity:[tiers count]];
		
		for(AnnotationSet *set in tiers)
		{
			[variables addObject:[set name]];
			[count addObject:[NSNumber numberWithInt:[[set annotations] count]]];
		}
		
		[delegate dataSourceLoadStatus:0.9];
		
		[self setDataArray:[NSArray arrayWithObjects:variables,count,nil]];
		[delegate dataSourceLoadFinished];
	}
	return dataArray;
}

-(NSArray*)importVariables:(NSArray*)variables asTypes:(NSArray*)types
{
	NSMutableArray *newDataSets = [NSMutableArray array];
	
	NSUInteger index;
	for(index = 0; index < [variables count]; index++)
	{
		NSString *variable = [variables objectAtIndex:index];
		NSString *type = [types objectAtIndex:index];
		
		// If this dataSet has already been imported, don't import it again
		for(TimeCodedData *dataSet in dataSets)
		{
			if([variable isEqualToString:[dataSet variableName]])
			{
				[newDataSets addObject:variable];
				continue;
			}
		}
				
		if([type isEqualToString:DataTypeAnnotation])
		{
			for(AnnotationSet* tier in tiers)
			{
				if([variable isEqualToString:[tier name]])
				{
					[dataSets addObject:tier];
					[tier setSource:self];
					[tier setVariableName:variable];
					[newDataSets addObject:tier];
					
					[[AnnotationDocument currentDocument] addCategory:[tierCategories objectForKey:[tier name]]];
				}
			}
		}
		else
		{
			[newDataSets addObject:[NSNull null]];
		}
	}
	
	return newDataSets;
}

-(void)parseElanXML:(NSString*)filename
{
	if(tiers)
	{
		[tiers release];
	}
	tiers = [[NSMutableArray alloc] init];
	
	if(tierCategories)
	{
		[tierCategories release];
	}
	tierCategories = [[NSMutableDictionary alloc] init];
	
	if(timeSlots)
	{
		[timeSlots release];
	}
	timeSlots = [[NSMutableDictionary alloc] init];
	
	if(linguisticTypes)
	{
		[linguisticTypes release];
	}
	linguisticTypes = [[NSMutableDictionary alloc] init];
	
    NSURL *xmlURL = [NSURL fileURLWithPath:filename];
	if(elanParser)
	{
		[elanParser release];
	}
    elanParser = [[NSXMLParser alloc] initWithContentsOfURL:xmlURL];
    [elanParser setDelegate:self];
    [elanParser setShouldResolveExternalEntities:NO];
    [elanParser parse];
}

- (void)convertToCategoryValues:(AnnotationSet*)set
{
	for(Annotation *annotation in [set annotations])
	{
		AnnotationCategory *value = [[annotation category] valueForName:[annotation annotation]];
		[annotation replaceCategory:[annotation category] withCategory:value];
	}
}

#pragma mark XML Parsing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ( [elementName isEqualToString:@"TIME_SLOT"]) 
	{
		NSString *timeSlot = [attributeDict objectForKey:@"TIME_SLOT_ID"];
		long long timeValue = [[attributeDict objectForKey:@"TIME_VALUE"] longLongValue];
		NSTimeInterval timeInterval = (double)timeValue/timeScale;
		
		[timeSlots setObject:[NSNumber numberWithFloat:timeInterval] forKey:timeSlot];
    }
	else if ( [elementName isEqualToString:@"TIER"]) 
	{
		NSString *tierName = [attributeDict objectForKey:@"TIER_ID"];
		NSString *linguisticType = [attributeDict objectForKey:@"LINGUISTIC_TYPE_REF"];
		
		[linguisticTypes setObject:linguisticType forKey:tierName];
		
		currentTier = [[AnnotationSet alloc] init];
		[currentTier setName:tierName];
		currentTierCategory = [[AnnotationDocument currentDocument] categoryForName:tierName];
		if(!currentTierCategory)
		{
			//currentTierCategory = [[AnnotationDocument currentDocument] createCategoryWithName:tierName];
			currentTierCategory = [[AnnotationCategory alloc] init];
			[currentTierCategory setName:tierName];
			[currentTierCategory autoColor];
			[tierCategories setObject:currentTierCategory forKey:tierName];
			[currentTierCategory release];
		}
		
		[tiers addObject:currentTier];
		
		[currentTier release];
	}
    else if ( [elementName isEqualToString:@"ALIGNABLE_ANNOTATION"] ) 
	{
		NSString *startTimeSlot = [attributeDict objectForKey:@"TIME_SLOT_REF1"];
		NSString *endTimeSlot = [attributeDict objectForKey:@"TIME_SLOT_REF2"];
		NSTimeInterval startTime = [[timeSlots objectForKey:startTimeSlot] floatValue];
		NSTimeInterval endTime = [[timeSlots objectForKey:endTimeSlot] floatValue];
		currentAnnotation = [[Annotation alloc] initWithTimeInterval:startTime];
		[currentAnnotation setIsDuration:YES];
		[currentAnnotation setEndTime:CMTimeMakeWithSeconds(endTime, 600)];
		[currentAnnotation setCategory:currentTierCategory];
		
		[currentTier addAnnotation:currentAnnotation];
		[currentAnnotation release];
		
		if(CMTimeCompare(range.duration, [currentAnnotation endTime]) == NSOrderedAscending)
		{
			range.duration = [currentAnnotation endTime];
		}
    }
	else if ( [elementName isEqualToString:@"LINGUISTIC_TYPE"] ) 
	{
		NSString *controlledVocabulary= [attributeDict objectForKey:@"CONTROLLED_VOCABULARY_REF"];
		if(controlledVocabulary)
		{
			NSString *typeID = [attributeDict objectForKey:@"LINGUISTIC_TYPE_ID"];
			for(AnnotationSet* set in tiers)
			{
				if([[linguisticTypes objectForKey:[set name]] isEqualToString:typeID])
				{
					[self convertToCategoryValues:set];
				}
			}
		}

    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!currentStringValue) {
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    }
    [currentStringValue appendString:string];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
    if ([elementName isEqualToString:@"ANNOTATION_VALUE"] ) {
        [currentAnnotation setAnnotation:[currentStringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    }
    // currentStringValue is an instance variable
    [currentStringValue release];
    currentStringValue = nil;
	
	if ([elementName isEqualToString:@"ANNOTATION_DOCUMENT"] ) {
       	[timeSlots release];
		timeSlots = nil;
		
		[linguisticTypes release];
		linguisticTypes = nil;
		
		currentTier = nil;
		currentTierCategory = nil;
		currentAnnotation = nil;
    }
}


@end
