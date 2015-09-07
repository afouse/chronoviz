//
//  InteractionLog.m
//  Annotation
//
//  Created by Adam Fouse on 11/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InteractionLog.h"
#import "Interaction.h"
#import "InteractionSpeedChange.h"
#import "InteractionAddSegment.h"
#import "InteractionJump.h"
#import "InteractionAnnotationEdit.h"
#import "DPApplicationSupport.h"
#import "Annotation.h"

int const AFInteractionType = 1;
int const AFInteractionTypeSpeedChange = 2;
int const AFInteractionTypeAddSegment = 3;
int const AFInteractionTypeJump = 4;
int const AFInteractionTypeTimelineClick = 5;
int const AFInteractionTypeNextPrompt = 6;
int const AFInteractionTypeAnnotationEdit = 7;

@implementation InteractionLog

static NSString *logsDirectory = nil;

@synthesize isPlaying;
@synthesize currentPlaybackTime;
@synthesize playbackDuration;

- (id)init
{
	[super init];
	interactions = [[NSMutableArray alloc] init];
	startTime = [[NSDate date] retain];
	isPlaying = NO;
	timeScale = 600;
	visualizerType = -1;
	return self;
}

- (void)dealloc
{
	[interactions release];
	[startTime release];
	[super dealloc];
}

- (void)reset
{
	[interactions removeAllObjects];
	visualizerType = -1;
	[self startClock];
}

- (void)addInteraction:(Interaction*)interaction
{
	[interactions addObject:interaction];
}

- (InteractionSpeedChange*)addSpeedChange:(float)speed atTime:(QTTime)time
{
	if(isPlaying)
		return nil;
	
	InteractionSpeedChange *interaction = [[InteractionSpeedChange alloc] initWithSpeed:speed andMovieTime:time atTime:[self sessionTime]];
	[interactions addObject:interaction];
	[interaction release];
	return interaction;
}

- (InteractionAddSegment*)addSegmentationPoint:(QTTime)time
{
	if(isPlaying)
		return nil;
	
	InteractionAddSegment *interaction = [[InteractionAddSegment alloc] initWithMovieTime:time andSessionTime:[self sessionTime]];
	[interactions addObject:interaction];
	[interaction release];
	return interaction;
}

- (InteractionJump*)addJumpFrom:(QTTime)fromTime to:(QTTime)toTime
{
	if(isPlaying)
		return nil;
	
	InteractionJump *jump = [[InteractionJump alloc] initWithFromMovieTime:fromTime toMovieTime:toTime andSessionTime:[self sessionTime]];
	[interactions addObject:jump];
	[jump release];
	return jump;
}

- (InteractionAnnotationEdit*)addEditOfAnnotation:(Annotation*)annotation forAttribute:(NSString*)attribute withTime:(QTTime)value
{
	return [self addEditOfAnnotation:annotation forAttribute:attribute withValue:[NSValue valueWithQTTime:value]];
}

- (InteractionAnnotationEdit*)addEditOfAnnotation:(Annotation*)annotation forAttribute:(NSString*)attribute withValue:(NSObject*)value
{
	InteractionAnnotationEdit *edit = [[InteractionAnnotationEdit alloc] initWithAnnotation:annotation
																			   forAttribute:attribute
																				  withValue:value
																			 andSessionTime:[self sessionTime]];
	[interactions addObject:edit];
	[edit release];
	return edit;
}

- (NSArray *)getSegmentationPoints
{
	NSMutableArray *array = [NSMutableArray array];
	for(Interaction *interaction in interactions)
	{
		if([interaction isKindOfClass:[InteractionAddSegment class]])
		{
			[array addObject:interaction];
		}
	}
	return array;
}

- (NSMutableArray *)interactions
{
	return interactions;
}

- (void)startClock
{
	NSDate* oldTime = startTime;
	startTime = [[NSDate date] retain];
	[oldTime release];
}

- (double)sessionTime
{
	return [[NSDate date] timeIntervalSinceDate:startTime];
}

- (void)setTimeScale:(int)scale
{
	//NSLog(@"Set time scale: %i",scale);
	timeScale = scale;
}

