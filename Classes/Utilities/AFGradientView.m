//
//  AFGradientView.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/18/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "AFGradientView.h"

NSString * const AFGradientUpdatedNotification = @"GradientUpdatedNotification";

@interface AFGradientViewColorControl : NSView {
	
	AFGradientView *gradientView;
	NSColor *color;
	CGFloat position;
	BOOL selected;
	
	NSBezierPath *swatchPath;
	NSBezierPath *borderPath;
	NSBezierPath *insetPath;
	NSRect colorRect;
	NSRect lineRect;
	CGFloat lineWidth;
	
	CGFloat dragOffset;
	
}

@property(assign) AFGradientView* gradientView;
@property(retain) NSColor* color;
@property CGFloat position;
@property BOOL selected;

- (void)updatePaths:(NSNotification*)notification;

@end

@interface AFGradientView (Internal)

- (void)setDragging:(BOOL)inDrag;
- (NSRect)gradientFrame;
- (NSRect)colorFrameForPosition:(CGFloat)position;
- (void)updateGradientLayout:(NSNotification*)notification;
- (void)updateGradient;
- (void)selectColor:(AFGradientViewColorControl*)colorControl;
- (void)removeColor:(AFGradientViewColorControl*)colorControl;
- (void)addColorAtPoint:(NSPoint)pt;
- (void)addColorAction:(id)sender;
- (void)removeColorAction:(id)sender;

@end


NSComparisonResult afGradientControlSort( id obj1, id obj2, void *context ) {
	
	AFGradientViewColorControl *color1 = (AFGradientViewColorControl*)obj1;
	AFGradientViewColorControl *color2 = (AFGradientViewColorControl*)obj2;
	
	// Compare and return
	if(color2.selected)
		return NSOrderedAscending;
	else if(color1.selected)
		return NSOrderedDescending;
	else
		return NSOrderedSame;
}


@implementation AFGradientViewColorControl

@synthesize color,position,gradientView,selected;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		selected = NO;
		
		[self updatePaths:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updatePaths:)
													 name:NSViewFrameDidChangeNotification
												   object:self];
		
    }
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.color = nil;
	[swatchPath release];
	[borderPath release];
	[insetPath release];
	[super dealloc];
}

- (void)updatePaths:(NSNotification*)notification
{
	[borderPath release];
	[insetPath release];
	[swatchPath release];
	
	NSRect frame = [self bounds];
	
	colorRect = NSMakeRect(0.5, 0.5, frame.size.width - 1, frame.size.width - 1);
	borderPath = [[NSBezierPath bezierPathWithRoundedRect:colorRect xRadius:5 yRadius:5] retain];
	
	NSRect inset = colorRect;
	
	inset = NSMakeRect(inset.origin.x + 1.5,
					   inset.origin.y + 1.5,
					   inset.size.width - 3,
					   inset.size.height - 3);
	
	insetPath = [[NSBezierPath bezierPathWithRoundedRect:inset xRadius:5 yRadius:5] retain];
	
	inset = NSMakeRect(inset.origin.x + 1.5,
					   inset.origin.y + 1.5,
					   inset.size.width - 3,
					   inset.size.height - 3);
	
	swatchPath = [[NSBezierPath bezierPathWithRoundedRect:inset xRadius:5 yRadius:5] retain];
	
	lineWidth = 1.0;
	if(frame.size.width < frame.size.height)
	{
		lineRect = NSMakeRect((frame.size.width/2.0) - (lineWidth/2.0), 
							  frame.size.width, 
							  lineWidth, 
							  frame.size.height - frame.size.width);
	}
	else
	{
		lineRect = NSZeroRect;
	}
	
}

- (void)drawRect:(NSRect)dirtyRect 
{
	
	if(!NSIsEmptyRect(lineRect))
	{
		[[NSColor blackColor] drawSwatchInRect:lineRect];
	}
	
	if(self.selected)
	{
		[[NSColor blackColor] set];
		[borderPath fill];
		[insetPath fill];
		
		
		[self.color set];
		[swatchPath fill];
		
//		[[NSColor whiteColor] set];
//		[[NSBezierPath bezierPathWithRoundedRect:colorRect xRadius:5 yRadius:5] fill];
//		//NSRectFill(colorRect);
//		
//		CGFloat inset = 2;
//		NSRect insetRect = NSMakeRect(inset,inset,colorRect.size.width - (inset * 2),colorRect.size.height - (inset * 2));
//		
//		[self.color set];
//		[[NSBezierPath bezierPathWithRoundedRect:insetRect xRadius:5 yRadius:5] fill];
		
		//[self.color drawSwatchInRect:insetRect];
	}
	else
	{
		if(NSIntersectsRect(dirtyRect, colorRect))
		{
			[[NSColor darkGrayColor] set];
			[borderPath fill];
			[[NSColor whiteColor] set];
			[insetPath fill];
			
			
			[self.color set];
			[swatchPath fill];
			//[self.color drawSwatchInRect: NSIntersectionRect(dirtyRect, colorRect)];	
		}
	}
	
}

- (void)mouseUp:(NSEvent*)theEvent
{
	[gradientView setDragging:NO];
}

