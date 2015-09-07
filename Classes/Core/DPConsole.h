//
//  DPConsole.h
//  DataPrism
//
//  Created by Adam Fouse on 6/23/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const DPConsoleChangedNotification;

@interface DPConsole : NSObject {

	NSMutableArray *entries;
	NSMutableString *currentText;
	
	NSMutableArray *taskPipes;
	NSMutableArray *readHandles;
	NSMutableArray *tasks;
	
}

+ (DPConsole*)defaultConsole;
+ (void)defaultConsoleEntry:(NSString*)value;

- (void)addConsoleEntry:(NSString*)value;

- (void)attachTaskOutput:(NSTask*)task;

- (NSArray*)consoleEntries;
- (NSString*)consoleText;

@end
