//
//  AnnotationFiltersController.m
//  Annotation
//
//  Created by Adam Fouse on 12/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationFiltersController.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "VideoProperties.h"
#import "AnnotationCategoryFilter.h"
#import "AnnotationSearchFilter.h"
#import "ColorTaggedTextCell.h"
#import "AnnotationCategory.h"
#import "TimelineView.h"
#import "MultiTimelineView.h"
#import "MapView.h"
#import "MAAttachedWindow.h"

@interface AnnotationFiltersController (Private)

- (void)updateTimelineLabel;
- (void)repositionWindow:(NSNotification*)notification;

@end

@implementation AnnotationFiltersController

- (id)init
{
	if(![super initWithWindowNibName:@"AnnotationFilters"])
		return nil;
	
	annotationView = nil;
    
    attachedWindow = nil;
    windowView = nil;
	
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setAnnotationView:nil];
    if(attachedWindow)
    {
        [self closeWindowAction:self];
    }
    [windowView release];
    [super dealloc];
}

- (void)windowDidLoad
{
    windowView = [[[self window] contentView] retain];
    
	NSArray* tableColumns = [filtersView tableColumns];

	for(NSTableColumn *column in tableColumns)
	{
		if([[column identifier] isEqualToString:@"Category"])
		{
			ColorTaggedTextCell *colorCell = [[[ColorTaggedTextCell alloc] init] autorelease];
			[column setDataCell: colorCell];
		}
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"label"])
	{
        [self updateTimelineLabel];
	}
	else
	{
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
	}
}


-(void)updateTimelineLabel
{
    TimelineView *timeline = (TimelineView*)annotationView;
    NSString *timelineLabel = [timeline label];
    if(!timelineLabel)
    {
        timelineLabel = [[NSNumber numberWithUnsignedInteger:[[(MultiTimelineView*)[timeline superTimelineView] timelines] indexOfObject:timeline] + 1] stringValue];
    }
        
    [filtersTitle setStringValue:[NSString stringWithFormat:@"Filters for Timeline %@", timelineLabel]];
}

-(void)setAnnotationView:(id<AnnotationView>) theAnnotationView
{
    if([(NSObject*)annotationView isKindOfClass:[TimelineView class]])
    {
        [(TimelineView*)annotationView removeObserver:self forKeyPath:@"label"];
    }
    
    if(theAnnotationView == nil)
    {
        annotationView = nil;
    }
    else        
    {
    
        [self window];
        annotationView = theAnnotationView;
        
        if([(NSObject*)annotationView isKindOfClass:[TimelineView class]])
        {
            [self updateTimelineLabel];
            [(TimelineView*)annotationView addObserver:self
                                            forKeyPath:@"label"
                                               options:0
                                               context:NULL];
        }
        else if ([(NSObject*)annotationView isKindOfClass:[MapView class]])
        {
            [filtersTitle setStringValue:@"Filters for Map"];
        }
        else
        {
            [filtersTitle setStringValue:@"Filters"];
        }
        
        AnnotationFilter *currentFilter = [annotationView annotationFilter];
        if([currentFilter isKindOfClass:[AnnotationCategoryFilter class]])
        {
            [filtersView reloadData];
            [filterTypeButton selectItemWithTag:1];
            [self changeFilterType:self];
            AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
            if([filter predicateNegation] == AnnotationCategoryFilterNOT)
            {
                [booleanButton selectItemAtIndex:2];
            }
            else if([filter predicateBoolean] == AnnotationCategoryFilterAND)
            {
                [booleanButton selectItemAtIndex:1];
            }
            else
            {
                [booleanButton selectItemAtIndex:0];
            } 
        }
        else if([currentFilter isKindOfClass:[AnnotationSearchFilter class]])
        {
            [filterTypeButton selectItemWithTag:2];
            [self changeFilterType:self];
            AnnotationSearchFilter *filter = (AnnotationSearchFilter*)currentFilter;
            [searchField setStringValue:[filter searchTerm]];
        }
        else
        {
            //[filterTypeButton selectItemWithTag:0];
            //[self changeFilterType:self];
            
            // This makes it start up with the categories view if there is no filter
            // (Mimics the original ChronoViz behavior)
            [filtersView reloadData];
            [filterTypeButton selectItemWithTag:1];
            [self changeFilterType:self];
            //[filterTypeButton setNeedsDisplay:YES];
            //[self performSelectorOnMainThread:@selector(changeFilterType:) withObject:nil waitUntilDone:NO];
            
        }
    }
}


