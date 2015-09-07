//
//  ColorTaggedTextCell.m
//  Annotation
//
//  Created by Adam Fouse on 11/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ColorTaggedTextCell.h"


@implementation ColorTaggedTextCell

@synthesize colorTagWidth;
@synthesize colorTagHeight;

- (id) init
{
	self = [super init];
	if (self != nil) {
		colorTagWidth = -1;
		colorTagHeight = -1;
	}
	return self;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if ([self backgroundColor] != nil) {
        NSRect	imageFrame;
		
		
		CGFloat width;
		if(colorTagWidth > 0)
		{
			width = colorTagWidth;
		}
		else
		{
			width = fmin(cellFrame.size.height, 20);
		}
		
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, width, NSMinXEdge);
		
		if(colorTagHeight > 0)
		{
			imageFrame.size.height = colorTagHeight;
		}
		
		[[self backgroundColor] set];
		NSRectFill(imageFrame);

    }
    [super drawWithFrame:cellFrame inView:controlView];
}

@end
