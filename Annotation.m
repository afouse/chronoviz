//
//  Annotation.m
//  Annotation
//
//  Created by Adam Fouse on 6/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Annotation.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "AnnotationCategory.h"
#import "DataPrismLog.h"
#import "NSColorHexadecimalValue.h"
#import "NSStringTimeCodes.h"

NSString * const AnnotationUpdatedNotification = @"AnnotationUpdatedNotification";
NSString * const AnnotationSelectedNotification = @"AnnotationSelectedNotification";

@implementation Annotation

@synthesize keyframeImage;
@synthesize source;
@synthesize isDuration;
@synthesize title;
@synthesize image;
@synthesize color;
@synthesize textColor;
@synthesize isCategory;
@synthesize caption;
@synthesize annotation;
@synthesize xmlRepresentation;
@synthesize frameRepresentation;
@synthesize document;
@synthesize creationDate;
@synthesize modificationDate;
@synthesize creationUser;
@synthesize modificationUser;

static NSDictionary* colorMap = nil;

-(id)initWithTimeInterval:(NSTimeInterval)interval
{
	return [self initWithQTTime:QTMakeTimeWithTimeInterval(interval) andTitle:@"" andAnnotation:@""];
}

-(id)initWithStart:(NSDate *)time sinceDate:(NSDate*)referenceDate
{
	QTTime qttime = QTMakeTimeWithTimeInterval([time timeIntervalSinceDate:referenceDate]);
	return [self initWithQTTime:qttime andTitle:@"" andAnnotation:@""];
}

-(id)initWithQTTime:(QTTime)time
{
	return [self initWithQTTime:time andTitle:@"" andAnnotation:@""];
}

//-(id)initWithQTTime:(QTTime)time andTitle:(NSString *)theTitle andAnnotation:(NSString *)theAnnotation;
//{
//	double timepoint = ((double)time.timeValue)/((double)time.timeScale);
//	NSDate *theStart = [[[NSDate alloc] initWithTimeInterval:timepoint sinceDate:defaultReferenceDate] autorelease];
//	
//	Annotation* ann = [self initWithStart:theStart andTitle:theTitle andAnnotation:theAnnotation];
//	//[ann setStartTime:time];
//	
//	return ann;
//}

-(id)initWithQTTime:(QTTime)time andTitle:(NSString *)theTitle andAnnotation:(NSString *)theAnnotation
{
	self = [super initAtTime:time];
	if (self != nil) {
		[self setIsDuration:NO];
		// Don't need extra logic (notifications, undo) during initialization
		//[self setStartTime:time];
		startTime = time;
		endTime = time;
		[self setTitle:theTitle];
		[self setAnnotation:theAnnotation];
		[self setImage:nil];
		[self setColor:nil];
		[self setCategory:nil];
		[self setTextColor:nil];
		[self setCaption:nil];
		[self setSource:nil];
		[self setKeyframeImage:YES];
		[self setFrameRepresentation:nil];
		[self setColorObject:nil];
		categories = [[NSMutableArray alloc] init];
		keywords = [[NSMutableArray alloc] init];
		selected = NO;
	}
	return self;
}


- (void) dealloc
{
	//[start release];
	//[end release];
	//[referenceDate release];
	[annotation release];
	[caption release];
	[title release];
	[image release];
	[color release];
	[textColor release];
	[source release];
	//[category release];
	[frameRepresentation release];
	[categories release];
	[keywords release];
	[super dealloc];
}

#pragma mark Times

-(QTTime)time
{
	return startTime;
}

-(QTTimeRange)range
{
	if(isDuration)
	{
		//return QTMakeTimeRange(startTime,QTTimeDecrement(endTime, startTime));
		return QTMakeTimeRange(startTime, QTMakeTime(endTime.timeValue - startTime.timeValue, startTime.timeScale));	
	}
	else
	{
		return QTMakeTimeRange(startTime, QTMakeTime(0,startTime.timeScale));
	}
}

-(void)setStartTime:(QTTime)qttime
{
	if(QTTimeCompare(startTime,qttime) != NSOrderedSame)
	{
		[self willChangeValueForKey:@"startTime"];
        [self willChangeValueForKey:@"startTimeString"];
		[self willChangeValueForKey:@"start"];
		
		NSUndoManager* undoManager = [[AppController currentApp] undoManager];
		[[undoManager prepareWithInvocationTarget:self] setStartTime:startTime];
		[undoManager setActionName:@"Change Annotation Position"];
		
		DataPrismLog* log = [[AppController currentApp] interactionLog];
		[log addEditOfAnnotation:self forAttribute:@"StartTime" withTime:qttime];
		
		startTime = qttime;
		
		//startTime = QTMakeTimeScaled(qttime, startTime.timeScale);
		//double timepoint = ((double)qttime.timeValue)/((double)qttime.timeScale);
		//[start release];
		//start = [[NSDate alloc] initWithTimeInterval:timepoint sinceDate:[self referenceDate]];
		
		if(![self isDuration])
		{
			//[end release];
			//end = [start retain];
			endTime = startTime;
		}
		
		[self didChangeValueForKey:@"start"];
        [self didChangeValueForKey:@"startTimeString"];
		[self didChangeValueForKey:@"startTime"];
		
		[self setUpdated];
	}
}

