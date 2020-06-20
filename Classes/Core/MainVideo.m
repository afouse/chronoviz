//
//  Video.m
//  ChronoViz
//
//  Created by Johannes Maas on 20.06.20.
//

#import "MainVideo.h"

@implementation MainVideo

@synthesize currentTime;
@synthesize duration;
@synthesize dimensions;

- (id)initWitReadyPlayer:(AVPlayer *)player {
    self = [super init];
    
    if (self) {
        _player = player;
        
        duration = _player.currentItem.duration;
        dimensions = [[[_player.currentItem.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] naturalSize];
    }
    
    return self;
}

- (CMTime)currentTime {
    return _player.currentTime;
}

@end
