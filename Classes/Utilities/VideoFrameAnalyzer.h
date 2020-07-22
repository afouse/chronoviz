#import <AVKit/AVKit.h>

@interface VideoFrameAnalyzer : NSObject {
}

+ (void)analyze:(AVPlayer*)player withDelegate:(id)delegate;

@end

@interface NSObject(VideoFrameAnalzerDelegate)
- (void)readFrame:(CVPixelBufferRef)buffer atTime:(NSValue *)time;
@end
