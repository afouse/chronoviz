//
//  NSColorHexadecimalValue.h
//  Annotation
//
//  Created by Adam Fouse on 7/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor(NSColorHexadecimalValue)
-(NSString *)hexadecimalValueOfAnNSColor;
+ (NSColor *) colorFromHexRGB:(NSString *) inColorString;
@end


