//
//  InqScribeDataSource.m
//  DataPrism
//
//  Created by Adam Fouse on 4/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "InqScribeDataSource.h"
#import "TimeCodedSourcedString.h"
#import "AnnotationSet.h"
#import "Annotation.h"
#import "AnnotationDocument.h"
#import "AnnotationCategory.h"
#import "TranscriptData.h"
#import "DPConstants.h"

@interface InqScribeDataSource (InqScribeParsing)

-(NSArray *)parseTranscriptData:(NSString*)data;
-(BOOL)scanTimeCodeFromScanner:(NSScanner*)theScanner intoTimeInterval:(NSTimeInterval*)timeInterval;
-(void)addObject:(id)obj toRow:(NSMutableArray*)targetRow inMatrix:(NSMutableArray*)matrix;
- (void)updateAnnotations;

@end

@implementation InqScribeDataSource

@synthesize interpolate;

+(NSString*)dataTypeName
{
	return @"InqScribe";
}

+(BOOL)validateFileName:(NSString*)fileName
{
	return [[fileName pathExtension] isEqualToString:@"inqscr"];
}

-(NSArray*)defaultVariablesToImport
{
	return [NSArray arrayWithObjects:@"Transcript Data",@"Annotations",nil];
}

-(NSArray*)possibleDataTypes
{
	return [NSArray arrayWithObjects:
			DataTypeTranscript,
			DataTypeAnnotation,
			nil];
}

