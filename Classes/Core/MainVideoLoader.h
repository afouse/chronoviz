//
//  MainVideoLoader.h
//  ChronoViz
//
//  Created by Johannes Maas on 20.06.20.
//

#import "MainVideo.h"

#import <AVKit/AVKit.h>

typedef void (^LoadedCallbackBlock)(MainVideo *);

@interface MainVideoLoader : NSObject

@property (retain) AVPlayerItem *playerItem;
@property (copy) LoadedCallbackBlock callbackBlock;

- (void)loadFromFile:(NSString *)fileName whenLoaded:(LoadedCallbackBlock)callbackBlock;

@end
