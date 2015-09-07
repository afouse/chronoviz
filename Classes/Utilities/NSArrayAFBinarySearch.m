//
//  NSArrayAFBinarySearch.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/30/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "NSArrayAFBinarySearch.h"


@implementation NSArray(AFBinarySearch)

//////
// The following implementations are from https://gist.github.com/275631/
// Created by Marcus Rohrmoser
//////

-(NSInteger)binarySearch:(id)key usingFunction:(NSInteger (*)(id, id, void *))comparator context:(void *)context
{
    return [self binarySearch:key usingFunction:comparator context:context inRange:NSMakeRange(0, self.count)];
}

-(NSInteger)binarySearch:(id)key usingFunction:(NSInteger (*)(id, id, void *))comparator context:(void *)context inRange:(NSRange)range
{
    //NSLogD(@"[NSArray(MroBinarySearch) binarySearch:%@ usingFunction:]", key);
    if(self.count == 0 || key == nil || comparator == NULL)
        return NSNotFound;
	
	//	check overflow?
    NSInteger min = range.location;
    NSInteger max = range.location + range.length - 1;
	
	//NSLog(@"Seach min max %i %i",min,max);
	
    while (min <= max)
    {
        // http://googleresearch.blogspot.com/2006/06/extra-extra-read-all-about-it-nearly.html
        const NSInteger mid = min + (max - min) / 2;
        switch (comparator(key, [self objectAtIndex:mid], context))
        {
            case NSOrderedSame:
                return mid;
            case NSOrderedDescending:
                min = mid + 1;
                break;
            case NSOrderedAscending:
                max = mid - 1;
                break;
        }
    }
    return -(min + 1);
}

@end
