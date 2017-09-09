//
//  AFAVAssetCreator.h
//  ChronoViz
//
//  Created by Adam Fouse on 9/8/17.
//
//

#import <Foundation/Foundation.h>

@interface AFAVAssetCreator : NSObject

+(void)createNewMovieAtPath:(NSURL*)somePath fromImage:(NSImage*)image withDuration:(NSTimeInterval)seconds;

@end
