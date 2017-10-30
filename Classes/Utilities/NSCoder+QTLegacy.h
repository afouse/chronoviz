//
//  NSCoder (QTLegacy).h
//  ChronoViz
//
//  Created by Adam Fouse on 10/29/17.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface NSCoder (QTLegacy)

- (CMTime)decodeLegacyQTTimeForKey:(NSString*)key;
- (CMTimeRange)decodeLegacyQTTimeRangeForKey:(NSString*)key;

@end
