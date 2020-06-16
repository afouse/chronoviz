//
//  VideoActivityVidew.m
//  Annotation
//
//  Created by Adam Fouse on 12/26/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "VideoActivityView.h"
#import "Interaction.h"
#import "InteractionLog.h"
#import "InteractionSpeedChange.h"
#import "InteractionJump.h"
#import "InteractionAddSegment.h"


@implementation VideoActivityView

@synthesize backgroundColor;
@synthesize activityColor;
@synthesize segmentColor;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setBackgroundColor:[NSColor grayColor]];
		[self setActivityColor:[NSColor whiteColor]];
		[self setSegmentColor:[NSColor colorWithDeviceWhite:0.4 alpha:1.0]];
		
		path = [[NSBezierPath alloc] init];
		[path setLineWidth:3.0];
		[path setLineJoinStyle:NSRoundLineJoinStyle];
		
		segmentLines = [[NSBezierPath alloc] init];
		[segmentLines setLineWidth:0.5];
		
		promptLines = [[NSBezierPath alloc] init];
		[promptLines setLineWidth:1.0];
		
		margin = 5.0;
		movieTimeToPixel = 0.01;
		sessionTimeToPixel = 2.5;
		
		dashPattern = (CGFloat *)malloc(sizeof(CGFloat) * 2);
		dashPattern[0] = 1.0;
		dashPattern[1] = 2.0;
		
		if(interactions) 
			[self updatePath];
	}
	return self;	
}

- (BOOL)isFlipped
{
	return NO;
}

- (void)exportImageToFile:(NSString *)filepath 
{
	NSRect r = [self bounds];
	NSData *data = [self dataWithPDFInsideRect:r];
	[data writeToFile:filepath atomically:YES];
}

- (void)updatePath
{
	[promptLines removeAllPoints];
	[segmentLines removeAllPoints];
	[path removeAllPoints];
	NSPoint start;
	start.x = margin;
	start.y = margin;
	[path moveToPoint:start];
//	NSLog(@"Update Path, Interactions: %@", interactions);
	float movieTime;
	float sessionTime = 0;
	for(Interaction* change in [interactions interactions]) {
		if([change type] == AFInteractionTypeSpeedChange)
		{
			CMTime movieCMTime = [change movieTime];
			movieTime = movieCMTime.value;
			sessionTime = [change sessionTime];
			[self addPointatMovieTime:movieTime andSessionTime:sessionTime];

		}
		else if([change type] == AFInteractionTypeJump) 
		{
			InteractionJump *jump = (InteractionJump *)change;
			CMTime fromMovieQTTime = [jump fromMovieTime];
			float fromMovieTime = fromMovieQTTime.value;
			CMTime toMovieQTTime = [jump toMovieTime];
			float toMovieTime = toMovieQTTime.value;
			sessionTime = [change sessionTime];
			
			//[path setLineDash:dashPattern count:2 phase:0.0];
			[self addPointatMovieTime:fromMovieTime andSessionTime:sessionTime];
			[self jumpToPointatMovieTime:toMovieTime andSessionTime:sessionTime];
			
			if(toMovieTime == 0)
			{
				float position = margin + sessionTime * sessionTimeToPixel;
				[promptLines moveToPoint:NSMakePoint(position,0)];
				[promptLines lineToPoint:NSMakePoint(position, [self bounds].size.width)];
			}
		} 
		else if([change type] == AFInteractionTypeAddSegment)
		{
			InteractionAddSegment *segment = (InteractionAddSegment *)change;
			float time = [segment movieTime].value;
			float x = margin + time * movieTimeToPixel;
			NSPoint start = NSMakePoint(0,x);
			NSPoint end = NSMakePoint([self bounds].size.width,x);
			
			[segmentLines moveToPoint:start];
			[segmentLines lineToPoint:end];
		}
	}
	if(movie && ([interactions sessionTime] > sessionTime))
	{
		CMTime movieCMTime = [movie currentTime];
		float movieTime = movieCMTime.value;
		float sessionTime = [interactions sessionTime];
		NSPoint last = [self addPointatMovieTime:movieTime andSessionTime:sessionTime];
//		NSPoint next;
//		next.x = margin + movieTime * movieTimeToPixel;
//		next.y = margin + sessionTime * sessionTimeToPixel;
//		[path lineToPoint:next];
//		NSLog(@"Line to point: %f %f",next.x,next.y);
		
		// Incrementing by 50 so that we're not continually resizing the frame
		// Maybe change to just resize the frame and check performance?
		if(last.x > [self bounds].size.width) {
			NSSize newSize = [self bounds].size;
			newSize.width = last.x + 50;
			[self setFrameSize:newSize];
		}
	} else {
		
		// make sure we can fit the whole path in the view
		NSSize newSize = [self bounds].size;
		newSize.width = [path bounds].size.width + 2*margin;
		[self setFrameSize:newSize];
	}
	
	
	[self setNeedsDisplay: YES];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	long long timeValue =([theEvent locationInWindow].y - margin)/movieTimeToPixel;
	int timeScale = [[movie currentItem] duration].timescale;
	[movie seekToTime:CMTimeMake(timeValue,timeScale)];
}

- (NSPoint)addPointatMovieTime:(float)movieTime andSessionTime:(float)sessionTime
{
	NSPoint next;
	next.y = margin + movieTime * movieTimeToPixel;
	next.x = margin + sessionTime * sessionTimeToPixel;
	[path lineToPoint:next];

	return next;
}

- (NSPoint)jumpToPointatMovieTime:(float)movieTime andSessionTime:(float)sessionTime
{
	NSPoint next;
	next.y = margin + movieTime * movieTimeToPixel;
	next.x = margin + sessionTime * sessionTimeToPixel;
	[path moveToPoint:next];
	//	NSLog(@"Line to point: %f %f",next.x,next.y);
	return next;
}

- (void)setMovie:(AVAsset *)theMovie
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:theMovie]; // TODO: Check whether asset keys are necessary. https://developer.apple.com/documentation/avfoundation/avplayeritem?language=objc
	[movie initWithPlayerItem:playerItem];
	float total = [[movie currentItem] duration].value;
	float height = ([self frame].size.height) - 2*margin;
	movieTimeToPixel = height/total;
}

- (void)addSpeedChange:(float)speed atTime:(CMTime)time
{
	
}

- (void)drawRect:(NSRect)rect {
	NSRect bounds = [self bounds];
	BOOL rotate = YES;
	if(rotate)
	{
		NSAffineTransform* xform = [NSAffineTransform transform];
		if(![path isEmpty])
		{
		// Add the transformations
		[xform translateXBy:0.0 yBy:(bounds.size.height - ([path bounds].size.width + margin))];
		[xform rotateByDegrees:90.0];
		[xform scaleXBy:1.0 yBy:-1.0];
		
		// Apply the changes
		[xform concat];
		}
	}
	[backgroundColor set];
	[NSBezierPath fillRect:bounds];
	
	[segmentColor set];
	[segmentLines stroke];
	
	[activityColor set];
	NSPoint start;
	start.x = margin;
	start.y = margin;
	[path moveToPoint:start];
	[path stroke];	
	
	[[NSColor redColor] set];
	[promptLines stroke];
}

- (void)setInteractionLog:(InteractionLog *)log
{
	interactions = log;
}
		   
@end
