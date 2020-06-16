//
//  TranscriptView.h
//  DataPrism
//
//  Created by Adam Fouse on 5/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <AVKit/AVKit.h>
#import "AnnotationView.h"
#import "DPStateRecording.h"
@class TranscriptData;
@class TimeCodedSourcedString;

@interface TranscriptView : NSView <AnnotationView,DPStateRecording> {

	TranscriptData* data;
	NSTableView* tableView;
	WebView* webView;
	
	NSMutableString* html;
	NSString *htmlPath;
	
	NSString *scrollPosition;
	
	CMTime currentTime;
	NSTimeInterval clickedTime;
}

-(void)setData:(TranscriptData*)source;
-(void)reloadData;

-(void)handleTimeClick:(NSTimeInterval)time;
-(IBAction)alignToPlayhead:(id)sender;

-(NSString*)anchorForString:(TimeCodedSourcedString*)theString;

- (void)performFindPanelAction:(id)sender;
- (IBAction)updateSearchTerm:(id)sender;
- (void)searchForTerm:(NSString*)searchTerm;

@end
