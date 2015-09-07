//
//  DPURLHandler.m
//  ChronoViz
//
//  Created by Adam Fouse on 3/22/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPURLHandler.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "NSString+URIQuery.h"
#import "AnotoViewController.h"
#import "AnotoView.h"
#import <QTKit/QTKit.h>

@implementation DPURLHandler

- (id)initForAppController:(AppController*)controller
{
	self = [super init];
	if (self != nil) {
		app = controller;
		handlers = [[NSMutableDictionary alloc] init];
		[handlers setObject:self forKey:@"time"];
		
		//[handlers setObject:self forKey:@"note"];
		//[handlers setObject:self forKey:@"start_annotation"];
		//[handlers setObject:self forKey:@"end_annotation"];
	}
	return self;
}

- (void) dealloc
{
	app = nil;
	[handlers release];
	[super dealloc];
}


- (void)handleURLEvent:(NSAppleEventDescriptor*)event withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
	NSString *urlString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL* url = [NSURL URLWithString:urlString];
	
	//NSLog(@"Scheme: %@, path: %@, query: %@, param: %@, host: %@",[url scheme],[url path],[url query],[url parameterString],[url host]);
	
	if([[url scheme] isEqualToString:@"dataprism"]
	   || [[url scheme] isEqualToString:@"chronoviz"])
	{
		NSString *command = [url host];
		
		id handler = [handlers objectForKey:command];
		
		if(handler != self)
		{
			[handler handleURLEvent:event withReplyEvent:replyEvent];
		}
		else 
		{
			if([command isEqualToString:@"time"])
			{
                [NSApp arrangeInFront:self];
                
				NSDictionary *params = [[url query] queryDictionaryUsingEncoding:NSUTF8StringEncoding];
				
				NSString *error = [params objectForKey:@"error"];
				if(error)
				{
					NSLog(@"%@",error);
					return;
				}
				
				NSString *file = [params objectForKey:@"file"];
				
				if(file)
				{
					if(![[[app document] annotationsDirectory] isEqualToString:file])
					{
						[app application:NSApp openFile:file];
					}
				}
				
				NSString *frame = [params objectForKey:@"frame"];
				
				if(frame)
				{
					if([frame characterAtIndex:0] == '+')
					{
						[app stepOneFrameForward:self];
					}
					else if([frame characterAtIndex:0] == '-')
					{
						[app stepOneFrameBackward:self];
					}
					return;
				}
				
				NSString *seconds = [params objectForKey:@"seconds"];
				
				if(seconds)
				{
					if(([seconds characterAtIndex:0] == '+') && ([seconds length] > 1))
					{
						NSTimeInterval current;
						QTGetTimeInterval([app currentTime],&current);
						current += [[seconds substringFromIndex:1] floatValue];
						[app moveToTime:QTMakeTimeWithTimeInterval(current) fromSender:urlString];
					}
					else if(([seconds characterAtIndex:0] == '-') && ([seconds length] > 1))
					{
						NSTimeInterval current;
						QTGetTimeInterval([app currentTime],&current);
						current -= [[seconds substringFromIndex:1] floatValue];
						[app moveToTime:QTMakeTimeWithTimeInterval(current) fromSender:urlString];
					}
					else
					{
						[app moveToTime:QTMakeTimeWithTimeInterval([seconds floatValue]) fromSender:urlString];
					}
					return;
				}
				
				NSString *rate = [params objectForKey:@"rate"];
				
				if(rate)
				{
					float newrate = 0;
					
					unichar rateChar = [rate characterAtIndex:0];
					
					if((rateChar == '+') && ([rate length] > 1))
					{
						newrate = [[rate substringFromIndex:1] floatValue];
					}
					else if(rateChar == 'p')
					{
						newrate = [app playbackRate];
					}
					else if(rateChar == 's')
					{
						newrate = 0.0;
					}
					else if(rateChar == 'r')
					{
						newrate = -2.0 * [app playbackRate];
					}
					else if(rateChar == 'f')
					{
						newrate = 2.0 * [app playbackRate];
					}
					else
					{
						newrate = [rate floatValue];
					}
					
					if((newrate == HUGE_VAL) || (newrate == -HUGE_VAL))
					{
						NSLog(@"Error: Can't interpret rate in URL: %@",urlString);
						return;
					}
					
					[app setRate:newrate fromSender:urlString];
					
					return;
				}
				
			}
		}
	}
	
	//	NSArray* components = [url componentsSeparatedByString:@"//"];
	//	QTTime time = [self currentTime];
	//	time.timeValue = [[components objectAtIndex:1] floatValue] * time.timeScale;
	//	[self moveToTime:time];
    //NSLog(@"%@", [url absoluteString]);
}

- (void)registerHandler:(id)handler forCommand:(NSString*)command
{
	if([handler respondsToSelector:@selector(handleURLEvent:withReplyEvent:)])
	{
		[handlers setObject:handler forKey:command];	
	}
}

@end
