//
//  AnnotationFilmstripVisualizer.m
//  Annotation
//
//  Created by Adam Fouse on 8/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationFilmstripVisualizer.h"
#import "Annotation.h"

@implementation AnnotationFilmstripVisualizer

-(id)initWithTimelineView:(TimelineView*)timelineView
{
	self = [super initWithTimelineView:timelineView];
	if(self)
	{
		[self setLineUpCategories:NO];
		viz = [[FilmstripVisualizer alloc] initWithTimelineView:timelineView];
		//filmstrip = nil;
	}
	return self;
}

-(id)initWithTimelineView:(TimelineView*)timelineView andFilmstripVisualizer:(FilmstripVisualizer*)filmViz
{
	return [super initWithTimelineView:timelineView andSecondVisualizer:filmViz];
}

-(void)updateMarker:(TimelineMarker*)marker
{
	if(![[marker annotation] isDuration])
	{
		[super updateMarker:marker];
	}
}

-(void)setVideoProperties:(VideoProperties *)theMovie
{
	[viz setVideoProperties:theMovie];
}

/*
- (void) dealloc
{
	[filmstrip release];
	[super dealloc];
}

- (SegmentVisualizer*)dataVisualizer
{
	return filmstrip;
}

-(void)reset
{
	[filmstrip reset];
	[super reset];
}

-(void)setup
{
	[filmstrip setup];
	[super setup];
}

-(BOOL)updateMarkers
{
	[super updateMarkers];
	return [filmstrip updateMarkers];
}


 */


@end
