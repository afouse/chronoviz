//
//  NSColorAutomatic.m
//  ChronoViz
//
//  Created by Adam Fouse on 3/20/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "NSColorUniqueColors.h"

@implementation NSColor (UniqueColors)

+(NSArray*)basicColors
{
	return [NSArray arrayWithObjects:
			[NSColor blueColor],
			[NSColor redColor],
			[NSColor orangeColor],
			[NSColor greenColor],
			[NSColor purpleColor],
			[NSColor cyanColor],
			[NSColor magentaColor],
			nil];	
}

#pragma mark Unique Colors

+(NSColor*)basicColorNotInArrayOfColors:(NSArray*)arrayOfColors
{
	return [NSColor colorFromColors:[NSColor basicColors] notInArrayOfColors:arrayOfColors];
}

+(NSColor*)basicColorNotInArrayOfObjects:(NSArray*)arrayOfObjects
{
	return [NSColor colorFromColors:[NSColor basicColors] notInArrayOfObjects:arrayOfObjects];
}

+(NSColor*)colorFromColors:(NSArray*)colors notInArrayOfColors:(NSArray*)arrayOfColors
{
	for(NSColor* color in colors)
	{
		if(![arrayOfColors containsObject:color])
		{
			return color;
		}
	}
	return nil;	
}

+(NSColor*)colorFromColors:(NSArray*)colors notInArrayOfObjects:(NSArray*)arrayOfObjects
{
	NSMutableArray *arrayOfColors = [NSMutableArray array];
	for(id obj in arrayOfObjects)
	{
		if([(NSObject*)obj respondsToSelector:@selector(color)])
		{
			[arrayOfColors addObject:[obj color]];
		}
	}
	return [NSColor colorFromColors:colors notInArrayOfColors:arrayOfColors];
}

+(void)uniquelyColorObjects:(NSArray*)objects fromColors:(NSArray*)colors
{
	if([objects count] < [colors count])
	{
		NSMutableSet *objectColors = [NSMutableSet set];
		for(id obj in objects)
		{
			if([obj respondsToSelector:@selector(setColor:)]
			   && [obj respondsToSelector:@selector(color)])
			{
				if([objectColors containsObject:[obj color]])
				{
					NSColor* newColor = [NSColor colorFromColors:colors notInArrayOfColors:[objectColors allObjects]];
					if(newColor)
					{
						[obj setColor:newColor];
					}
				}
				[objectColors addObject:[obj color]];
			}
		}

	}
	
	
}

#pragma mark Distributed Colors

+(NSColor*)basicColorConsideringArrayOfColors:(NSArray*)arrayOfColors
{
    return [NSColor colorFromColors:[NSColor basicColors] consideringArrayOfColors:arrayOfColors];
}

+(NSColor*)basicColorConsideringArrayOfObjects:(NSArray*)arrayOfObjects
{
    return [NSColor colorFromColors:[NSColor basicColors] consideringArrayOfObjects:arrayOfObjects];
}


+(NSColor*)colorFromColors:(NSArray*)colors consideringArrayOfColors:(NSArray*)arrayOfColors
{
    NSMutableArray *counts = [NSMutableArray arrayWithCapacity:[colors count]];
    
    for(NSColor* color in colors)
    {
        [counts addObject:[NSNumber numberWithInt:0]];
    }
    
    for(NSColor* color in arrayOfColors)
    {
        NSUInteger index = [colors indexOfObjectPassingTest:^(id obj,NSUInteger idx,BOOL *stop)
         {
             CGFloat distance = [color distanceFromColor:(NSColor*)obj];
             
             //NSLog(@"Color distance for %@ and %@: %f",[color description],[obj description],distance);
             
             if((distance >= 0) && (distance < .01))
             {
                 return YES;
             }
             else 
             {
                 return NO;
             }
         }];
        //NSUInteger index = [colors indexOfObject:color];
        if(index != NSNotFound)
        {
            NSNumber *newCount = [NSNumber numberWithInt:([[counts objectAtIndex:index] intValue] + 1)];
            [counts replaceObjectAtIndex:index withObject:newCount];
        }
    }
    
    //NSLog(@"Colors: %@",colors);
    //NSLog(@"Counts: %@",counts);
    
    NSUInteger minIndex = NSNotFound;
    NSInteger minCount = NSIntegerMax;
    NSUInteger index = 0;
    for(NSNumber *count in counts)
    {
        if([count integerValue] < minCount)
        {
            minIndex = index;
            minCount = [count integerValue];
        }
        index++;
    }
    
    if(minIndex != NSNotFound)
    {
        return [colors objectAtIndex:minIndex];
    }
    else
    {
        return nil;
    }
}

+(NSColor*)colorFromColors:(NSArray*)colors consideringArrayOfObjects:(NSArray*)arrayOfObjects
{
   	NSMutableArray *arrayOfColors = [NSMutableArray array];
	for(id obj in arrayOfObjects)
	{
		if([(NSObject*)obj respondsToSelector:@selector(color)])
		{
			[arrayOfColors addObject:[obj color]];
		}
	}
	return [NSColor colorFromColors:colors consideringArrayOfColors:arrayOfColors]; 
}

#pragma mark Comparison

-(CGFloat)distanceFromColor:(NSColor*)otherColor
{
    CMProfileRef labProfile;
    
//    CGFloat whitePoint[3] = {0.95047, 1.0, 1.08883};
//    CGFloat blackPoint[3] = {0, 0, 0};
//    CGFloat range[4] = {-127, 127, -127, 127};
//    CGColorSpaceRef labSpace = CGColorSpaceCreateLab(whitePoint, blackPoint, range);
    
//    CMGetDefaultProfileBySpace (cmLabData, &labProfile);
//
//
//
//    NSColorSpace *labColorSpace = [[[NSColorSpace alloc]
//                                    initWithColorSyncProfile:labProfile] autorelease];
//    CMCloseProfile (labProfile);

    NSColorSpace *labColorSpace = [[NSColorSpace availableColorSpacesWithModel:NSColorSpaceModelLAB] firstObject];
    
    NSColor *myLabColor = [self colorUsingColorSpace:labColorSpace];
    unsigned myComponentCount = [myLabColor numberOfComponents];
    CGFloat myComponents[myComponentCount];
    [myLabColor getComponents:(CGFloat*)&myComponents];
    
    NSColor *otherLabColor = [otherColor colorUsingColorSpace:labColorSpace];
    unsigned otherComponentCount = [otherLabColor numberOfComponents];
    CGFloat otherComponents[otherComponentCount];
    [otherLabColor getComponents:(CGFloat*)&otherComponents];
    
    if((myComponentCount > 2) && (otherComponentCount > 2))
    {
        //NSLog(@"Lab components for %@ (%i): %f %f %f",[otherColor description],(int)otherComponentCount,otherComponents[0],otherComponents[1],otherComponents[2]);
        
        return sqrt(pow((myComponents[0] - otherComponents[0]), 2) + pow((myComponents[1] - otherComponents[1]), 2) + pow((myComponents[1] - otherComponents[1]), 2));
    }
    else 
    {
        return -1;
    }
}

@end
