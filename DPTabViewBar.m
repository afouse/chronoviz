//
//  DPTabViewBar.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/9/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPTabViewBar.h"
#import "DPTabViewButtonCell.h"
#import "DPTabViewButton.h"

@interface DPTabViewBar (Internal)

- (void)updateButtons;
- (void)changeTab:(id)sender;

@end

@implementation DPTabViewBar

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        buttons = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    self.tabView = nil;
    [buttons release];
    [super dealloc];
}

- (void)setTabView:(NSTabView *)theTabView
{
    [theTabView retain];
    [tabView release];
    tabView = theTabView;
    [tabView setDelegate:self];
    
    [self updateButtons];
    
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
}

- (void)updateButtons
{
    for(NSButton *button in buttons)
    {
        [button removeFromSuperview];
    }
    [buttons removeAllObjects];
    
    NSArray *tabItems = [tabView tabViewItems];
    
    CGFloat start = 0;
    
    for(NSTabViewItem *item in tabItems)
    {
        NSRect buttonframe = NSMakeRect(start, 1, 125, [self frame].size.height - 2);
        DPTabViewButton *button = [[DPTabViewButton alloc] initWithFrame:buttonframe];
        
        //DPTabViewButtonCell *cell = [[DPTabViewButtonCell alloc] init];
        //[cell setBackgroundColor:[NSColor clearColor]];
        //[(NSButtonCell*)[button cell] setBackgroundStyle:NSBackgroundStyleRaised];
        //[button setCell:cell];
        //[cell release];
        
        [button setTitle:[item label]];

        [buttons addObject:button];
        [button setAction:@selector(changeTab:)];
        [button setTarget:self];
        [self addSubview:button];
        [button release];
    } 
}

- (NSTabView*)tabView
{
    return tabView;
}

- (void)changeTab:(id)sender
{
    NSUInteger index = [buttons indexOfObject:sender];
    if(index != NSNotFound)
    {
        [tabView selectTabViewItemAtIndex:index];
    }
    [[buttons objectAtIndex:index] setState:YES];
}

- (void)tabViewDidChangeNumberOfTabViewItems:(NSTabView *)tabView
{
    [self updateButtons];
}

- (void)tabView:(NSTabView *)theTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    int selectedIndex = [theTabView indexOfTabViewItem:tabViewItem];
    
    int index = 0;
    for(index = 0; index < [buttons count]; index++)
    {
        [[buttons objectAtIndex:index] setState:(index == selectedIndex)];
    } 
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
    
    CGFloat buttonSize = 125;
    CGFloat buttonStart = bounds.size.width/2.0 - (0.5 * [buttons count] * buttonSize);
    
    for(NSButton *button in buttons)
    {
        NSRect buttonframe = [button frame];
        buttonframe.origin.x = buttonStart;
        [button setFrame:buttonframe];
        buttonStart += buttonSize;
    }
    
    NSColor *startColor = [NSColor colorWithDeviceWhite:0.830 alpha:1.000];
    NSColor *endColor = [NSColor colorWithDeviceWhite:0.946 alpha:1.000];
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
    [gradient drawInRect:[self bounds] angle:270];
    
    [[NSColor grayColor] drawSwatchInRect:NSMakeRect(0,0.6,bounds.size.width,1)];
    [[NSColor darkGrayColor] drawSwatchInRect:NSMakeRect(0,bounds.size.height - 0.5,bounds.size.width,1)];
}

@end
