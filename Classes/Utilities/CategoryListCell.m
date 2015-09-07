//
//  CategoryListCell.m
//  ChronoViz
//
//  Created by Adam Fouse on 4/7/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "CategoryListCell.h"
#import "AnnotationCategory.h"

@implementation CategoryListCell

@synthesize colorTagWidth;
@synthesize colorTagHeight;

- (id) init
{
	self = [super init];
	if (self != nil) {
		colorTagWidth = 16;
		colorTagHeight = 16;
	}
	return self;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	[self setTextColor:[NSColor blackColor]];
	
	NSObject* data = [self objectValue];
	
	NSArray* categories = nil;
	
	if([data isKindOfClass:[NSArray class]])
	{
		categories = (NSArray*)data;
	}
	
	CGFloat yoffset = 0;
	for(id obj in categories)
	{
		
		if([obj isKindOfClass:[AnnotationCategory class]])
		{
			AnnotationCategory *category = (AnnotationCategory*)obj;
			NSString *name = [category name];
			NSColor *categoryColor = [category color];

			NSRect imageFrame = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y + yoffset, colorTagWidth, colorTagHeight);
			[categoryColor set];
			NSRectFill(imageFrame);
			
			NSDictionary* primaryTextAttributes = [NSDictionary dictionaryWithObjectsAndKeys: [NSColor blackColor], NSForegroundColorAttributeName,
												   [NSFont systemFontOfSize:12], NSFontAttributeName, nil];	
			[name drawAtPoint:NSMakePoint(cellFrame.origin.x + colorTagWidth + 2, cellFrame.origin.y + yoffset) withAttributes:primaryTextAttributes];
			
			yoffset += colorTagHeight;
			yoffset += 2;
		}
	}
	
}

@end
