//
//  NSCoder (QTLegacy).m
//  ChronoViz
//
//  Created by Adam Fouse on 10/29/17.
//

#import "NSCoder+QTLegacy.h"

@implementation NSCoder (QTLegacy)

- (CMTime)decodeLegacyQTTimeForKey:(NSString*)key
{
    return kCMTimeZero;
}

- (CMTimeRange)decodeLegacyQTTimeRangeForKey:(NSString*)key
{
    return kCMTimeRangeZero;
}

@end
