#import "VideoFrameAnalyzer.h"

@implementation VideoFrameAnalyzer


+ (void)analyze:(AVPlayer*)player withDelegate:(id)delegate {
    AVAsset *asset = [[player currentItem] asset];
    AVAssetReader *reader = [AVAssetReader assetReaderWithAsset:asset error:nil];
    
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    NSDictionary *settings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
    AVAssetReaderTrackOutput *readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:track outputSettings:settings];
    
    [reader addOutput:readerOutput];
    [reader startReading];
    
    CMSampleBufferRef nextSample = [readerOutput copyNextSampleBuffer];
    while (nextSample != NULL) {
        CVPixelBufferRef frame = CMSampleBufferGetImageBuffer(nextSample);
        if (frame != NULL) {
            [delegate readFrame:frame];
        }
        CFRelease(nextSample);
        nextSample = [readerOutput copyNextSampleBuffer];
    }
}
@end