-(NSString*)defaultDataType:(NSString*)variableName
{
	if([variableName rangeOfString:@"Transcript Data" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		return DataTypeTranscript;
	}
	else if([variableName rangeOfString:@"Annotations" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		return DataTypeAnnotation;
	}
	else
	{
		return DataTypeAnnotation;
	}
}


-(id)initWithPath:(NSString *)directory
{	
	self = [super initWithPath:directory];
	
	if (self != nil) {
		self.predefinedTimeCode = YES;
		self.timeCoded = YES;
		range = CMTimeRangeMake(kCMTimeZero, kCMTimeZero);
		transcriptFPS = 29;
		interpolate = YES;
		transcriptStrings = nil;
		annotationSet = nil;
		
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		self.predefinedTimeCode = YES;
		self.timeCoded = YES;
		for(TimeCodedData* data in [self dataSets])
		{
			if([data isKindOfClass:[TranscriptData class]])
			{
				transcriptStrings = [[(TranscriptData*)data timeCodedStrings] mutableCopy];
			}
			else if ([data isKindOfClass:[AnnotationSet class]])
			{
				annotationSet = [(AnnotationSet*)data retain];
			}
		}
	}
    return self;
}


- (void) dealloc
{
	[transcriptStrings release];
	[annotationSet release];
	[super dealloc];
}

-(void)setRange:(CMTimeRange)newRange
{
	CMTime previousDiff = range.start;
	CMTime diff = newRange.start;
	
	//[super setRange:newRange];
	range = newRange;
	
	for(Annotation *annotation in [annotationSet annotations])
	{
		[annotation setStartTime:CMTimeAdd(CMTimeSubtract([annotation startTime],previousDiff), diff)];
		[annotation setEndTime:CMTimeAdd(CMTimeSubtract([annotation endTime],previousDiff), diff)];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DPDataSetRangeChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:DataSourceUpdatedNotification object:self];
	
	[[AnnotationDocument currentDocument] saveAnnotations];
}

-(NSArray*)dataArray
{	
	if(!dataArray)
	{		
		[delegate dataSourceLoadStart];
		[delegate dataSourceLoadStatus:0];
		
		NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:2];
		
		[fileArray addObject:[NSArray arrayWithObjects:@"Transcript Data",@"Annotations",nil]];
		[fileArray addObject:[NSArray arrayWithObjects:@"1",@"1",nil]];
		
		if([[dataFile pathExtension] isEqualToString:@"inqscr"])
		{
			NSLog(@"Load file:%@",dataFile);

			[delegate dataSourceLoadStatus:0.25];
			
			NSStringEncoding enc;
			NSError *error = nil;
			NSString *inqscrData = [[NSString alloc ] initWithContentsOfFile:dataFile usedEncoding:&enc error:&error];
			
			if(error)
			{
				NSLog(@"%@",[error localizedDescription]);
			}
			
			[delegate dataSourceLoadStatus:0.5];
			
			NSArray *lines = [[inqscrData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
							  componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
			
			[inqscrData release];
							
			[delegate dataSourceLoadStatus:0.75];
			
			for(NSString* line in lines)
			{
				if([line rangeOfString:@"text="].location == 0)
				{
					[self parseTranscriptData:[line substringFromIndex:5]];
					break;
				}
			}
		}
		
		[self setDataArray:fileArray];
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
		
		BOOL alreadyIn = NO;
		
		// If this dataSet has already been imported, don't import it again
		for(TimeCodedData *dataSet in dataSets)
		{
			if([variable isEqualToString:[dataSet variableName]])
			{
				[newDataSets addObject:variable];
				alreadyIn = YES;
				break;
			}
		}
		
		if(!alreadyIn)
		{
			if([variable isEqualToString:@"Transcript Data"] && [type isEqualToString:DataTypeTranscript])
			{
				TranscriptData *data = [[TranscriptData alloc] initWithTimeCodedStrings:transcriptStrings];
				[data setSource:self];
				[data setFrameRate:29];
				
				[data setVariableName:variable];
				[newDataSets addObject:data];
				[dataSets addObject:data];
				[data release];
			}
			else if([variable isEqualToString:@"Annotations"] && [type isEqualToString:DataTypeAnnotation])
			{
//				AnnotationSet *data = [[AnnotationSet alloc] init];
//				[data setSource:self];
//				
//				for(Annotation* annotation in [self annotations])
//				{
//					[annotation setSource:[self name]];
//					[data addAnnotation:annotation];
//				}
				
				AnnotationSet *data = [self annotations];
				
				[data setVariableName:variable];
				[newDataSets addObject:data];
				[dataSets addObject:data];
				
				//[data release];
			}
			else
			{
				[newDataSets addObject:[NSNull null]];
			}
		}
	}
	
	return newDataSets;
}

-(void)addAnnotation:(Annotation*)annotation
{
	if(!annotationSet)
	{
		annotationSet = [[AnnotationSet alloc] init];
	}

	[annotation setSource:[self uuid]];
	[annotationSet addAnnotation:annotation];
}

- (AnnotationSet*)annotations
{
	if(!annotationSet)
	{
		[self updateAnnotations];
	}
	return annotationSet;
}

- (void)updateAnnotations
{
	if(annotationSet)
	{
		for(Annotation* annotation in [annotationSet annotations])
		{
			[[AnnotationDocument currentDocument] removeAnnotation:annotation];
		}
		[annotationSet release];
	}
	annotationSet = [[AnnotationSet alloc] init];
	[annotationSet setSource:self];
    
	NSString *sourceName = [self name];
	
	AnnotationCategory* category = [[AnnotationDocument currentDocument] categoryForName:sourceName];
	if(!category)
	{
		category = [[AnnotationDocument currentDocument] createCategoryWithName:sourceName];
		[category setColor:[NSColor colorWithCalibratedRed:0.111 green:0.157 blue:0.810 alpha:1.000]];
	}
	
	for(TimeCodedSourcedString *line in transcriptStrings)
	{
		if([[line source] length] > 0)
		{
			Annotation *annotation = [[Annotation alloc] initWithQTTime:[line time]];
			[annotation setAnnotation:[line string]];
			[annotation setIsDuration:YES];
			[annotation setEndTime:CMTimeAdd([line time], [line duration])];
			
			AnnotationCategory* speakerCategory = [category valueForName:[line source]];
			[annotation setCategory:speakerCategory];
			
			[annotation setSource:[self uuid]];
			[annotationSet addAnnotation:annotation];
			[annotation release];
		}
	}
	
	NSGradient *transcriptColors = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedRed:0.111 green:0.157 blue:0.810 alpha:1.000]
																 endingColor:[NSColor colorWithCalibratedRed:0.733 green:0.103 blue:0.269 alpha:1.000]];
	[category colorValuesByGradient:transcriptColors];
	[transcriptColors release];
	
	//[[AnnotationDocument currentDocument] addAnnotations:annotations];
}


-(BOOL)scanTimeCodeFromScanner:(NSScanner*)theScanner intoTimeInterval:(NSTimeInterval*)timeInterval
{
	int hours;
	int minutes;
	int seconds;
	int frames;
	
	NSString *separator = @":";
	
	NSUInteger startLocation = [theScanner scanLocation];
	
	if ([theScanner scanInt:&hours] &&
		[theScanner scanString:separator intoString:NULL] &&
		[theScanner scanInt:&minutes] &&
		[theScanner scanString:separator intoString:NULL] &&
		[theScanner scanInt:&seconds] && 
		[theScanner scanString:@"." intoString:NULL] &&
		[theScanner scanInt:&frames])
	{
		
		*timeInterval = (hours * 60.0 * 60.0) + (minutes * 60.0) + seconds + ((frames - 1)/transcriptFPS);
		//NSLog(@"Time Interval: %f",(hours * 60.0 * 60.0) + (minutes * 60.0) + seconds + ((frames - 1)/transcriptFPS));
		return YES;
	}
	else
	{
		[theScanner setScanLocation:startLocation];
		return NO;
	}
}

-(void)addObject:(id)obj toRow:(NSMutableArray*)targetRow inMatrix:(NSMutableArray*)matrix
{
	for(NSMutableArray* row in matrix)
	{
		if(row == targetRow)
		{
			[row addObject:obj];
		}
		else
		{
			[row addObject:[NSNull null]];
		}
	}
}

-(NSMutableArray*)interpolateUtterances:(NSMutableArray*)utterances toTime:(NSTimeInterval)endTime
{
	NSMutableArray *results = [NSMutableArray array];
	
	if([utterances count] == 0)
	{
		return results;
	}
	
	NSMutableArray *strings = [NSMutableArray array];
	NSMutableArray* alignment = [NSMutableArray array];
	for(TimeCodedSourcedString* line in utterances)
	{
		[strings addObject:[NSMutableString stringWithString:[[line string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]]];
		[alignment addObject:[NSMutableArray array]];
	}
	
	NSTimeInterval startTime;
	startTime = CMTimeGetSeconds([[utterances objectAtIndex:0] time]);
	
	// First match up utterances
	int index;
	int matchIndex;
	BOOL needsMatch;
	for(index = 0; index < [strings count]; index++)
	{
		needsMatch = NO;
		NSMutableString *string = [strings objectAtIndex:index];
		if([string length] == 0)
		{
			continue;
		}
		
		NSMutableArray *lineArray = [alignment objectAtIndex:index];
		NSRange bracketRange = [string rangeOfString:@"["];
		if(bracketRange.location != NSNotFound)
		{
			needsMatch = YES;
			if(bracketRange.location > 0)
			{
				[self addObject:[[string substringToIndex:bracketRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
						  toRow:lineArray
					   inMatrix:alignment];
			}
			[string deleteCharactersInRange:NSMakeRange(0, bracketRange.location + 1)];
			
			while(needsMatch)
			{
				bracketRange = [string rangeOfString:@"["];
				if(bracketRange.location != NSNotFound)
				{
					[self addObject:[string substringToIndex:bracketRange.location] toRow:lineArray inMatrix:alignment];
					[string deleteCharactersInRange:NSMakeRange(0, bracketRange.location + 1)];
				}
				else
				{
					[self addObject:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] toRow:lineArray inMatrix:alignment];
					[string setString:@""];
					needsMatch = NO;
				}
				
				for(matchIndex = index + 1; matchIndex < [strings count]; matchIndex++)
				{
					NSMutableString *nextString = [strings objectAtIndex:matchIndex];
					NSRange matchedBracketRange = [nextString rangeOfString:@"["];
					if(matchedBracketRange.location != NSNotFound)
					{
						[nextString deleteCharactersInRange:NSMakeRange(0, matchedBracketRange.location + 1)];
						NSRange matchedBracketRange = [nextString rangeOfString:@"["];
						NSString *match;
						if(matchedBracketRange.location != NSNotFound)
						{
							match = [nextString substringToIndex:matchedBracketRange.location];
							[nextString deleteCharactersInRange:NSMakeRange(0, matchedBracketRange.location)];
						}
						else
						{
							match = [nextString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
							[nextString setString:@""];
						}
						
						NSMutableArray *matchedLineArray = [alignment objectAtIndex:matchIndex];
						[matchedLineArray removeLastObject];
						[matchedLineArray addObject:match];
						break;
					}
				}	
			}
			
		}
		else
		{
			[self addObject:[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] toRow:lineArray inMatrix:alignment];
			[string setString:@""];
		}
	}
	
	// Next, create TimeCodedSourcedStrings
	NSTimeInterval duration = endTime - startTime;
	float maxLengths[20];
	float totalLength = 0;
	float currentMax = 0;
	int rowIndex = 0;
	int colIndex = 0;
	for(colIndex = 0; colIndex < [[alignment objectAtIndex:0] count]; colIndex++)
	{
		currentMax = 0;
		for(rowIndex = 0; rowIndex < [alignment count]; rowIndex++)
		{
			id utterance = [[alignment objectAtIndex:rowIndex] objectAtIndex:colIndex];
			if(utterance != [NSNull null])
			{
				currentMax = fmax([(NSString*)utterance length],currentMax);
			}
		}
		maxLengths[colIndex] = currentMax;
		totalLength += currentMax;
	}
	
	rowIndex = 0;
	for(NSMutableArray *row in alignment)
	{
		NSTimeInterval currentTime = startTime;
		colIndex = 0;
		for(id utterance in row)
		{
			CMTime columnStart = CMTimeMakeWithSeconds(currentTime, 600);
			CMTime columnDuration = CMTimeMakeWithSeconds((maxLengths[colIndex]/totalLength)*duration, 600);
			if(utterance != [NSNull null])
			{
				TimeCodedSourcedString *original = [utterances objectAtIndex:rowIndex];
				TimeCodedSourcedString *tcss = [[TimeCodedSourcedString alloc] init];
				tcss.time = columnStart;
				if(currentTime != startTime)
				{
					tcss.interpolated = YES;
				}
				tcss.duration = columnDuration;
				tcss.source = original.source;
				tcss.string = (NSString*)utterance;
				[results addObject:tcss];
				[tcss release];	
			}
			currentTime += (maxLengths[colIndex]/totalLength)*duration;
			colIndex++;
		}
		rowIndex++;
	}
	
	return results;
}


		 
-(NSArray*)parseTranscriptData:(NSString*)theData {
	
	[transcriptStrings release];
    transcriptStrings = [[NSMutableArray alloc] init];	
	
	NSString* data = [theData stringByReplacingOccurrencesOfString:@"\\r" withString:@"\n"];
	data = [data stringByReplacingOccurrencesOfString:@"\\e" withString:@"="];
	
	NSString *timeCodePrefix = @"[";
	NSString *timeCodePostfix = @"]";
	
    // Get newline character set
	NSCharacterSet *newlineCharacterSet = [NSCharacterSet newlineCharacterSet];
	NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	
    // Characters that are important to the parser
    NSMutableCharacterSet *importantCharactersSetM = (id)[NSMutableCharacterSet characterSetWithCharactersInString:@":"];
    [importantCharactersSetM formUnionWithCharacterSet:newlineCharacterSet];
	NSCharacterSet *importantCharactersSet = [importantCharactersSetM copy];
	
	NSTimeInterval currentStart = -1;
	NSMutableArray *currentTimeSegment = [NSMutableArray array];
	
	NSCharacterSet *timeCodeStart = [NSCharacterSet characterSetWithCharactersInString:@"["];
	
    // Create scanner, and scan string
    NSScanner *scanner = [NSScanner scannerWithString:data];
    [scanner setCharactersToBeSkipped:nil];
	NSString *tempString = nil;
	NSTimeInterval tempTime;
	NSMutableString *currentUtterance = [NSMutableString string];
	NSString *currentSpeaker = nil;
	
	[scanner scanUpToCharactersFromSet:timeCodeStart intoString:&tempString];
	[scanner scanString:timeCodePrefix intoString:NULL];
	[self scanTimeCodeFromScanner:scanner intoTimeInterval:&currentStart];
	[scanner scanString:timeCodePostfix intoString:NULL];
	[scanner scanCharactersFromSet:whitespaceCharacterSet intoString:NULL];
	
    while ( ![scanner isAtEnd] ) {        
		
		if([scanner scanString:timeCodePrefix intoString:&tempString])
		{
			if([self scanTimeCodeFromScanner:scanner intoTimeInterval:&tempTime])
			{
				[scanner scanString:timeCodePostfix intoString:NULL];
				[scanner scanCharactersFromSet:whitespaceCharacterSet intoString:NULL];
				if(interpolate)
				{
					NSArray *results = [self interpolateUtterances:currentTimeSegment toTime:tempTime];
					if([results count] > 0)
					{
						[transcriptStrings addObjectsFromArray:results];
					}
					else
					{
						TimeCodedSourcedString *tcss = [[TimeCodedSourcedString alloc] init];
						tcss.time = CMTimeMakeWithSeconds(currentStart, 600);
						tcss.duration = kCMTimeZero;
						tcss.source = @"";
						tcss.string = @"";
						[transcriptStrings addObject:tcss];
						[tcss release];	
					}
			
				}
				else
				{
					[transcriptStrings addObjectsFromArray:currentTimeSegment];
				}
				
				[currentTimeSegment removeAllObjects];
				currentStart = tempTime;
				currentSpeaker = nil;
			}
			else
			{
				[currentUtterance appendString:tempString];
			}
		}
		else if([scanner scanCharactersFromSet:newlineCharacterSet intoString:&tempString])
		{
			if([scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&tempString])
			{
				[currentUtterance appendString:@"\n"];
				//[currentUtterance appendString:tempString];
			}
			else
			{
				if(currentSpeaker)
				{
					TimeCodedSourcedString* currentString = [[TimeCodedSourcedString alloc] init];
					[currentString setTime:CMTimeMakeWithSeconds(currentStart, 600)];
					[currentString setString:[NSString stringWithString:currentUtterance]];
					[currentString setSource:currentSpeaker];
					[currentUtterance setString:@""];
					
					[currentTimeSegment addObject:currentString];
					[currentString release];
					currentSpeaker = nil;
					
					if(CMTIME_COMPARE_INLINE(range.duration, <, [currentString time]))
					{
						range.duration = [currentString time];
					}
				}
				
//				[scanner scanUpToCharactersFromSet:importantCharactersSet intoString:&tempString];
//				currentSpeaker = tempString;
			}
		} 
		else if([scanner scanUpToCharactersFromSet:importantCharactersSet intoString:&tempString])
		{
			if(!currentSpeaker)
			{
				[scanner scanCharactersFromSet:importantCharactersSet intoString:NULL];
				currentSpeaker = tempString;
			}
			else
			{
				[currentUtterance appendString:tempString];
			}
		}
		else if([scanner scanUpToCharactersFromSet:newlineCharacterSet intoString:&tempString])
		{
			[currentUtterance appendString:tempString];
		}

        
    }
	
	// Take care of any last utterances
	
	if(currentSpeaker && ([currentUtterance length] > 0))
	{
		TimeCodedSourcedString* currentString = [[TimeCodedSourcedString alloc] init];
		[currentString setTime:CMTimeMakeWithSeconds(currentStart, 600)];
		[currentString setString:[currentUtterance copy]];
		[currentString setSource:currentSpeaker];
		[currentUtterance setString:@""];
		
		[currentTimeSegment addObject:currentString];
		[currentString release];
	}
	
	if([currentTimeSegment count] > 0)
	{
		if(interpolate)
		{
			NSArray *results = [self interpolateUtterances:currentTimeSegment toTime:(tempTime + 1)];
			if([results count] > 0)
			{
				[transcriptStrings addObjectsFromArray:results];
			}
			else
			{
				TimeCodedSourcedString *tcss = [[TimeCodedSourcedString alloc] init];
				tcss.time = CMTimeMakeWithSeconds(currentStart, 600);
				tcss.duration = kCMTimeZero;
				tcss.source = @"";
				tcss.string = @"";
				[transcriptStrings addObject:tcss];
				[tcss release];	
			}
			
		}
		else
		{
			[transcriptStrings addObjectsFromArray:currentTimeSegment];
		}
	}
	
    [importantCharactersSet release];
    
	return transcriptStrings;
}


@end
