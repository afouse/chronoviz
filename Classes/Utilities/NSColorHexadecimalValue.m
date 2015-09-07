//
//  NSColorHexadecimalValue.m
//  Annotation
//
//  Created by Adam Fouse on 7/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSColorHexadecimalValue.h"

@implementation NSColor(NSColorHexadecimalValue)

-(NSString *)hexadecimalValueOfAnNSColor
{
	float redFloatValue, greenFloatValue, blueFloatValue;
	int redIntValue, greenIntValue, blueIntValue;
	NSString *redHexValue, *greenHexValue, *blueHexValue;
	
	//Convert the NSColor to the RGB color space before we can access its components
	NSColor *convertedColor=[self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	
	if(convertedColor)
	{
		// Get the red, green, and blue components of the color
		[convertedColor getRed:&redFloatValue green:&greenFloatValue blue:&blueFloatValue alpha:NULL];
		
		// Convert the components to numbers (unsigned decimal integer) between 0 and 255
		redIntValue=redFloatValue*255.99999f;
		greenIntValue=greenFloatValue*255.99999f;
		blueIntValue=blueFloatValue*255.99999f;
		
		// Convert the numbers to hex strings
		redHexValue=[NSString stringWithFormat:@"%02x", redIntValue];
		greenHexValue=[NSString stringWithFormat:@"%02x", greenIntValue];
		blueHexValue=[NSString stringWithFormat:@"%02x", blueIntValue];
		
		// Concatenate the red, green, and blue components' hex strings together with a "#"
		return [NSString stringWithFormat:@"#%@%@%@", redHexValue, greenHexValue, blueHexValue];
	}
	return nil;
}

/*
 NSColor: Instantiate from Web-like Hex RRGGBB string
 Original Source: <http://cocoa.karelia.com/Foundation_Categories/NSColor__Instantiat.m>
 (See copyright notice at <http://cocoa.karelia.com>)
 */

+ (NSColor *) colorFromHexRGB:(NSString *) inColorString
{
	NSColor *result = nil;
	unsigned int colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
	
	if (nil != inColorString)
	{
        if([inColorString length] == 0)
        {
            return [NSColor blackColor];
        }
        else if([inColorString characterAtIndex:0] == '#')
		{
			inColorString = [inColorString substringFromIndex:1];
		}
		NSScanner *scanner = [NSScanner scannerWithString:inColorString];
		(void) [scanner scanHexInt:&colorCode];	// ignore error
	}
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	result = [NSColor
			  colorWithCalibratedRed:		(float)redByte	/ 0xff
			  green:	(float)greenByte/ 0xff
			  blue:	(float)blueByte	/ 0xff
			  alpha:1.0];
	return result;
}

@end