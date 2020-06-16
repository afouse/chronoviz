//
//  MovieViewerController.m
//  Annotation
//
//  Created by Adam Fouse on 12/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MovieViewerController.h"
#import "VideoProperties.h"
#import "Annotation.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "NSStringTimeCodes.h"

@implementation MovieViewerController

- (id)init
{
	if(![super initWithWindowNibName:@"MovieViewer"])
		return nil;
	
	statusBarVisible = YES;
	alignmentBarVisible = NO;
	
	return self;
}

- (void) dealloc
{
	NSLog(@"move view dealloc");
	[properties removeObserver:self forKeyPath:@"title"];
	[properties removeObserver:self forKeyPath:@"offset"];
	[properties release];
	[super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[properties setEnabled:NO];
	[[AppController currentApp] setRate:[[[AppController currentApp] movie] rate] fromSender:self];
}

- (void)showWindow:(id)sender
{
	[properties setEnabled:YES];
	[[AppController currentApp] setRate:[[[AppController currentApp] movie] rate] fromSender:self];
}

- (void)windowDidLoad
{
	[[self window] setDelegate:self];
	
	[[self window] setContentBorderThickness:[statusBar frame].size.height forEdge:NSMinYEdge];
	[[timeField cell] setBackgroundStyle:NSBackgroundStyleRaised];
	
	CAAnimation *anim = [CABasicAnimation animation];
	[anim setDelegate:self];
	[[self window] setAnimations:[NSDictionary dictionaryWithObject:anim forKey:@"frame"]];
}

- (void)setVideoProperties:(VideoProperties*)props
{
	if(props != properties)
	{
		[properties removeObserver:self forKeyPath:@"title"];
		[properties removeObserver:self forKeyPath:@"offset"];
		[props retain];
		[properties release];
		properties = props;
		
		if(properties)
		{
			[self window];
			NSSize contentSize = [[[properties movie] attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
			
			contentSize.width = contentSize.width;
			contentSize.height = contentSize.height;
			
			CGFloat footer = 0;
			
			if(statusBarVisible)
			{
				footer = [statusBar frame].size.height;
			}
			else if (alignmentBarVisible)
			{
				footer = [alignmentBar frame].size.height;
			}
			
			contentSize.height = contentSize.height + footer;
			[[self window] setContentSize:contentSize];
			[[self window] setTitle:[properties title]];
			[movieView setMovie:[properties movie]];
			
			CMTime offset = [properties offset];
			[offsetField setFloatValue:((CGFloat) offset.value/(CGFloat) offset.timescale)];
			
			[volumeSlider setHidden:![properties hasAudio]];
			[volumeIcon setHidden:![properties hasAudio]];
			
			[properties addObserver:self forKeyPath:@"title" options:0 context:NULL];
			[properties addObserver:self forKeyPath:@"offset" options:0 context:NULL];
		}
	}
	
}

- (VideoProperties*)videoProperties
{
	return properties;
}

-(AFMovieView*)movieView
{
	[self window];
	return movieView;
}

- (IBAction)adjustAlignment:(id)sender
{
	if(alignmentBarVisible)
	{
		alignmentBarVisible = NO;
		[movieView setLocalControl:nil];
		
		CGFloat diff = [alignmentBar frame].size.height;
		
		NSRect windowFrame = [[self window] frame];
		windowFrame.size.height = windowFrame.size.height - diff;
		windowFrame.origin.y = windowFrame.origin.y + diff;
		
		[movieView setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
		
		[NSAnimationContext beginGrouping];
		
		[[NSAnimationContext currentContext] setDuration:0.2];
		
		[[[self window] animator] setFrame:windowFrame display:YES];
		
		[NSAnimationContext endGrouping];
		
		[alignmentButton setTitle:@"Adjust Alignment"];
		
		[[AppController currentDoc] saveVideoProperties:properties];
        [[AppController currentDoc] saveData];
	}
	else
	{
		alignmentBarVisible = YES;
		
		[self update];
		
		CGFloat diff = [alignmentBar frame].size.height;
		
		NSRect windowFrame = [[self window] frame];
		windowFrame.size.height = windowFrame.size.height + diff;
		windowFrame.origin.y = windowFrame.origin.y - diff;
		
		NSRect frame = [alignmentBar frame];
		frame.size.width = [statusBar frame].size.width;
		frame.origin.y = [statusBar frame].origin.y + [statusBar frame].size.height;
		[alignmentBar setFrame:frame];
		
		[movieView setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
		
		[NSAnimationContext beginGrouping];
		
		[[NSAnimationContext currentContext] setDuration:0.2];
		
		[[[self window] animator] setFrame:windowFrame display:YES];
		[[[self window] animator] setContentBorderThickness:([statusBar frame].size.height + diff) forEdge:NSMinYEdge];
		
		[NSAnimationContext endGrouping];
		
		[[[self window] contentView] addSubview:alignmentBar positioned:NSWindowBelow relativeTo:movieView];
		[alignmentButton setTitle:@"Save Alignment"];
		
		[movieView setLocalControl:self];
	}
}

- (IBAction)moveAlignmentSlider:(id)sender
{
	long long timeValue = [[movieView movie] duration].timeValue * [alignmentSlider floatValue];
	QTTime newTime = QTMakeTime(timeValue,[[movieView movie] duration].timeScale);
	[[movieView movie] setCurrentTime:newTime];
	QTTime offset = QTTimeDecrement(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.timeValue/(CGFloat) offset.timeScale)];
	[self update];
}

- (IBAction)changeOffset:(id)sender
{
	QTTime offset = QTMakeTimeWithTimeInterval((NSTimeInterval)[offsetField floatValue]);
	[properties setOffset:offset];
	QTTime newTime = QTTimeIncrement([[[AppController currentApp] movie] currentTime], offset);
	if(newTime.timeValue < 0)
	{
		newTime.timeValue = 0;
	}
	[[movieView movie] setCurrentTime:newTime];
	[self update];
}

- (void)moveAlignmentOneFrameForward
{
	[[movieView movie] stepForward];
	QTTime newTime = [[movieView movie] currentTime];
	QTTime offset = QTTimeDecrement(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.timeValue/(CGFloat) offset.timeScale)];
	[self update];
}

- (void)moveAlignmentOneFrameBackward
{
	[[movieView movie] stepBackward];
	QTTime newTime = [[movieView movie] currentTime];
	QTTime offset = QTTimeDecrement(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.timeValue/(CGFloat) offset.timeScale)];
	[self update];
}

- (void)moveAlignmentOneStepForward
{
	QTTime newTime = [[movieView movie] currentTime];
	newTime.timeValue = newTime.timeValue + newTime.timeScale*[[AppController currentApp] stepSize];
	if(QTTimeCompare(newTime, [[movieView movie] duration]) == NSOrderedDescending)
		newTime.timeValue = [[movieView movie] duration].timeValue;
	[[movieView movie] setCurrentTime:newTime];
	QTTime offset = QTTimeDecrement(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.timeValue/(CGFloat) offset.timeScale)];
	[self update];
}

- (void)moveAlignmentOneStepBackward
{
	QTTime newTime = [[movieView movie] currentTime];
	newTime.timeValue = newTime.timeValue - newTime.timeScale*[[AppController currentApp] stepSize];
	if(newTime.timeValue < 0)
		newTime.timeValue = 0;
	[[movieView movie] setCurrentTime:newTime];
	QTTime offset = QTTimeDecrement(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.timeValue/(CGFloat) offset.timeScale)];
	[self update];
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
	[movieView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
	if(!alignmentBarVisible)
	{
		[alignmentBar removeFromSuperview];
		[[[self window] animator] setContentBorderThickness:[statusBar frame].size.height forEdge:NSMinYEdge];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ((object == properties) && [keyPath isEqual:@"title"])
	{
		[[self window] setTitle:[properties title]];
    }
	else if ((object == properties) && [keyPath isEqual:@"offset"])
	{
		QTTime newTime = QTTimeIncrement([[[AppController currentApp] movie] currentTime], [properties offset]);
		if(newTime.timeValue < 0)
		{
			newTime.timeValue = 0;
		}
		[[movieView movie] setCurrentTime:newTime];
		[self update];
    }
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}

#pragma mark AnnotationView Methods

-(void)addAnnotation:(Annotation*)annotation
{

}

-(void)addAnnotations:(NSArray*)array
{

}

-(void)removeAnnotation:(Annotation*)annotation
{

}

-(void)updateAnnotation:(Annotation*)annotation
{

}

-(void)setAnnotationFilter:(AnnotationFilter*)filter
{

}

-(AnnotationFilter*)annotationFilter
{
	return nil;
}

-(NSArray*)dataSets
{
	return [NSArray array];
}


-(void)update
{
	[timeField setStringValue:[NSString stringWithQTTime:[[AppController currentApp] currentTime]]];
	if(alignmentBarVisible)
	{
		[alignmentSlider setFloatValue:(float)([[movieView movie] currentTime].timeValue)/(float)[[movieView movie] duration].timeValue];
	}
}

-(NSData*)currentState:(NSDictionary*)stateFlags
{		
	if([[self window] isVisible])
	{
		return [NSKeyedArchiver archivedDataWithRootObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                            [properties uuid],@"VideoID",
                                                            [NSNumber numberWithBool:[properties enabled]],@"VideoEnabled",
															[properties title] ,@"VideoTitle",
															nil]];	
	}
	else
	{
		return nil;
	}
}

-(BOOL)setState:(NSData*)stateData
{
	NSDictionary *stateDict;
	@try {
		stateDict = [NSKeyedUnarchiver unarchiveObjectWithData:stateData];
	}
	@catch (NSException *e) {
		NSLog(@"Invalid archive, %@", [e description]);
		return NO;
	}
	
    NSString *movieID = [stateDict objectForKey:@"VideoID"];
    if(movieID)
    {
        BOOL enabled = [[stateDict objectForKey:@"VideoEnabled"] boolValue];
        for(VideoProperties *video in [[AnnotationDocument currentDocument] allMediaProperties])
        {
            if([movieID isEqualToString:[video uuid]])
            {
                [self setVideoProperties:video];
                [video setEnabled:enabled];
            }
        }
    }
    else
    {
        NSString *title = [stateDict objectForKey:@"VideoTitle"];
        if(title)
        {
            for(VideoProperties *video in [[AnnotationDocument currentDocument] mediaProperties])
            {
                if([title isEqualToString:[video title]])
                {
                    [self setVideoProperties:video];
                    break;
                }
            }	
        }
    }
	
	return YES;
}

@end
