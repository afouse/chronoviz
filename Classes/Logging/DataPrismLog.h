//
//  DataPrismLog.h
//  DataPrism
//
//  Created by Adam Fouse on 7/8/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "InteractionLog.h"
#import "DPStateRecording.h"

@interface DataPrismLog : InteractionLog {
	
	NSXMLDocument *xmlDoc;
	NSString *userID;
	NSString *documentID;
	NSTimeInterval documentDuration;
	
	NSXMLElement *interactionsElement;
	NSXMLElement *statesElement;
	
	NSObject<DPStateRecording> *stateSource;
	
	NSTimer *stateTimer;
	NSTimer *screenTimer;
	
	NSDate *endTime;
	
	BOOL recordTimePosition;
	BOOL recordAnnotationEdits;
	BOOL recordState;
}

@property(copy) NSString* userID;
@property(copy) NSString* documentID;
@property NSTimeInterval documentDuration;
@property BOOL recordTimePosition;
@property BOOL recordAnnotationEdits;
@property BOOL recordState;

- (NSXMLDocument*)xmlDocument;

- (NSDate*)startTime;
- (NSDate*)endTime;

-(void)setStateSource:(NSObject<DPStateRecording>*)theSource;
-(void)addStateData:(NSData*)state;

+ (DataPrismLog*)logFromFile:(NSString*)filename;
+ (DataPrismLog*)logFromFile:(NSString*)filename ignoringStates:(BOOL)ignoreStates;

@end
