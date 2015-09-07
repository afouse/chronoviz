//
//  DataPrismLog.m
//  DataPrism
//
//  Created by Adam Fouse on 7/8/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "DataPrismLog.h"
#import "DPConstants.h"
#import "Interaction.h"
#import "NSStringFileManagement.h"
#import "NSStringMD5.h"
#import "InteractionSpeedChange.h"
#import "InteractionJump.h"
#import "InteractionAddSegment.h"
#import "InteractionAnnotationEdit.h"

@interface DataPrismLog (Internal)

- (void)createNewXMLDocument;
- (void)setStartTime:(NSDate*)theStart;
- (void)setEndTime:(NSDate*)theEnd;
- (void)recordState:(NSTimer*)theTimer;
- (void)screenCapture;

@end

@implementation DataPrismLog

@synthesize userID;
@synthesize documentID;
@synthesize documentDuration;
@synthesize recordTimePosition;
@synthesize recordAnnotationEdits;
@synthesize recordState;

- (id) init
{
	self = [super init];
	if (self != nil) {
		[self createNewXMLDocument];
		[self setUserID:@""];
		[self setDocumentID:@""];
		[self setDocumentDuration:0];
		
		endTime = nil;
		stateSource = nil;
		
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		
		[self setRecordTimePosition:[defaults boolForKey:AFSaveTimePositionKey]];
		[self setRecordAnnotationEdits:[defaults boolForKey:AFSaveAnnotationEditsKey]];
		[self setRecordState:[defaults boolForKey:AFSaveVizConfigKey]];
	}
	return self;
}

- (void) dealloc
{
	[stateSource release];
	[stateTimer invalidate];
	[xmlDoc release];
	[userID release];
	[documentID release];
	[endTime release];
	[super dealloc];
}

- (InteractionSpeedChange*)addSpeedChange:(float)speed atTime:(QTTime)time
{
	if(recordTimePosition)
	{
		return [super addSpeedChange:speed atTime:time];
	}
	return nil;
}

- (InteractionJump*)addJumpFrom:(QTTime)fromTime to:(QTTime)toTime
{
	if(recordTimePosition)
	{
		return [super addJumpFrom:fromTime to:toTime];
	}
	return nil;
}

- (InteractionAddSegment*)addSegmentationPoint:(QTTime)time
{
	if(recordTimePosition)
	{
		return [super addSegmentationPoint:time];
	}
	return nil;
}

- (InteractionAnnotationEdit*)addEditOfAnnotation:(Annotation*)annotation forAttribute:(NSString*)attribute withTime:(QTTime)value
{
	if(recordAnnotationEdits)
	{
		return [super addEditOfAnnotation:annotation forAttribute:attribute withTime:value];
	}
	return nil;
}

- (InteractionAnnotationEdit*)addEditOfAnnotation:(Annotation*)annotation forAttribute:(NSString*)attribute withValue:(NSObject*)value
{
	if(recordAnnotationEdits)
	{
		return [super addEditOfAnnotation:annotation forAttribute:attribute withValue:value];
	}
	return nil;
}

- (void)setStartTime:(NSDate*)theStart
{
	[theStart retain];
	[startTime release];
	startTime = theStart;
}

- (void)setEndTime:(NSDate*)theEnd
{
	[theEnd retain];
	[endTime release];
	endTime = theEnd;
}

- (NSDate*)startTime
{
	return startTime;
}

- (NSDate*)endTime
{
	return endTime;
}

- (NSXMLDocument*)xmlDocument
{
	return xmlDoc;
}

- (void)createNewXMLDocument
{
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"dataprismlog"];
	xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
	
	interactionsElement = [NSXMLElement elementWithName:@"interactions"];
	statesElement = [NSXMLElement elementWithName:@"states"];
	
	[root addChild:interactionsElement];
	[root addChild:statesElement];
	
	stateTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
												  target:self
												selector:@selector(recordState:)
												userInfo:nil
												 repeats:YES];
}

- (void)reset
{
	[super reset];
	[stateTimer invalidate];
	[xmlDoc release];
	xmlDoc = nil;
	[self createNewXMLDocument];
}

