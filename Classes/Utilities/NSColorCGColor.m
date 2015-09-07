//
//  NSColorCGColor.m
//  Annotation
//
//  Created by Adam Fouse on 10/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSColorCGColor.h"


@implementation NSColor(NSColorCGColor)

-(CGColorRef)createCGColor
{
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	NSColor *deviceColor = [self colorUsingColorSpaceName:  
							NSDeviceRGBColorSpace];
	CGFloat components[4];
	[deviceColor getRed: &components[0] green: &components[1] blue:  
	 &components[2] alpha: &components[3]];
	
	return CGColorCreate(colorSpace, components);
}


@end