-(void)setEndTime:(QTTime)qttime
{
	if(QTTimeCompare(endTime,qttime) != NSOrderedSame)
	{
		[self willChangeValueForKey:@"endTime"];
        [self willChangeValueForKey:@"endTimeString"];
		[self willChangeValueForKey:@"end"];
		
		NSUndoManager* undoManager = [[AppController currentApp] undoManager];
		[[undoManager prepareWithInvocationTarget:self] setEndTime:endTime];
		[undoManager setActionName:@"Change Annotation Position"];
		
		DataPrismLog* log = [[AppController currentApp] interactionLog];
		[log addEditOfAnnotation:self forAttribute:@"EndTime" withTime:qttime];
		
		endTime = QTMakeTimeScaled(qttime,startTime.timeScale);
		//double timepoint = ((double)qttime.timeValue)/((double)qttime.timeScale);
		//[end release];
		//end = [[NSDate alloc] initWithTimeInterval:timepoint sinceDate:[self referenceDate]];
		
		[self didChangeValueForKey:@"end"];
        [self didChangeValueForKey:@"endTimeString"];
		[self didChangeValueForKey:@"endTime"];
		
		[self setUpdated];
	}		
}

-(QTTime)startTime
{
	return startTime;
}


-(QTTime)endTime
{
	return endTime;
}

-(void)setStartTimeString:(NSString *)startTimeString
{
    NSTimeInterval seconds = [startTimeString timeInterval];
    [self setStartTime:QTMakeTimeWithTimeInterval(seconds)];
}

-(void)setEndTimeString:(NSString *)endTimeString
{
    NSTimeInterval seconds = [endTimeString timeInterval];
    [self setEndTime:QTMakeTimeWithTimeInterval(seconds)];
}

- (NSString*)startTimeString
{
    return [NSString stringWithQTTime:[self startTime]];
}

- (NSString*)endTimeString
{
    return [NSString stringWithQTTime:[self endTime]];
}

- (NSTimeInterval)startTimeSeconds
{
	NSTimeInterval startTimeInterval;
	QTGetTimeInterval([self startTime], &startTimeInterval);
	return startTimeInterval;
}

- (NSTimeInterval)endTimeSeconds
{
	NSTimeInterval endTimeInterval;
	QTGetTimeInterval([self endTime], &endTimeInterval);
	return endTimeInterval;
}


#pragma mark Categories

-(AnnotationCategory*)category
{
	if([categories count] > 0)
	{
		return [categories objectAtIndex:0];
	}
	else
	{
		return nil;
	}
}

-(void)setCategory:(AnnotationCategory*)theCategory
{
	[[self category] removeObserver:self forKeyPath:@"color"];
	
	if(theCategory)
	{
		if([categories containsObject:theCategory])
		{
			if([categories indexOfObject:theCategory] != 0)
			{
				[theCategory retain];
				[categories removeObject:theCategory];
				[categories insertObject:theCategory atIndex:0];
				[theCategory release];
			}
		}
		else if([categories count] == 1)
		{
			[categories replaceObjectAtIndex:0 withObject:theCategory];
		}
		else
		{
			[categories insertObject:theCategory atIndex:0];
		}
		
		[theCategory addObserver:self forKeyPath:@"color" options:0 context:NULL];
		 
	}
	else
	{
		[categories removeAllObjects];
	}
	[self setUpdated];
}

-(NSArray*)categories
{
	return categories;
}

-(void)addCategory:(AnnotationCategory*)theCategory
{
	if(![categories containsObject:theCategory])
	{
		if([categories count] == 0)
		{
			[self setCategory:theCategory];
		}
		else
		{
			[categories addObject:theCategory];
		}
	}
	[self setUpdated];
}

-(void)removeCategory:(AnnotationCategory*)theCategory;
{
	[theCategory retain];
	BOOL newCategory = ([self category] == theCategory);
	[categories removeObject:theCategory];
	if(newCategory)
	{
		[self setUpdated];
	}
	
//	if([self category] == theCategory)
//	{
//		if([categories count] > 0)
//			[self setCategory:[categories objectAtIndex:0]];
//		else
//			[self setCategory:nil];
//	}
	[theCategory release];
}

-(void)replaceCategory:(AnnotationCategory*)oldCategory withCategory:(AnnotationCategory*)newCategory
{
	NSUInteger index = [categories indexOfObject:oldCategory];
	if(index == 0)
	{
		[self setCategory:newCategory];
		[self removeCategory:oldCategory];
	}
	else
	{
		[categories replaceObjectAtIndex:index withObject:newCategory];
	}
}

#pragma mark Keywords

