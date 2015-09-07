//
//  TranscriptViewController.m
//  DataPrism
//
//  Created by Adam Fouse on 5/3/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TranscriptViewController.h"
#import "TranscriptView.h"

@implementation TranscriptViewController

- (id)init
{
	if(![super initWithWindowNibName:@"TranscriptWindow"])
		return nil;
	
	return self;
}

- (id<AnnotationView>)annotationView
{
    return [self transcriptView];
}

- (TranscriptView*)transcriptView
{
	[self window];
	return transcriptView;
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[[self window] makeFirstResponder:transcriptView];
}

- (void)performFindPanelAction:(id)sender;
{ 
    NSRect contentRect = [transcriptView frame]; 
    [transcriptView setFrameSize:NSMakeSize(contentRect.size.width, contentRect.size.height - [findPanelView bounds].size.height)]; 
    [findPanelView setFrame:NSMakeRect(contentRect.origin.x, [[[self window] contentView] frame].size.height - [findPanelView bounds].size.height, 
                                       contentRect.size.width, [findPanelView bounds].size.height)]; 
    [[[self window] contentView] addSubview:findPanelView];
	[[self window] makeFirstResponder:searchField];
} 

- (IBAction)closeFindPanelAction:(id)sender 
{ 
    NSRect contentRect = [transcriptView frame]; 
    // extra retain to stop findPanelView being released (for some reason) 
    [[findPanelView retain] removeFromSuperviewWithoutNeedingDisplay]; 
    [transcriptView setFrameSize:NSMakeSize(contentRect.size.width, contentRect.size.height + [findPanelView bounds].size.height)]; 
} 

@end
