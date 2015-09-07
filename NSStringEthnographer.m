//
//  NSString-Ethnographer.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/24/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "NSStringEthnographer.h"

static long long MASKS[] = { 4095L, 4095L, 65535L, 4095L, 4095L };
static int SHIFTS[] = { 52, 40, 24, 12, 0 };

@implementation NSString (Ethnographer)

+ (NSString*) livescribePageFromLong:(long long) pageNr
{
	if (pageNr == -1L) {
        return @"<Invalid page address>";
	} else {
        return [NSString stringWithFormat:@"%qi.%qi.%qi.%qi",
				//(pageNr >> SHIFTS[0] & MASKS[0]),
				(pageNr >> SHIFTS[1] & MASKS[1]),
				(pageNr >> SHIFTS[2] & MASKS[2]),
				(pageNr >> SHIFTS[3] & MASKS[3]),
				(pageNr >> SHIFTS[4] & MASKS[4])];
	}
}

- (long long) livescribePageNumber {
	
	NSArray *components = [self componentsSeparatedByString:@"."];
	
	int startIndex;
	
	if([components count] == 5)
	{
		startIndex = 1;
	}
	else if ([components count] == 4)
	{
		startIndex = 0;
	}
	else
	{
		return 0LL;
	}
	
	int segment = [[components objectAtIndex:startIndex] intValue];
	int shelf = [[components objectAtIndex:(startIndex + 1)] intValue];
	int book = [[components objectAtIndex:(startIndex + 2)] intValue];
	int page = [[components objectAtIndex:(startIndex + 3)] intValue];
	
	return (segment & MASKS[1]) << SHIFTS[1] | (shelf & MASKS[2]) << SHIFTS[2]
	| (book & MASKS[3]) << SHIFTS[3] | (page & MASKS[4]) << SHIFTS[4];
}

- (NSString*) livescribePageNumberString
{
	if([self rangeOfString:@"."].location != NSNotFound)
	{
		return [NSString stringWithFormat:@"%qi",[self livescribePageNumber]];	
	}
	else
	{
		return self;
	}
}

- (NSString*) livescribeAddress
{
	return [NSString livescribePageFromLong:[self longLongValue]];
}

@end
