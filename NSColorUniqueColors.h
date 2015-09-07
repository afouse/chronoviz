//
//  NSColorAutomatic.h
//  ChronoViz
//
//  Created by Adam Fouse on 3/20/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSColor (UniqueColors)

+(NSArray*)basicColors;

+(NSColor*)basicColorNotInArrayOfColors:(NSArray*)arrayOfColors;
+(NSColor*)basicColorNotInArrayOfObjects:(NSArray*)arrayOfObjects;

+(NSColor*)colorFromColors:(NSArray*)colors notInArrayOfColors:(NSArray*)arrayOfColors;
+(NSColor*)colorFromColors:(NSArray*)colors notInArrayOfObjects:(NSArray*)arrayOfObjects;

+(void)uniquelyColorObjects:(NSArray*)objects fromColors:(NSArray*)colors;

+(NSColor*)basicColorConsideringArrayOfColors:(NSArray*)arrayOfColors;
+(NSColor*)basicColorConsideringArrayOfObjects:(NSArray*)arrayOfObjects;

+(NSColor*)colorFromColors:(NSArray*)colors consideringArrayOfColors:(NSArray*)arrayOfColors;
+(NSColor*)colorFromColors:(NSArray*)colors consideringArrayOfObjects:(NSArray*)arrayOfObjects;

-(CGFloat)distanceFromColor:(NSColor*)otherColor;

@end
