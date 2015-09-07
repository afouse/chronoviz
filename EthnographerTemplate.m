//
//  EthnographerTemplate.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/11/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerTemplate.h"

struct dpLongPageRange {
	long long startPage;
	long long endPage;
};

@implementation EthnographerTemplate

@synthesize name, background, printed, numPages, hidden;

- (id) init
{
	self = [super init];
	if (self != nil) {
		self.name = nil;
		self.background = nil;
		self.printed = YES;
		self.numPages = 0;
		
		pageRanges = [[NSMutableArray alloc] init];
        rotations = nil;
	}
	return self;
}

- (void) dealloc
{
    [rotations release];
	[pageRanges release];
	self.name = nil;
	self.background = nil;
	[super dealloc];
}

- (void)addRangeFrom:(long long)begin to:(long long)end
{
	struct dpLongPageRange pageRange;
	pageRange.startPage = begin;
	pageRange.endPage = end;
	
	[pageRanges addObject:[NSData dataWithBytes:&pageRange length:sizeof(struct dpLongPageRange)]];	
}

- (void)resetRanges
{
	[pageRanges removeAllObjects];
}

- (BOOL)containsPage:(NSString*)lsPage
{
	return ([self pdfPageForLivescribePage:lsPage] != NSNotFound);
}

- (NSInteger)pdfPageForLivescribePage:(NSString*)lsPage
{
	struct dpLongPageRange pageRange;
	
	long long pageNumber = [lsPage longLongValue];
	
	for(NSData *rangeData in pageRanges)
	{
		[rangeData getBytes:&pageRange length:sizeof(struct dpLongPageRange)];
		
		if((pageNumber >= pageRange.startPage) && (pageNumber <= pageRange.endPage))
		{
			return (((pageNumber - pageRange.startPage) % numPages) + 1);
		}
	}
	
	return NSNotFound;
}

- (NSUInteger)rotationForPdfPage:(NSUInteger)pdfPage
{
    
    if((pdfPage < 1) || (pdfPage > numPages))
    {
        NSLog(@"Invalid page for requesting rotation from template");
        return 0;
    }
    
    pdfPage -= 1;
        
    if(rotations == nil)
    {
        return 0;
    }
    else if ([rotations count] == 1)
    {
        return [[rotations lastObject] unsignedIntegerValue];
    }
    else if ([rotations count] > pdfPage)
    {
        return [[rotations objectAtIndex:pdfPage] unsignedIntegerValue];
    }

    return 0;
}

- (NSArray*)rotations
{
    return [[rotations copy] autorelease];
}

- (void)setRotation:(NSUInteger)rotation forPdfPage:(NSUInteger)pdfPage
{
    while(rotation > 359)
    {
        rotation -= 360;
    }
    
    if((pdfPage < 1) || (pdfPage > numPages))
    {
        NSLog(@"Invalid page for setting rotation for template");
        return;
    }
    
    pdfPage -= 1;
    
    if(!rotations || ([rotations count] < numPages))
    {
        [rotations release];
        rotations = [[NSMutableArray alloc] initWithCapacity:numPages];
        for(int i = 0; i < numPages; i++)
        {
            [rotations addObject:[NSNumber numberWithUnsignedInteger:0]];
        }
    }
    
    [rotations replaceObjectAtIndex:pdfPage withObject:[NSNumber numberWithUnsignedInteger:rotation]];
}

- (void)setRotation:(NSUInteger)rotation
{
    while(rotation > 359)
    {
        rotation -= 360;
    }
    
    [rotations release];
    rotations = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithUnsignedInteger:rotation], nil];
}

@end