- (void)screenCapture
{
	NSTask *task = [[NSTask alloc] init];
	NSString *imageDirectory = [[InteractionLog defaultLogsDirectory] stringByAppendingPathComponent:@"screenCaptures"];
	if([imageDirectory verifyOrCreateDirectory])
	{
		
		[task setCurrentDirectoryPath:imageDirectory];
		[task setLaunchPath:@"/usr/sbin/screencapture"];
		
		NSString* dateFormat = @"%m-%d-%y_%H-%M-%S";
		NSString* filenameFormat = @"DP_screenshot_%@.jpg";
		
		NSString *date = [[NSDate date] descriptionWithCalendarFormat:dateFormat timeZone:nil locale:nil];
		NSMutableArray *arguments = [NSArray arrayWithObjects:
									 @"-x",
									 @"-C",
									 @"-tjpg",
									 [NSString stringWithFormat:filenameFormat,date],nil];
		//NSLog(@"Arguments: %@",[arguments description]);
		[task setArguments:arguments];
		
		//NSLog(@"Screen Capture: %@",[arguments objectAtIndex:0]);
		[task launch];
		
		//[task waitUntilExit];
		[task release];
	
	}
}

-(void)setStateSource:(NSObject<DPStateRecording>*)theSource
{
	[stateSource release];
	stateSource = [theSource retain];
}

- (void)recordState:(NSTimer*)theTimer
{
	
	if(recordState && [NSApp isActive])
	{
		[self addStateData:[stateSource currentState:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:DataPrismLogState]]];	
	}
}

-(void)addStateData:(NSData*)state
{
	NSXMLElement *stateElement = [NSXMLElement elementWithName:@"state"];
	[stateElement setObjectValue:state];
	
	NSNumber *sessionTimeNumber = [NSNumber numberWithDouble:[self sessionTime]];
	NSXMLNode *sessionTimeAttribute = [NSXMLNode attributeWithName:@"sessionTime"
														 stringValue:[sessionTimeNumber stringValue]];
	[stateElement addAttribute:sessionTimeAttribute];
	
	[statesElement addChild:stateElement];
}

- (BOOL)saveToDefaultFile
{	
    NSString *folder = [InteractionLog defaultLogsDirectory];
	NSString *format = @"%Y-%m-%d-%H-%M-%S.xml";
	NSString *file = [folder stringByAppendingPathComponent:[startTime descriptionWithCalendarFormat:format timeZone:nil locale:nil]];
	
	return [self saveToFile:file];
}

- (BOOL)saveToFile:(NSString*) fileName
{
	[self recordState:nil];
	
	NSXMLNode *startTimeAttribute = [[NSXMLNode alloc] initWithKind:NSXMLAttributeKind];
	[startTimeAttribute setName:@"startDate"];
	[startTimeAttribute setObjectValue:startTime];
	[[xmlDoc rootElement] addAttribute:startTimeAttribute];
	[startTimeAttribute release];
	
	NSXMLNode *endTimeAttribute = [[NSXMLNode alloc] initWithKind:NSXMLAttributeKind];
	[endTimeAttribute setName:@"endDate"];
	[endTimeAttribute setObjectValue:[NSDate date]];
	[[xmlDoc rootElement] addAttribute:endTimeAttribute];
	[endTimeAttribute release];
	
	NSXMLNode *userAttribute = [NSXMLNode attributeWithName:@"user" stringValue:userID];
	[[xmlDoc rootElement] addAttribute:userAttribute];
	
	NSXMLNode *docIdAttribute = [NSXMLNode attributeWithName:@"documentID" stringValue:[documentID md5hash]];
	[[xmlDoc rootElement] addAttribute:docIdAttribute];
	
	NSXMLNode *durationAttribute = [NSXMLNode attributeWithName:@"documentDuration" 
													stringValue:[[NSNumber numberWithDouble:documentDuration] stringValue]];
	[[xmlDoc rootElement] addAttribute:durationAttribute];
	
	for(Interaction* interaction in interactions)
	{
		[interactionsElement addChild:[interaction xmlElement]];
	}
	
	NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    if (![xmlData writeToFile:fileName atomically:YES]) {
        NSLog(@"Could not save annotations to file:%@",fileName);
        return NO;
    }
    return YES;
	
}

+ (DataPrismLog*)logFromFile:(NSString*) filename
{
    return [DataPrismLog logFromFile:filename ignoringStates:NO];
}

