//
//  MainVideoLoader.m
//  ChronoViz
//
//  Created by Johannes Maas on 20.06.20.
//

#import "MainVideoLoader.h"

@implementation MainVideoLoader

// Marker for value observing callback.
static const NSString *PlayerItemContext;

@synthesize playerItem;
@synthesize callbackBlock;

- (void)loadFromFile:(NSURL *)url whenLoaded:(LoadedCallbackBlock)callbackBlock {
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray<NSString *> *assetKeysToLoad = @[@"duration", @"tracks"];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset automaticallyLoadedAssetKeys:assetKeysToLoad];
        
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew;
    [self.playerItem addObserver:self forKeyPath:@"status"
                         options:options context:&PlayerItemContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context {
    // Only handle observations for the PlayerItemContext
    if (context != &PlayerItemContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
 
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = AVPlayerItemStatusUnknown;
        // Get the status change from the change dictionary
        NSNumber *statusNumber = change[NSKeyValueChangeNewKey];
        if ([statusNumber isKindOfClass:[NSNumber class]]) {
            status = statusNumber.integerValue;
        }
        // Switch over the status
        switch (status) {
            case AVPlayerItemStatusReadyToPlay: {
                AVPlayer *player = [AVPlayer playerWithPlayerItem:self.playerItem];
                MainVideo *mainVideo = [[MainVideo alloc] initWithReadyPlayer:player];
                callbackBlock(mainVideo);
                break;
            }
            case AVPlayerItemStatusFailed:
                // Failed. Examine AVPlayerItem.error
                NSLog(@"Loading video failed.");
                // TODO: Pass error to callback.
                break;
            case AVPlayerItemStatusUnknown:
                // Not ready
                NSAssert(false, @"This case should never happen.");
                break;
        }
    }
}

@end