- (void)mouseDragged:(NSEvent *)theEvent
{	
	[gradientView setDragging:YES];
	
	NSPoint positionInGradientView = [gradientView convertPoint:[theEvent locationInWindow] fromView:nil];
	NSRect gradientFrame = [gradientView gradientFrame];
	CGFloat newPos = (positionInGradientView.x + dragOffset - gradientFrame.origin.x)/gradientFrame.size.width;
	newPos = fmax(fmin(1.0,newPos),0);
	self.position = newPos;
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[gradientView selectColor:self];
	
	[gradientView sortSubviewsUsingFunction:afGradientControlSort context:NULL];
	
	if([theEvent clickCount] == 2)
	{
		NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
		[colorPanel setTarget: self];
		[colorPanel setColor: self.color];
		[colorPanel setContinuous:NO];
		[colorPanel setAction: @selector (colorChanged:)];
		[colorPanel makeKeyAndOrderFront: self];
	}
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	dragOffset = [self frame].size.width/2 - pt.x;
}

- (void) colorChanged: (id) sender {    // sender is the NSColorPanel
	self.color = [sender color];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
	
	NSMenuItem *item = nil;
	
	item = [theMenu addItemWithTitle:@"Remove Color" action:@selector(removeColorAction:) keyEquivalent:@""];
	[item setTarget:gradientView];
	[item setRepresentedObject:self];
	
	return theMenu;
}

@end




@implementation AFGradientView

@synthesize gradient, continuous;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		
		colorControls = [[NSMutableArray alloc] init];
		
		[self updateGradientLayout:nil];
		
		[self addObserver:self
			   forKeyPath:@"gradient"
				  options:0
				  context:NULL];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(updateGradientLayout:)
													 name:NSViewFrameDidChangeNotification
												   object:self];
		
    }
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[colorControls release];
	[super dealloc];
}

- (NSRect)gradientFrame
{
	return gradientFrame;
}

- (void)setDragging:(BOOL)inDrag
{
	dragging = inDrag;
	if(!dragging && updateOnDragEnd)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:AFGradientUpdatedNotification
															object:self];
	}
}

- (void)updateGradientLayout:(NSNotification*)notification
{
	NSRect frame = [self frame];
	
	gradientInset = 10;
	
	colorSize = fmax(12,fmin(gradientInset * 2.0,frame.size.height/3.0));
	CGFloat lineHeight = fmin(gradientInset,colorSize/2.0);
	
	//CGFloat gradientHeight = fmax(6,(frame.size.height/2) - (2 * gradientInset));
	CGFloat gradientHeight = fmax(6,frame.size.height - (gradientInset + colorSize + lineHeight));
	
	gradientFrame = NSMakeRect(gradientInset, frame.size.height - (gradientHeight + gradientInset/2.0), 
							   frame.size.width - (2*gradientInset) , gradientHeight);
	
	colorsFrame = NSMakeRect(gradientInset + 1, 
							 gradientFrame.origin.y - colorSize - lineHeight,
							 gradientFrame.size.width - 2, 
							 colorSize + lineHeight);
	
	for(AFGradientViewColorControl *control in colorControls)
	{
		[control setFrame:[self colorFrameForPosition:control.position]];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)updateGradient
{
	CGFloat *positions = (CGFloat *)malloc(sizeof(CGFloat) * [colorControls count]);
	NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:[colorControls count]];
	int index = 0;
	for(AFGradientViewColorControl *control in colorControls)
	{
		[colors addObject:control.color];
		positions[index] = control.position;
		index++;
	}
	[gradient release];
	gradient = [[NSGradient alloc] initWithColors:colors
									  atLocations:positions
									   colorSpace:[NSColorSpace deviceRGBColorSpace]];
	[colors release];
	free(positions);
	
	if(self.continuous || !dragging)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:AFGradientUpdatedNotification
															object:self];
	}
	else
	{
		updateOnDragEnd = YES;
	}
	
	[self setNeedsDisplay:YES];
}

- (NSRect)colorFrameForPosition:(CGFloat)position
{
	return NSMakeRect(colorsFrame.origin.x + (colorsFrame.size.width * position) - (0.5 * colorSize) ,
					  colorsFrame.origin.y,
					  colorSize,
					  //colorSize);
					  colorsFrame.size.height);
}

