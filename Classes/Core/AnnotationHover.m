//
//  AnnotationHover.m
//  Annotation
//
//  Created by Adam Fouse on 6/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationHover.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "TimelineView.h"
#import "TimelineMarker.h"
#import "FilmstripVisualizer.h"
#import "MAAttachedWindow.h"

@implementation AnnotationHover

- (void)awakeFromNib
{
	originalFrame = [annotationHoverView frame];
}

- (void) dealloc
{
	[hoverTimeline release];
	[hoverWindow release];
	[super dealloc];
}

- (void)reset
{
	if(hoverTimeline)
	{
		[hoverTimeline removeFromSuperviewWithoutNeedingDisplay];
		[hoverTimeline release];
		hoverTimeline = nil;
	}
	[hoverWindow release];
	hoverWindow = nil;
}

- (void)displayForTimelineMarker:(TimelineMarker*)marker
{	
	Annotation *annotation = [marker annotation];
	
	

	if(annotation && (currentMarker != marker))
	{
		currentMarker = marker;
		[self setAnnotation:annotation];
		
		//NSWindow  *mMovieWindow = [[AppController currentApp] window];
		NSWindow *mMovieWindow = [[marker timeline] window];
		
		// Find the x coordinate in window-space
		NSPoint point = NSMakePoint([[marker layer] frame].origin.x + [[marker layer] frame].size.width/2,0.0);
		point = [[mMovieWindow contentView] convertPoint:point fromView:[marker timeline]];
		if(point.x > [[mMovieWindow contentView] bounds].size.width)
		{
			point.x = [[mMovieWindow contentView] bounds].size.width;
		}
		
		// Find the y coordinate so that it's at the top of the timeline
		TimelineView *timeline = [marker timeline];
		NSPoint height = [[mMovieWindow contentView] convertPoint:NSMakePoint(0.0,[timeline frame].size.height) fromView:timeline];
		point.y = height.y;
		
		if([annotation isDuration] && [annotation keyframeImage])
		{
			NSRect frame = [annotationHoverImage frame];
			frame.origin.x = 0;
			
			NSSize contentSize = [[[[AnnotationDocument currentDocument] movie] attributeForKey:QTMovieNaturalSizeAttribute] sizeValue];
			
			frame.size.width = (contentSize.width/contentSize.height)*frame.size.height*2;
			
			//frame.size.width = fmin(fmax(originalFrame.size.width,[marker layer].bounds.size.width * 2.0),[mMovieWindow frame].size.width);
			
			if(hoverTimeline == nil)
			{				
				hoverTimeline = [[TimelineView alloc] initWithFrame:frame];
				[hoverTimeline setMovie:[[AnnotationDocument currentDocument] movie]];
				[hoverTimeline setShowPlayhead:NO];
				[hoverTimeline setClickToMovePlayhead:NO];
				[hoverTimeline setLinkedToMouse:NO];
				[hoverTimeline setLinkedToMovie:YES];
				
				FilmstripVisualizer* viz = [[FilmstripVisualizer alloc] initWithTimelineView:hoverTimeline];
				[viz setVideoProperties:[[AppController currentDoc] videoProperties]];
				[viz setAutoSegments:YES];
				[hoverTimeline setSegmentVisualizer:viz];
				[viz release];
				
				//[annotationHoverView addSubview:hoverTimeline];
				//[hoverTimeline redraw];
			}
			
			[hoverTimeline setRange:[annotation range]];
			
			[hoverTimeline setFrame:frame];
			NSRect viewFrame = [annotationHoverView frame];
			viewFrame.size.width = frame.size.width;
			[annotationHoverView setFrame:viewFrame];
			
			//[hoverTimeline redrawAllSegments];
			
			[annotationHoverView addSubview:hoverTimeline];
			//[hoverTimeline redraw];
			//[hoverTimeline setHidden:NO];
			[annotationHoverImage setHidden:YES];
			
		}	
		else 
		{
			//[hoverTimeline setHidden:YES];
			[hoverTimeline removeFromSuperview];
			[annotationHoverImage setHidden:NO];
			//[annotationHoverView setFrame:originalFrame];
		}
		
		CGFloat halfHoverWidth = annotationHoverView.frame.size.width/2.0;
        NSRect windowFrame = [mMovieWindow frame];
        CGFloat left = windowFrame.origin.x + point.x - halfHoverWidth;
        CGFloat right = windowFrame.origin.x + point.x + halfHoverWidth;
        
        NSScreen *screen = [mMovieWindow screen];
        NSRect screenframe = [screen visibleFrame];
        
        
        
        MAWindowPosition windowPosition = MAPositionTop;
        if(left < screenframe.origin.x)
        {
            windowPosition = MAPositionTopRight;
        }
        else if (right > (screenframe.origin.x + screenframe.size.width))
        {
            windowPosition = MAPositionTopLeft;
        }
        
		if(hoverWindow && ([hoverWindow parentWindow] == mMovieWindow))
		{
			[hoverWindow setPoint:point side:windowPosition];
		}
		else
		{
			[hoverWindow release];
			hoverWindow = [[MAAttachedWindow alloc] initWithView:annotationHoverView
												 attachedToPoint:point 
														inWindow:mMovieWindow 
														  onSide:windowPosition 
													  atDistance:0];
			[hoverWindow setViewMargin:5.0];
			[hoverWindow setReleasedWhenClosed:NO];
		}
		
		[mMovieWindow addChildWindow:hoverWindow ordered:NSWindowAbove];
	}
}

