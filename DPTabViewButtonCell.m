//
//  DPTabViewButtonCell.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/9/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPTabViewButtonCell.h"

@implementation DPTabViewButtonCell


/*
- (void)drawImage:(NSImage*)image 
        withFrame:(NSRect)frame 
           inView:(NSView*)controlView
{
}

*/

- (NSRect)drawTitle:(NSAttributedString*)title 
          withFrame:(NSRect)frame 
             inView:(NSView*)controlView
{
    
    if([self state] || [self isHighlighted])
    {
    
        NSRangePointer range = nil;
        
        NSDictionary *attributes = [title attributesAtIndex:0 effectiveRange:range];
        NSMutableDictionary *noback = [attributes mutableCopy];
        NSFont *font = [noback objectForKey:NSFontAttributeName];
        NSFont *boldfont = [[NSFontManager sharedFontManager] convertWeight:YES ofFont:font];
        [noback setObject:boldfont forKey:NSFontAttributeName];
    
        NSAttributedString *nobackstring = [[[NSAttributedString alloc] initWithString:[title string] attributes:noback] autorelease];
    
        return [super drawTitle:nobackstring withFrame:frame inView:controlView];
    }
    else
    {
        return [super drawTitle:title withFrame:frame inView:controlView];
    }
    
}


/*
- (void)drawWithFrame:(NSRect)frame inView:(NSView *)controlView
{
    NSColor *endpointsColor = [NSColor colorWithDeviceRed:0.674 green:0.674 blue:0.673 alpha:1.000];
    NSColor *midColor = [NSColor colorWithDeviceWhite:0.419 alpha:1.000];
    NSColor *topColor = [NSColor colorWithDeviceRed:0.811 green:0.812 blue:0.811 alpha:1.000];
    NSColor *middleBackColor = [NSColor colorWithDeviceWhite:0.788 alpha:1.000];
    NSColor *bottomColor = [NSColor colorWithDeviceWhite:0.926 alpha:1.000];
    
    NSLog(@"Draw with frame: %f %f %f %f",frame.origin.x, frame.origin.y,frame.size.width,frame.size.height);
    
    NSRect topRect = frame;
    topRect.size.height = frame.size.height/2.0;
    topRect.origin.y = topRect.size.height;
    
    NSRect bottomRect = frame;
    bottomRect.size.height = topRect.size.height;
    
    NSGradient *backgroundGradientTop = [[NSGradient alloc] initWithStartingColor:topColor endingColor:middleBackColor];
    [backgroundGradientTop drawInRect:topRect angle:270];
    [backgroundGradientTop release];
    NSGradient *backgroundGradientBottom = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    [backgroundGradientBottom drawInRect:bottomRect angle:270];
    [backgroundGradientBottom release];
    
    CGFloat sidewidth = 2.0;
    NSRect leftSide = NSMakeRect(0.5, 0, sidewidth, frame.size.height);
    NSRect rightSide = NSMakeRect(frame.size.width - sidewidth, 0, sidewidth, frame.size.height);
    NSRect leftShadow = NSMakeRect(0.5 + sidewidth, 0, sidewidth, frame.size.height);
    NSRect rightShadow = NSMakeRect(frame.size.width - (2*sidewidth), 0, 1, frame.size.height);
    
    NSGradient *sidesGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:endpointsColor,midColor,endpointsColor, nil]];
    [sidesGradient drawInRect:leftSide angle:90];
    [sidesGradient drawInRect:rightSide angle:90];
    
    NSGradient *shadowGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:
                                                                     [endpointsColor colorWithAlphaComponent:0.4],
                                                                     [midColor colorWithAlphaComponent:0.4],
                                                                     [endpointsColor colorWithAlphaComponent:0.4], nil]];
    [shadowGradient drawInRect:leftShadow angle:90];
    [shadowGradient drawInRect:rightShadow angle:90];
    
    [sidesGradient release];
    [shadowGradient release]; 
    
    [[self title] drawInRect:frame withAttributes:nil];
}
*/


- (void)drawBezelWithFrame:(NSRect)frame 
                    inView:(NSView *)controlView
{
    if([self state])
    {
    
    NSColor *endpointsColor = [NSColor colorWithDeviceRed:0.674 green:0.674 blue:0.673 alpha:1.000];
    NSColor *midColor = [NSColor colorWithDeviceWhite:0.419 alpha:1.000];
    NSColor *topColor = [NSColor colorWithDeviceRed:0.811 green:0.812 blue:0.811 alpha:1.000];
    NSColor *middleBackColor = [NSColor colorWithDeviceWhite:0.788 alpha:1.000];
    NSColor *bottomColor = [NSColor colorWithDeviceWhite:0.926 alpha:1.000];
    
    //NSLog(@"Button frame: %f %f %f %f",frame.origin.x, frame.origin.y,frame.size.width,frame.size.height);
    
    NSRect topRect = frame;
    topRect.size.height = frame.size.height/2.0;
    topRect.origin.y = topRect.size.height;
    
    NSRect bottomRect = frame;
    bottomRect.size.height = topRect.size.height;
    
    NSGradient *backgroundGradientTop = [[NSGradient alloc] initWithStartingColor:topColor endingColor:middleBackColor];
    [backgroundGradientTop drawInRect:topRect angle:270];
    [backgroundGradientTop release];
    NSGradient *backgroundGradientBottom = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    [backgroundGradientBottom drawInRect:bottomRect angle:270];
    [backgroundGradientBottom release];
    
    CGFloat sidewidth = 1.0;
    NSRect leftSide = NSMakeRect(0.5, 0, sidewidth, frame.size.height);
    NSRect rightSide = NSMakeRect(frame.size.width - sidewidth, 0, sidewidth, frame.size.height);
    NSRect leftShadow = NSMakeRect(0.5 + sidewidth, 0, sidewidth, frame.size.height);
    NSRect rightShadow = NSMakeRect(frame.size.width - (2*sidewidth), 0, sidewidth, frame.size.height);
    
    NSGradient *sidesGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:endpointsColor,midColor,endpointsColor, nil]];
    [sidesGradient drawInRect:leftSide angle:90];
    [sidesGradient drawInRect:rightSide angle:90];
    
    NSGradient *shadowGradient = [[NSGradient alloc] initWithColors:[NSArray arrayWithObjects:
                                                                    [endpointsColor colorWithAlphaComponent:0.4],
                                                                    [midColor colorWithAlphaComponent:0.4],
                                                                    [endpointsColor colorWithAlphaComponent:0.4], nil]];
    [shadowGradient drawInRect:leftShadow angle:90];
    [shadowGradient drawInRect:rightShadow angle:90];
    
    [sidesGradient release];
    [shadowGradient release];
    }
}

@end
