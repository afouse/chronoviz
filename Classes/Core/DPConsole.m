//
//  DPConsole.m
//  DataPrism
//
//  Created by Adam Fouse on 6/23/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "DPConsole.h"

NSString * const DPConsoleChangedNotification = @"DPConsoleChangedNotification";

@implementation DPConsole

static DPConsole* defaultConsole = nil;

- (id) init
{
	self = [super init];
	if (self != nil) {
		entries = [[NSMutableArray alloc] init];
		currentText = [[NSMutableString alloc] init];
		taskPipes = [[NSMutableArray alloc] init];
		readHandles = [[NSMutableArray alloc] init];
		tasks = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	if(self == defaultConsole)
	{
		defaultConsole = nil;
	}
	[tasks release];
	[taskPipes release];
	[readHandles release];
	[entries release];
	[currentText release];
	[super dealloc];
}

+ (DPConsole*)defaultConsole
{
	if(!defaultConsole)
	{
		defaultConsole = [[DPConsole alloc] init];
	}
	return defaultConsole;
}

+ (void)defaultConsoleEntry:(NSString*)value
{
	[[DPConsole defaultConsole] addConsoleEntry:value];
}

- (void)addConsoleEntry:(NSString*)value
{
	[entries addObject:value];
	
	[currentText appendFormat:@"%@\n",[value stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:DPConsoleChangedNotification object:self];
}

-(void)attachTaskOutput:(NSTask*)task
{
	NSPipe *newPipe = [[NSPipe pipe] retain];
	[taskPipes addObject:newPipe];
	[tasks addObject:task];
	[newPipe release];
	
	NSFileHandle *readHandle = [newPipe fileHandleForReading];
	[readHandles addObject:readHandle];
	
	[task setStandardOutput:newPipe];
	[task setStandardError:newPipe];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(readFromTask:)
												 name:NSFileHandleReadCompletionNotification
											   object:readHandle];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(taskFinished:)
												 name:NSTaskDidTerminateNotification
											   object:task];
	
	[readHandle readInBackgroundAndNotify];
}

- (void)readFromTask:(NSNotification*)notification
{
	if(![readHandles containsObject:[notification object]])
	{
		return;
	}
	
	NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
	NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
	if([string length] > 0)
	{
		[self addConsoleEntry:string];
	}
	else
	{
		NSLog(@"Read 0");
	}
	
	[(NSFileHandle*)[notification object] readInBackgroundAndNotify];
	
	[string release];
}

- (void)taskFinished:(NSNotification*)notification
{
	NSUInteger index = [tasks indexOfObject:[notification object]];
	if(index != NSNotFound)
	{
		[tasks removeObjectAtIndex:index];
		[taskPipes removeObjectAtIndex:index];
		[readHandles removeObjectAtIndex:index];
	}
}

- (NSArray*)consoleEntries
{
	return [[entries copy] autorelease];
}

- (NSString*)consoleText
{
	return [[currentText copy] autorelease];
}

@end