- (void)closeForTimelineMarker:(TimelineMarker*)marker
{
	if(marker == currentMarker)
	{
		[self close];
	}
}

- (void)close
{
	currentMarker = nil;
	
	[[hoverWindow parentWindow] removeChildWindow:hoverWindow];
	//[[[AppController currentApp] window] removeChildWindow:hoverWindow];
	[hoverWindow close];
}

- (void)setAnnotation:(Annotation*)annotation
{
	NSString *timeString = nil;
	
	if([annotation isDuration])
	{
		NSTimeInterval duration;
		duration = CMTimeGetSeconds(CMTimeSubtract([annotation endTime], [annotation startTime]));
		timeString = [NSString stringWithFormat:@"%@, %.1f seconds",[annotation startTimeString],duration];
	}
	else
	{
		timeString = [annotation startTimeString];
	}
	
	if([[annotation title] length] > 0)
	{
		[annotationHoverTitle setStringValue:[NSString stringWithFormat:@"%@ (%@)",[annotation title],timeString]];
	}
	else
	{
		[annotationHoverTitle setStringValue:[NSString stringWithFormat:@"%@ (%@)",[[annotation category] fullName],timeString]];
	}
	[annotationHoverContent setStringValue:[annotation annotation]];
	
	if(![annotation frameRepresentation])
	{
		[[AppController currentApp] loadAnnotationKeyframeImage:annotation];
	}
	
	NSSize imageSize = [[annotation frameRepresentation] size];
	
    //NSLog(@"Hover Image Size: %f %f",imageSize.width,imageSize.height);
    
	CGFloat ratio = imageSize.width/imageSize.height;
	
	NSRect frame = [annotationHoverImage frame];
	CGFloat width = (frame.size.height) * ratio;
	frame.size.width = fmin(fmax(originalFrame.size.width,[[annotation frameRepresentation] size].width),width);
	
	NSRect viewFrame = [annotationHoverView frame];
	viewFrame.size.width = fmax(frame.size.width,originalFrame.size.width);
	
	frame.origin.x = (viewFrame.size.width - frame.size.width)/2;
	
    //NSLog(@"Hover Frame Size: %f %f",frame.size.width,frame.size.height);
    
//    if([annotation keyframeImage])
//    {
//        [annotationHoverImage setImageScaling:NSScaleNone];
//    }
//    else
//    {
//        [annotationHoverImage setImageScaling:NSScaleToFit];
//    }
    
	[annotationHoverImage setImage:[annotation frameRepresentation]];
	
	[annotationHoverImage setFrame:frame];
	
	
	[annotationHoverView setFrame:viewFrame];
	
}

- (NSView*)hoverView
{
	return annotationHoverView;
}


@end
