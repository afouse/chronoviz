//
//  NSString-Ethnographer.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/24/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString(Ethnographer)

+ (NSString*) livescribePageFromLong:(long long)pageNum;
- (NSString*) livescribePageNumberString;
- (long long) livescribePageNumber;
- (NSString*) livescribeAddress;

@end