-(void)addKeyword:(NSString*)keyword
{
	if(![(AnnotationDocument*)document keywordExists:keyword])
	{
		[(AnnotationDocument*)document addKeyword:keyword];
	}
	[keywords addObject:keyword];
	[self setUpdated];
}


-(void)removeKeyword:(NSString*)keyword
{
	[keywords removeObject:keyword];
	[self setUpdated];
}

-(NSArray*)keywords
{
	return keywords;
}

-(void)setKeywords:(NSArray*)theKeywords
{
	[keywords removeAllObjects];
	for(NSString *keyword in theKeywords)
	{
		[self addKeyword:keyword];
	}
}

- (void)setSelected:(BOOL)isSelected
{
	selected = isSelected;
	[[NSNotificationCenter defaultCenter] 
	 postNotificationName:AnnotationSelectedNotification object:self];		
}

- (BOOL)selected
{
	return selected;
}

- (void)setUpdated
{
	[self setModificationDate:[NSDate date]];
	[self setModificationUser:[[NSUserDefaults standardUserDefaults] stringForKey:AFUserNameKey]];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:AnnotationUpdatedNotification object:self];
}


- (NSColor*)colorObject
{
	if(isCategory)
	{
		if(!colorObject)
		{
			[self setColorObject:[Annotation colorForString:color]];
		}
		return colorObject;
	}
	else if([self category])
	{
		return [[self category] color];
	}
	else if(color)
	{
		return [Annotation colorForString:color];
	}
	else if(textColor)
	{
		return [Annotation colorForString:textColor];
	}
	else
	{
		//return nil;
		return [NSColor grayColor];
	}
	
}

- (void)setColorObject:(NSColor*)colorObj
{
	if(colorObj)
	{
		[colorObj retain];
		[colorObject release];
		colorObject = colorObj;
		if(isDuration)
		{
			[self setColor:[colorObj hexadecimalValueOfAnNSColor]];
		}
		else
		{
			[self setTextColor:[colorObj hexadecimalValueOfAnNSColor]];
		}

	}
	else
	{
		[colorObject release];
		[self setColor:nil];
		[self setTextColor:nil];
		colorObject = nil;
	}
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ((object == [self category]) && [keyPath isEqual:@"color"])
	{
		[self setUpdated];
    }
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}

//+ (void)setDefaultReferenceDate:(NSDate *)date
//{
//	[date retain];
//	[defaultReferenceDate release];
//	defaultReferenceDate = date;
//}

//+ (NSString*)secondsToString:(double)totalSeconds
//{
//	int minutes = totalSeconds/60;
//	int seconds = totalSeconds - minutes*60;
//	int deciseconds = (totalSeconds - (minutes*60 + seconds)) * 10;
//	
//	return [NSString stringWithFormat:@"%02i:%02i.%i",minutes,seconds,deciseconds];
//}
//
//+ (NSString*)timeToString:(QTTime)time
//{
//	float totalSeconds = (float)time.timeValue/(float)time.timeScale;
//	int minutes = totalSeconds/60;
//	int seconds = totalSeconds - minutes*60;
//	int deciseconds = roundf((totalSeconds - (minutes*60 + seconds)) * 10);
//	
//	if(deciseconds == 10)
//	{
//		seconds++;
//		deciseconds = 0;
//	}
//	
//	if(minutes > 90)
//	{
//		int hours = minutes/60;
//		minutes = minutes - (hours*60);
//		return [NSString stringWithFormat:@"%02i:%02i:%02i.%i",hours,minutes,seconds,deciseconds];
//	}
//	
//	return [NSString stringWithFormat:@"%02i:%02i.%i",minutes,seconds,deciseconds];
//}

+ (NSColor*)colorForString:(NSString*)colorName
{
	if(colorMap == nil)
	{
		NSArray* colors = [NSArray arrayWithObjects:
						   [NSColor redColor],
						   [NSColor blueColor],
						   [NSColor greenColor],
						   [NSColor orangeColor],
						   [NSColor yellowColor],
						   nil];
		NSArray* colorNames = [NSArray arrayWithObjects:
							  @"Red",
							  @"Blue",
							  @"Green",
							  @"Orange",
							  @"Yellow",
							  nil];
		colorMap = [[NSDictionary dictionaryWithObjects:colors forKeys:colorNames] retain];
	}
	
	if([colorName characterAtIndex:0] == '#')
	{
		return [NSColor colorFromHexRGB:colorName];
	} 
	else
	{
	 	NSColor* color = [colorMap objectForKey:colorName];
		if(color == nil) color = [NSColor blackColor];
		return color;	
	}
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
	BOOL automatic = NO;
	
    if ([theKey isEqualToString:@"startTime"] 
		|| [theKey isEqualToString:@"start"]
		|| [theKey isEqualToString:@"endTime"]
		|| [theKey isEqualToString:@"end"]
        || [theKey isEqualToString:@"startTimeString"]
		|| [theKey isEqualToString:@"endTimeString"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}

@end