-(void)attachToAnnotationView:(NSView<AnnotationView>*)theAnnotationView
{ 
//    if([[self window] isVisible])
//    {
//        [[self window] close];
//    }
//    
//    if(attachedWindow)
//    {
//        [[attachedWindow parentWindow] removeChildWindow:attachedWindow];
//    }
//    [attachedWindow release];
//    attachedWindow = nil;
    
   
    [self closeWindowAction:self];
    
    NSWindow *viewWindow = [theAnnotationView window];
    
    CGFloat width = [categoriesView frame].size.width;
    CGFloat height = [categoriesView frame].size.height * 1.5;
    CGFloat arrowWidth = 20;
    
    NSRect viewFrame = [theAnnotationView frame];
    
    // Find the top right coordinate in window-space
    NSPoint point = NSMakePoint(viewFrame.size.width,viewFrame.size.height);
    point = [[viewWindow contentView] convertPoint:point fromView:theAnnotationView];
    
    CGFloat halfHoverWidth = width/2.0;
    NSRect windowFrame = [viewWindow frame];
    CGFloat right = windowFrame.origin.x + point.x;
    
    NSScreen *screen = [viewWindow screen];
    NSRect screenframe = [screen visibleFrame];
    
    
    MAWindowPosition windowPosition = MAPositionRight;
    if ((right + width + arrowWidth) > (screenframe.origin.x + screenframe.size.width))
    {
        if((windowFrame.origin.y + point.y + height) > (screenframe.origin.y + screenframe.size.height))
        {
            windowPosition = MAPositionBottom;
            point.y = point.y - viewFrame.size.height;
        }
        else
        {
            windowPosition = MAPositionTop;
        }
        point.x = point.x - halfHoverWidth;
    }
    else
    {
        point.y = point.y - (viewFrame.size.height/2.0);
    }
    


    
    MAAttachedWindow* hoverWindow = [[MAAttachedWindow alloc] initWithView:windowView
                                             attachedToPoint:point 
                                                    inWindow:viewWindow 
                                                      onSide:windowPosition 
                                                  atDistance:0];
    [hoverWindow setBackgroundColor:[NSColor windowBackgroundColor]];
    [hoverWindow setBorderColor:[NSColor lightGrayColor]];
    [hoverWindow setBorderWidth:0.5];
    [hoverWindow setViewMargin:0.0];
    [hoverWindow setReleasedWhenClosed:YES];

    attachedWindow = hoverWindow;
    currentAttachedPoint = point;
    
    [self setAnnotationView:theAnnotationView];
    
    [viewWindow addChildWindow:hoverWindow ordered:NSWindowAbove];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(repositionWindow:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:theAnnotationView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(repositionWindow:)
                                                 name:NSWindowDidResizeNotification
                                               object:viewWindow];
}

-(id<AnnotationView>)currentAnnotationView
{
    return annotationView;
}

- (void)repositionWindow:(NSNotification*)notification
{
    NSView *theAnnotationView = (NSView*)annotationView;
    NSWindow *viewWindow = [theAnnotationView window];
    
    CGFloat width = [categoriesView frame].size.width;
    CGFloat height = [categoriesView frame].size.height * 1.5;
    CGFloat arrowWidth = 20;
    
    NSRect viewFrame = [theAnnotationView frame];
    
    // Find the top right coordinate in window-space
    NSPoint point = NSMakePoint(viewFrame.size.width,viewFrame.size.height);
    point = [[viewWindow contentView] convertPoint:point fromView:theAnnotationView];
    
    CGFloat halfHoverWidth = width/2.0;
    NSRect windowFrame = [viewWindow frame];
    CGFloat right = windowFrame.origin.x + point.x;
    
    NSScreen *screen = [viewWindow screen];
    NSRect screenframe = [screen visibleFrame];
    
    
    MAWindowPosition windowPosition = MAPositionRight;
    if ((right + width + arrowWidth) > (screenframe.origin.x + screenframe.size.width))
    {
        if((windowFrame.origin.y + point.y + height) > (screenframe.origin.y + screenframe.size.height))
        {
            windowPosition = MAPositionBottom;
            point.y = point.y - viewFrame.size.height;
        }
        else
        {
            windowPosition = MAPositionTop;
        }
        point.x = point.x - halfHoverWidth;
    }
    else
    {
        point.y = point.y - (viewFrame.size.height/2.0);
    }


    [(MAAttachedWindow*)attachedWindow setPoint:point side:windowPosition];
    currentAttachedPoint = point;
}

