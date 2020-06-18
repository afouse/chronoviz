//
//  AFAVAssetCreator.m
//  ChronoViz
//
//  Created by Adam Fouse on 9/8/17.
//
//

#import "AFAVAssetCreator.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>

@implementation AFAVAssetCreator

+(void)createNewMovieAtPath:(NSURL*)somePath fromImage:(NSImage*)image withDuration:(NSTimeInterval)seconds
{
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc]
                                  initWithURL:somePath
                                  fileType:AVFileTypeQuickTimeMovie
                                  error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:640], AVVideoWidthKey,
                                   [NSNumber numberWithInt:480], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* writerInput = [AVAssetWriterInput
                                       assetWriterInputWithMediaType:AVMediaTypeVideo
                                       outputSettings:videoSettings]; //retain should be removed if ARC
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    NSRect imageRect = NSMakeRect(0, 0, image.size.width, image.size.height);
    CGImageRef cgImage = [image CGImageForProposedRect:&imageRect context:NULL hints:nil];
    
    CVPixelBufferRef buffer = NULL;
    
    while (1)
    {
        // Check if the writer is ready for more data, if not, just wait
        if(writerInput.readyForMoreMediaData){
            
            
            buffer = [AFAVAssetCreator pixelBufferFromCGImage:cgImage];
            
            [adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMakeWithSeconds(seconds, 600)];
            
            //Finish the session:
            // This is important to be done exactly in this order
            [writerInput markAsFinished];
            // WARNING: finishWriting in the solution above is deprecated.
            // You now need to give a completion handler.
            [videoWriter finishWritingWithCompletionHandler:^{
                NSLog(@"Finished writing...checking completion status...");
                if (videoWriter.status != AVAssetWriterStatusFailed && videoWriter.status == AVAssetWriterStatusCompleted)
                {
                    NSLog(@"Video writing succeeded.");
                    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:somePath display:YES completionHandler:^(NSDocument *document, BOOL alreadyOpen, NSError *err){
                        NSLog(@"%@",document);
                    }];
                    
                } else
                {
                    NSLog(@"Video writing failed: %@", videoWriter.error);
                }
                
            }]; // end videoWriter finishWriting Block
            
            CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
            
            NSLog (@"Done");
            break;
        }
    }
    
}

+ (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image
{
    int height = 480;
    int width = 640;
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width,
                                          height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata, width,
                                                 height, 8, 4*width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

@end