- (void)selectColor:(AFGradientViewColorControl*)colorControl
{
	for(AFGradientViewColorControl *color in colorControls)
	{
		if((color == colorControl) && !color.selected)
		{
			color.selected = YES;
			[color setNeedsDisplay:YES];
		}
		else if((color != colorControl) && color.selected) 
		{
			color.selected = NO;
			[color setNeedsDisplay:YES];
		}

	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"gradient"]) {
		NSArray *tempColors = [colorControls copy];
		for(AFGradientViewColorControl *color in tempColors)
		{
			[self removeColor:color];
		}
		[tempColors release];
		
		NSColor *stopColor = nil;
		CGFloat position = 0;
		int stop;
		for(stop = 0; stop < [gradient numberOfColorStops]; stop++)
		{
			[gradient getColor:&stopColor location:&position atIndex:stop];
			
			NSRect controlFrame = [self colorFrameForPosition:position];
			
			AFGradientViewColorControl *colorControl = [[AFGradientViewColorControl alloc] initWithFrame:controlFrame];
			colorControl.color = stopColor;
			colorControl.position = position;
			colorControl.gradientView = self;
			[self addSubview:colorControl];
			[colorControls addObject:colorControl];
			
			[colorControl addObserver:self
						   forKeyPath:@"position"
							  options:0
							  context:NULL];
			
			[colorControl addObserver:self
						   forKeyPath:@"color"
							  options:0
							  context:NULL];
			
			[colorControl release];
			
		}
		
		[self setNeedsDisplay:YES];
	}
	else if ([keyPath isEqual:@"position"]) {
		AFGradientViewColorControl *colorControl = (AFGradientViewColorControl*)object;
		NSRect controlFrame = [self colorFrameForPosition:colorControl.position];
		[colorControl setFrame:controlFrame];
		
		[self updateGradient];
		
	}
	else if ([keyPath isEqual:@"color"]) {

		[self updateGradient];
		
	}
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}



- (void)mouseDown:(NSEvent *)theEvent
{
	if([theEvent clickCount] == 2)
	{
		NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		[self addColorAtPoint:pt];
	}
	else
	{
		[self selectColor:nil];
	}

}

- (BOOL)acceptsFirstResponder {
    return YES;
}


- (void)keyDown:(NSEvent *)event
{
	unsigned short theKey = [event keyCode];
		//NSLog(@"KeyDown %i",theKey);
	if((theKey == 51) && ([colorControls count] > 1))// Backspace
	{
		AFGradientViewColorControl *selected = nil;
		for(AFGradientViewColorControl *color in colorControls)
		{
			if(color.selected)
			{
				selected = color;
				break;
			}
		}
		
		if(selected)
		{
			[self removeColor:selected];
		}
	}
			
}

- (void)addColorAction:(id)sender
{
	NSPoint pt = [(NSValue*)[sender representedObject] pointValue];
	[self addColorAtPoint:pt];	
}

- (void)removeColorAction:(id)sender
{
	AFGradientViewColorControl *colorControl = (AFGradientViewColorControl*)[sender representedObject];
	[self removeColor:colorControl];
}

- (void)removeColor:(AFGradientViewColorControl*)colorControl
{
	[colorControl removeObserver:self forKeyPath:@"position"];
	[colorControl removeObserver:self forKeyPath:@"color"];
	[colorControl removeFromSuperview];
	[colorControls removeObject:colorControl];
	[self updateGradient];
}

- (void)addColorAtPoint:(NSPoint)pt
{
	CGFloat position = (pt.x - gradientFrame.origin.x)/(gradientFrame.size.width);
	
	NSColor *newColor = [gradient interpolatedColorAtLocation:position];
	
	AFGradientViewColorControl *colorControl = [[AFGradientViewColorControl alloc] initWithFrame:[self colorFrameForPosition:position]];
	colorControl.color = newColor;
	colorControl.position = position;
	colorControl.gradientView = self;
	[self addSubview:colorControl];
	[colorControls addObject:colorControl];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
	[colorControls sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];
	
	[colorControl addObserver:self
				   forKeyPath:@"position"
					  options:0
					  context:NULL];
	
	[colorControl addObserver:self
				   forKeyPath:@"color"
					  options:0
					  context:NULL];
	
	[colorControl release];
	
	[self updateGradient];
	[self selectColor:colorControl];
	
	NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
	[colorPanel setTarget: colorControl];
	[colorPanel setColor: newColor];
	[colorPanel setContinuous:NO];
	[colorPanel setAction: @selector (colorChanged:)];
	[colorPanel makeKeyAndOrderFront: self];
	
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *theMenu = [[[NSMenu alloc] initWithTitle:@"Contextual Menu"] autorelease];
	
	NSMenuItem *item = nil;
	
	item = [theMenu addItemWithTitle:@"Add Color Here" action:@selector(addColorAction:) keyEquivalent:@""];
	[item setTarget:self];
	[item setRepresentedObject:[NSValue valueWithPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]]];
	
	return theMenu;
}


- (void)drawRect:(NSRect)dirtyRect {
	
	//[[NSColor grayColor] drawSwatchInRect:[self bounds]];
	
	if(NSIntersectsRect(dirtyRect, gradientFrame))
	{
		[[NSColor darkGrayColor] set];
		NSRectFill(gradientFrame);
		NSRect inset = NSMakeRect(gradientFrame.origin.x + 1,
								  gradientFrame.origin.y + 1,
								  gradientFrame.size.width - 2,
								  gradientFrame.size.height - 2);
		[[NSColor whiteColor] set];
		NSRectFill(inset);
		inset = NSMakeRect(inset.origin.x + 1,
						   inset.origin.y + 1,
						   inset.size.width - 2,
						   inset.size.height - 2);
		[self.gradient drawInRect:inset angle:0];
	}
	
	if(NSIntersectsRect(dirtyRect, colorsFrame))
	{
		
	}
	
	
}

@end