+ (DataPrismLog*)logFromFile:(NSString*)filename ignoringStates:(BOOL)ignoreStates
{
	NSError *err=nil;
	NSURL *furl = [NSURL fileURLWithPath:filename];
	if (!furl) {
		NSLog(@"Can't create an URL from file %@.", filename);
		return nil;
	}
	NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithContentsOfURL:furl
												  options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
													error:&err];
	if (xmlDocument == nil) {
		xmlDocument = [[NSXMLDocument alloc] initWithContentsOfURL:furl
													  options:NSXMLDocumentTidyXML
														error:&err];
	}
	
	if (err) {
		NSLog(@"Error: %@",[err localizedDescription]);
		//        [self handleError:err];
		return nil;
	}
	
	NSXMLElement *rootElement = [xmlDocument rootElement];
	
	if([[rootElement name] caseInsensitiveCompare:@"dataprismlog"] != NSOrderedSame)
	{
		NSLog(@"Error: Root element not 'dataprismlog'");
		return nil;
	}

	
	DataPrismLog *log = [[[DataPrismLog alloc] init] autorelease];
    log.recordState = NO;
		
	NSString *user = [[rootElement attributeForName:@"user"] stringValue];
	[log setUserID:user];
	
	NSString *doc = [[rootElement attributeForName:@"documentID"] stringValue];
	[log setDocumentID:doc];
	
	NSString *durationString = [[rootElement attributeForName:@"documentDuration"] stringValue];
	[log setDocumentDuration:[durationString doubleValue]];
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
	NSString *startDateString = [[rootElement attributeForName:@"startDate"] stringValue];
	NSString *endDateString = [[rootElement attributeForName:@"endDate"] stringValue];
	[log setStartTime:[formatter dateFromString:startDateString]];
	[log setEndTime:[formatter dateFromString:endDateString]];
    [formatter release];
	
	
	NSArray *interactionsElements = [rootElement elementsForName:@"interactions"];
	for(NSXMLElement *element in interactionsElements)
	{
		for(NSXMLElement *interaction in [element children])
		{
			NSString *type = [interaction name];
			double sessionTime = [[[interaction attributeForName:@"sessionTime"] stringValue] doubleValue];
            
			if([type caseInsensitiveCompare:[InteractionSpeedChange typeString]] == NSOrderedSame)
			{
				float speed = [[[interaction attributeForName:@"speed"] stringValue] floatValue];
				double time = [[[interaction attributeForName:@"movieTime"] stringValue] doubleValue];
				QTTime qttime = QTMakeTimeWithTimeInterval(time);
				
				InteractionSpeedChange *speedChange = [[InteractionSpeedChange alloc] initWithSpeed:speed andMovieTime:qttime atTime:sessionTime];
				[log addInteraction:speedChange];
				[speedChange release];
			}
			else if ([type caseInsensitiveCompare:[InteractionJump typeString]] == NSOrderedSame)
			{
				double fromTime = [[[interaction attributeForName:@"fromTime"] stringValue] doubleValue];
				double toTime = [[[interaction attributeForName:@"toTime"] stringValue] doubleValue];
				
				InteractionJump *jump = [[InteractionJump alloc]
										 initWithFromMovieTime:QTMakeTimeWithTimeInterval(fromTime)
										 toMovieTime:QTMakeTimeWithTimeInterval(toTime)
										 andSessionTime:sessionTime];
				[log addInteraction:jump];
				[jump release];
			}
			else if ([type caseInsensitiveCompare:@"addSegment"] == NSOrderedSame)
			{
                double time = [[[interaction attributeForName:@"movieTime"] stringValue] doubleValue];
				QTTime qttime = QTMakeTimeWithTimeInterval(time);
				
				InteractionAddSegment *segment = [[InteractionAddSegment alloc] initWithMovieTime:qttime andSessionTime:sessionTime];
				[log addInteraction:segment];
				[segment release];
			}
            else if ([type caseInsensitiveCompare:[InteractionAnnotationEdit typeString]] == NSOrderedSame)
			{
                double time = [[[interaction attributeForName:@"annotationTime"] stringValue] doubleValue];
				QTTime qttime = QTMakeTimeWithTimeInterval(time);
                
                NSString *title = [[interaction attributeForName:@"annotationTitle"] stringValue];
                NSString *changedAttribute = [[interaction attributeForName:@"changedAttribute"] stringValue];
				NSString *changedAttributeValue = [[interaction attributeForName:@"changedAttributeValue"] stringValue];
    
                InteractionAnnotationEdit *edit = [[InteractionAnnotationEdit alloc] initWithAnnotationTitle:title
                                                                                                   startTime:qttime
                                                                                                forAttribute:changedAttribute
                                                                                                   withValue:changedAttributeValue
                                                                                              andSessionTime:sessionTime];
				[log addInteraction:edit];
				[edit release];
			}
			
		}
	}
	
    if(!ignoreStates)
    {
        NSArray *statesElements = [rootElement elementsForName:@"states"];
        
        if([statesElements count])
        {
            [(NSXMLNode*)[statesElements objectAtIndex:0] detach];
            [[[[[log xmlDocument] rootElement] elementsForName:@"states"] lastObject] detach];
            [[[log xmlDocument] rootElement] addChild:[statesElements objectAtIndex:0]];
        }
    }
    
	[xmlDocument release];
	
	return log;
}

@end
