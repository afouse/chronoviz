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
            NSSize contentSize = (NSSize)[[[[properties movie] tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
			
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
    CMTime duration = [[[movieView movie] currentItem] duration];
	long long timeValue = duration.value * [alignmentSlider floatValue];
	CMTime newTime = CMTimeMake(timeValue, duration.timescale);
	[[movieView movie] seekToTime:newTime];
	CMTime offset = CMTimeSubtract(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.value/(CGFloat) offset.timescale)];
	[self update];
}

- (IBAction)changeOffset:(id)sender
{
	CMTime offset = CMTimeMake((NSTimeInterval)[offsetField floatValue], 1000000); // TODO: Check if the timescale is correct.
	[properties setOffset:offset];
	CMTime newTime = CMTimeAdd([[[AppController currentApp] movie] currentTime], offset);
	if(newTime.value < 0)
	{
		newTime.value = 0;
	}
	[[movieView movie] seekToTime:newTime];
	[self update];
}

- (void)moveAlignmentOneFrameForward
{
	[[[movieView movie] currentItem] stepByCount:1];
	CMTime newTime = [[movieView movie] currentTime];
	CMTime offset = CMTimeSubtract(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.value/(CGFloat) offset.timescale)];
	[self update];
}

- (void)moveAlignmentOneFrameBackward
{
	[[[movieView movie] currentItem] stepByCount:-1];
	CMTime newTime = [[movieView movie] currentTime];
	CMTime offset = CMTimeSubtract(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.value/(CGFloat) offset.timescale)];
	[self update];
}

- (void)moveAlignmentOneStepForward
{
	CMTime newTime = [[movieView movie] currentTime];
	newTime.value = newTime.value + newTime.timescale*[[AppController currentApp] stepSize];
	if(CMTimeCompare(newTime, [[[movieView movie] currentItem] duration]) == NSOrderedDescending)
		newTime.value = [[[movieView movie] currentItem] duration].value;
	[[movieView movie] seekToTime:newTime];
	CMTime offset = CMTimeSubtract(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.value/(CGFloat) offset.timescale)];
	[self update];
}

- (void)moveAlignmentOneStepBackward
{
	CMTime newTime = [[movieView movie] currentTime];
	newTime.value = newTime.value - newTime.timescale*[[AppController currentApp] stepSize];
	if(newTime.value < 0)
		newTime.value = 0;
	[[movieView movie] seekToTime:newTime];
	CMTime offset = CMTimeSubtract(newTime, [[[AppController currentApp] movie] currentTime]);
	[properties setOffset:offset];
	[offsetField setFloatValue:((CGFloat) offset.value/(CGFloat) offset.timescale)];
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
		CMTime newTime = CMTimeAdd([[[AppController currentApp] movie] currentTime], [properties offset]);
		if(newTime.value < 0)
		{
			newTime.value = 0;
		}
		[[movieView movie] seekToTime:newTime];
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
		[alignmentSlider setFloatValue:(float)([[movieView movie] currentTime].value)/(float)[[[movieView movie] currentItem] duration].value];
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