- (IBAction)changeFilterType:(id)sender {
    
    NSWindow *theWindow = attachedWindow;
    if(!attachedWindow)
    {
        theWindow = [self window];
    }
    
    NSInteger tag = [filterTypeButton selectedTag];
    
    NSView *filterView = nil;
    
    if(tag == 1)
    {
        filterView = categoriesView;
        if([annotationView annotationFilter] && ![[annotationView annotationFilter] isKindOfClass:[AnnotationCategoryFilter class]])
        {
            [annotationView setAnnotationFilter:nil];
        }

    }
    else if (tag == 2)
    {
        filterView = searchView;
        if([annotationView annotationFilter] && ![[annotationView annotationFilter] isKindOfClass:[AnnotationSearchFilter class]])
        {
            [annotationView setAnnotationFilter:nil];
        }
    }
    else
    {
        [annotationView setAnnotationFilter:nil];
    }
    
    if(filterView != currentView)
    {
        [currentView removeFromSuperview];
        currentView = filterView;
    
        NSSize frameSize = NSMakeSize(0, -5);
        if(filterView)
        {
            frameSize = [filterView frame].size;  
        }
        
        NSRect currentFrame = [theWindow frame];
        CGFloat viewFrameDiff = currentFrame.size.height - [windowView frame].size.height;
        CGFloat newHeight = (currentFrame.size.height - [dividerLine frame].origin.y) + frameSize.height;
        
        currentFrame.origin.y = currentFrame.origin.y + (currentFrame.size.height - newHeight);
        currentFrame.size.height = newHeight;
        
        if(attachedWindow)
        {
            NSRect viewFrame = [windowView frame];
            viewFrame.size.height = currentFrame.size.height - viewFrameDiff;
            [windowView setFrame:viewFrame];
            
            [theWindow setFrame:currentFrame display:YES animate:NO];
        }
        else
        {
           [theWindow setFrame:currentFrame display:YES animate:YES]; 
        }
        
        if(filterView)
        {
            NSRect filterFrame = [filterView frame];
            filterFrame.origin = NSZeroPoint;
            [windowView addSubview:filterView];
        }
    }
    
}

-(IBAction)changeBoolean:(id)sender
{
	AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
	if([booleanButton indexOfSelectedItem] == 2)
	{
		[filter setPredicateBoolean:AnnotationCategoryFilterAND];
		[filter setPredicateNegation:AnnotationCategoryFilterNOT];
	}
	else if([booleanButton indexOfSelectedItem] == 1)
	{
		[filter setPredicateBoolean:AnnotationCategoryFilterAND];
		[filter setPredicateNegation:nil];
	}
	else
	{
		[filter setPredicateBoolean:AnnotationCategoryFilterOR];
		[filter setPredicateNegation:nil];
	}
	[filter generatePredicate];
	[annotationView setAnnotationFilter:filter];
}

-(IBAction)selectAll:(id)sender
{
	[annotationView setAnnotationFilter:nil];
	[filtersView reloadData];
}

-(IBAction)selectNone:(id)sender
{
	AnnotationCategoryFilter *filter = [[AnnotationCategoryFilter alloc] initForNone];
	[annotationView setAnnotationFilter:filter];
	[filter release];
	[filtersView reloadData];
}

- (IBAction)changeSearchTerm:(id)sender {
    
    NSString *searchString = [searchField stringValue];
	
	AnnotationSearchFilter *theFilter = [[AnnotationSearchFilter alloc] initWithString:searchString];
	[annotationView setAnnotationFilter:theFilter];
	[theFilter release];
    
}

- (IBAction)closeWindowAction:(id)sender {
    
    [self setAnnotationView:nil];
    
    if(attachedWindow)
    {
        [[attachedWindow parentWindow] removeChildWindow:attachedWindow];
        [attachedWindow release];
        attachedWindow = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
    }
    else
    {
        [[self window] performClose:sender];
    }
    
}

#pragma mark Outline View

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	
    return (item == nil) ? [[[AppController currentDoc] categories] count] : [[item values] count];
}


- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return ([[item values] count] > 0) ? YES : NO;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
	
    if(item == nil)
	{
		return [[[AppController currentDoc] categories] objectAtIndex:index];
	} else 
	{
		return [[(AnnotationCategory *)item values] objectAtIndex:index];
	}
}


- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
	AnnotationCategory *category = (AnnotationCategory*)item;
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		return category.name;
	}
	else if([[tableColumn identifier] isEqualToString:@"Buttons"])
	{
		AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
		if(!filter)
		{
			return [NSNumber numberWithBool:YES];
		}
		else
		{
			if([filter includesCategory:category])
			{
				return [NSNumber numberWithBool:YES];
			}
			else
			{
				for(AnnotationCategory *value in [category values])
				{
					if([filter includesCategory:value])
					{
						return [NSNumber numberWithInt:-1];
					}
				}
				return [NSNumber numberWithBool:NO];
			}
			//return [NSNumber numberWithBool:[filter includesCategory:category]];
		}
	}
	else
	{
		return @"";
	}
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		[(AnnotationCategory*)item setName:object];
	}
    else if([[tableColumn identifier] isEqualToString:@"Buttons"])
    {
        BOOL selected = [object boolValue];
        AnnotationCategory *category = (AnnotationCategory*)item;
        
        AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
		
		if(!filter)
		{
			selected = YES;
			filter = [[[AnnotationCategoryFilter alloc] init] autorelease];
		}
		
		if( selected )
			[filter showCategory:category];
		else
			[filter hideCategory:category];
		
		[annotationView setAnnotationFilter:filter];
		
		[filtersView deselectAll:self];
		
		if([category category])
            [filtersView reloadItem:[category category]];
		
		for(id value in [category values])
		{
			[filtersView reloadItem:value];
		}
        
    }
}


- (NSCell *) outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	NSTextFieldCell *cell = [tableColumn dataCell];
	if([[tableColumn identifier] isEqualToString:@"Category"])
	{
		[cell setBackgroundColor:[(AnnotationCategory*)item color]];	
	}
	return cell;
}

//- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
//{
//    return;
//    
//	if([filtersView selectedRow] > -1)
//	{	
//		int index = [filtersView selectedRow];
//		
//		AnnotationCategory *category = [filtersView itemAtRow:index];
//		
//		AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
//		
//		BOOL selected;
//		if(!filter)
//		{
//			selected = YES;
//			filter = [[[AnnotationCategoryFilter alloc] init] autorelease];
//		}
//		else
//		{
//			selected = [filter includesCategory:category];
//		}
//		
//		if( !selected )
//			[filter showCategory:category];
//		else
//			[filter hideCategory:category];
//		
//		[annotationView setAnnotationFilter:filter];
//		
//		[filtersView deselectAll:self];
//		
//		if([category category])
//		   [filtersView reloadItem:[category category]];
//		
//		for(id value in [category values])
//		{
//			[filtersView reloadItem:value];
//		}
//	}
//}



#pragma mark Table View Delegate Methods

/*
- (int) numberOfRowsInTableView: (NSTableView*) tableView {
	return [[[AppController currentDoc] categories] count];
}

- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) tableColumn row:(NSInteger) rowIndex {
	NSString *identifier = [tableColumn identifier];
	AnnotationCategory *category = [[[AppController currentDoc] categories] objectAtIndex:rowIndex];
	if([identifier isEqualToString:@"buttons"])
	{
		AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
		if(!filter)
			return [NSNumber numberWithBool:YES];
		else
			return [NSNumber numberWithBool:[filter includesCategory:category]];
	}
	else
	{
		return [category name];
	}
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	NSTextFieldCell *cell = [tableColumn dataCell];
	if([[tableColumn identifier] isEqualToString:@"names"])
	{
		AnnotationCategory *category = [[[AppController currentDoc] categories] objectAtIndex:rowIndex];
		[cell setBackgroundColor:[category color]];	
	}
	return cell;
}

//- (void)    tableView:(NSTableView*) tv setObjectValue:(id) val 
//	   forTableColumn:(NSTableColumn*) aTableColumn row:(NSInteger) rowIndex
//{
//	NSLog(@"edit table column");
//    AnnotationCategory* category = [[[AppController currentDoc] annotationCategories] objectAtIndex:rowIndex];
//	
//    if([[aTableColumn identifier] isEqualToString:@"buttons"])
//    {
//		NSLog(@"edit buttons");
//        BOOL selected = [val boolValue];
//		AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
//		
//		if(!filter)
//		{
//			filter = [[[AnnotationCategoryFilter alloc] init] autorelease];
//		}
//
//        if( selected )
//            [filter showCategory:category];
//        else
//            [filter hideCategory:category];
//		
//		[annotationView setAnnotationFilter:filter];
//		
//    }
//}


- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
	return YES;
}

//- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex
//{
//	return [[tableColumn identifier] isEqualToString:@"buttons"];
//}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	if([filtersTable selectedRow] > -1)
	{	
		AnnotationCategory* category = [[[AppController currentDoc] categories] objectAtIndex:[filtersTable selectedRow]];
		
		AnnotationCategoryFilter* filter = (AnnotationCategoryFilter*)[annotationView annotationFilter];
		
		BOOL selected;
		if(!filter)
		{
			selected = YES;
			filter = [[[AnnotationCategoryFilter alloc] init] autorelease];
		}
		else
		{
			selected = [filter includesCategory:category];
		}
			
		if( !selected )
			[filter showCategory:category];
		else
			[filter hideCategory:category];
			
		[annotationView setAnnotationFilter:filter];
		
		[filtersTable deselectAll:self];
	}
}

*/

@end
