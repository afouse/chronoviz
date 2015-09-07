//
//  MovieViewerController.h
//  Annotation
//
//  Created by Adam Fouse on 12/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AFMovieView.h"
#import "AnnotationView.h"
#import "DPStateRecording.h"
@class VideoProperties;

@interface MovieViewerController : NSWindowController <AnnotationView,DPStateRecording,NSWindowDelegate> {

	IBOutlet AFMovieView* movieView;
	IBOutlet NSView* statusBar;
	IBOutlet NSView* alignmentBar; 
	
	IBOutlet NSSlider* volumeSlider;
	IBOutlet NSImageView* volumeIcon;
	
	IBOutlet NSButton* alignmentButton;
	IBOutlet NSTextField* timeField;
	IBOutlet NSSlider* alignmentSlider;
	IBOutlet NSTextField* offsetField;
	
	VideoProperties* properties;
	
	BOOL statusBarVisible;
	BOOL alignmentBarVisible;
}

- (void)setVideoProperties:(VideoProperties*)props;
- (VideoProperties*)videoProperties;
- (AFMovieView*)movieView;

- (IBAction)adjustAlignment:(id)sender;
- (IBAction)moveAlignmentSlider:(id)sender;
- (IBAction)changeOffset:(id)sender;

- (void)moveAlignmentOneFrameForward;
- (void)moveAlignmentOneFrameBackward;
- (void)moveAlignmentOneStepForward;
- (void)moveAlignmentOneStepBackward;

@end
