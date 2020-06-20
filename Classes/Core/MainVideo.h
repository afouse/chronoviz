//
//  Video.h
//  ChronoViz
//
//  Created by Johannes Maas on 20.06.20.
//

#import <AVKit/AVKit.h>

@interface MainVideo : NSObject {
    AVPlayer *_player;
}

@property(nonatomic, readonly) CMTime currentTime;

@property(readonly) CMTime duration;
@property(readonly) CGSize dimensions;

/**
 Expects a specially configured and ready AVPlayer. Use a MainVideoLoader instead of calling this directly.
 */
- (id)initWithReadyPlayer:(AVPlayer *)player;

@end