+ (NSString*)defaultLogsDirectory
{
	if(logsDirectory == nil)
	{
		NSArray *paths;
		NSError *error;
		NSFileManager *mgr = [NSFileManager defaultManager];
		paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
		
		NSString *oldFolder = [[[paths objectAtIndex:0] 
							 stringByAppendingPathComponent:@"UCSD"]
							stringByAppendingPathComponent:@"Annotation"];
		
		NSString *folder = [[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"Logs"];
		
		NSLog(@"Logs folder: %@",folder);
		
		if ([mgr fileExistsAtPath:oldFolder])
		{
			NSError *err = nil;
			BOOL result = [mgr moveItemAtPath:oldFolder toPath:folder error:&err];
			if(!result)
			{
				NSAlert *alert = [NSAlert alertWithError:err];
				[alert runModal];
			}
		}
			 
		if(![mgr fileExistsAtPath:folder])
		{
			[mgr createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error];
		}
		
		logsDirectory = [folder retain];
	}
	
	return logsDirectory;
}

- (BOOL)saveToDefaultFile
{

    NSString *folder = [InteractionLog defaultLogsDirectory];
	NSString *format = @"%Y-%m-%d-%H-%M-%S.txt";
	NSString *file = [folder stringByAppendingPathComponent:[startTime descriptionWithCalendarFormat:format timeZone:nil locale:nil]];
	
	return [self saveToFile:file];
}

- (BOOL)saveToFile:(NSString*) filename
{
	int capacity = [interactions count] * 15;
	NSMutableString * output = [NSMutableString stringWithCapacity:capacity];
	NSEnumerator *allInteractions = [interactions objectEnumerator];
	Interaction* interaction;
	
//	[output appendString:[NSString stringWithFormat:@"video %@\n",[[app movieFileName] lastPathComponent]]];
	
	while(interaction = [allInteractions nextObject]) {
		[output appendString:[interaction logOutput]];
		//[output appendFormat:@"%1.2f %1.2f %qi\n",[speedChange sessionTime],[speedChange speed],[speedChange movieTime].timeValue];
	}
	
	return [output writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:NULL];		 
}

- (void)readFromFile:(NSString*) filename
{
	NSLog(@"Read interaction log: %@",filename);
	NSError *error;
	NSString *savedLog = [[NSString alloc] initWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
	
	NSMutableArray *result	= [NSMutableArray array];
	NSRange range = NSMakeRange(0,0);
	unsigned start, end;
	unsigned contentsEnd = 0;
		
	while (contentsEnd < [savedLog length])
	{
		[savedLog getLineStart:&start end:&end contentsEnd:&contentsEnd forRange:range];
		[result addObject:[savedLog substringWithRange:NSMakeRange(start,contentsEnd-start)]];
		range.location = end;
		range.length = 0;
	}
	
	if([result count] > 0) {
		[self reset];
	} else {
		[savedLog release];
		return;
	}
	
	for (NSString* interactionString in result)
	{
		NSArray *elements = [interactionString componentsSeparatedByString:@" "];
		NSString *type = [elements objectAtIndex:0];
		if([type isEqualToString:[InteractionSpeedChange typeString]])
		{
			//NSLog(@"input: %@",elements);
			double sessionTime = [(NSString *)[elements objectAtIndex:1] doubleValue];
			float speed = [(NSString *)[elements objectAtIndex:2] floatValue];
			long long time = [(NSString *)[elements objectAtIndex:3] longLongValue];
			QTTime qttime = QTMakeTime(time, timeScale);
			
			InteractionSpeedChange *speedChange = [[InteractionSpeedChange alloc] initWithSpeed:speed andMovieTime:qttime atTime:sessionTime];
			//NSLog(@"output: %@",speedChange);
			[interactions addObject:speedChange];
			[speedChange release];
		} else if ([type isEqualToString:[InteractionJump typeString]])
		{
			double sessionTime = [(NSString *)[elements objectAtIndex:1] doubleValue];
			long long fromTime = [(NSString *)[elements objectAtIndex:2] longLongValue];
			long long toTime = [(NSString *)[elements objectAtIndex:3] longLongValue];
			
			InteractionJump *jump = [[InteractionJump alloc]
									 initWithFromMovieTime:QTMakeTime(fromTime, timeScale) 
									 toMovieTime:QTMakeTime(toTime, timeScale)
									 andSessionTime:sessionTime];
			[interactions addObject:jump];
			[jump release];
		} else if([type isEqualToString:[InteractionAddSegment typeString]])
		{
			//NSLog(@"input: %@",elements);
			//double sessionTime = [(NSString *)[elements objectAtIndex:1] doubleValue];
			long long time = [(NSString *)[elements objectAtIndex:2] longLongValue];
			QTTime qttime = QTMakeTime(time, timeScale);
			
			// Init with sessionTime set to 0, because otherwise it interferes with playback.
			// There doesn't seem to be any reason why the segments need a sessionTime, but this may need to be fixed in the future.
			InteractionAddSegment *segment = [[InteractionAddSegment alloc] initWithMovieTime:qttime andSessionTime:0];
			//NSLog(@"output: %@",segment);
			[interactions addObject:segment];
			[segment release];
		}  else if([type isEqualToString:@"visualizer"])
		{
			visualizerType = [(NSString *)[elements objectAtIndex:1] intValue];
		}
		
		//[elements release];
	}
	
	[savedLog release];
	
	NSLog(@"Load done");
}

#pragma mark Playback

/*
- (void)playback:(AppController *)theApp
{
	// Keep the app pointer around
	app = theApp;
	
	// Make sure the interactions are sorted by session time;
	NSSortDescriptor *timeDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"sessionTime"
																	ascending:YES] autorelease];
	NSArray *sortDescriptors = [NSArray arrayWithObject:timeDescriptor];
	[interactions sortUsingDescriptors:sortDescriptors];
	
	// Add a 5 second to the end of the playback to allow for extra audio recording
	// Update: Not needed if we don't automatically close when we get to the end
	
	 //Interaction *last = [interactions lastObject];
	 //InteractionAddSegment *final = [[InteractionAddSegment alloc] initWithMovieTime:QTMakeTime(0, 0) andSessionTime:([last sessionTime] + 5)];
	 //[interactions addObject:final];
	 //[final release];
	 
	
	
	playbackDuration = [[interactions lastObject] sessionTime];
	
	if(visualizerType > 0)
	{
	}
	
	// Set the playback clock
	playbackStart = [[NSDate date] retain];
	currentPlaybackTime = 0;
	interactionIndex = 0;
	[self setIsPlaying:YES];
	
	// Start playback
	timer = [NSTimer scheduledTimerWithTimeInterval:0.05
											 target:self
										   selector:@selector(updatePlayback:)
										   userInfo:nil
											repeats:YES];
}

- (void)stopPlayback
{
	if(isPlaying)
	{
		NSLog(@"Done with playback");
		[timer invalidate];
		[self setIsPlaying:NO];
		[playbackStart release];
		//[app playbackDone];
	}
}

- (void)updatePlayback:(NSTimer *)aTimer
{
	if(isPlaying)
	{
		
		if(interactionIndex < [interactions count])
		{
			currentPlaybackTime = [[NSDate date] timeIntervalSinceDate:playbackStart];
			Interaction *action = [interactions objectAtIndex:interactionIndex];
			while([action sessionTime] <= currentPlaybackTime)
			{
				//NSLog(@"Playback Time: %f, Interaction: %@",currentPlaybackTime,[action logOutput]);
				if([action type] == AFInteractionTypeSpeedChange)
				{
					InteractionSpeedChange *speedChange = (InteractionSpeedChange*)action;
					[app moveToTime:[speedChange movieTime]];
					[app setRate:[speedChange speed]];
					
				}
				else if([action type] == AFInteractionTypeJump) 
				{
					InteractionJump *jump = (InteractionJump *)action;
					QTTime toMovieTime = [jump toMovieTime];
					[app moveToTime:toMovieTime];
				}
				else if([action type] == AFInteractionTypeNextPrompt) 
				{
				}
				
				interactionIndex++;
				if(interactionIndex < [interactions count])
				{
					action = [interactions objectAtIndex:interactionIndex];
				} else {
					[self stopPlayback];
					return;
				}
			}
		} else {
			[self stopPlayback];
		}
	}
}
*/

@end
