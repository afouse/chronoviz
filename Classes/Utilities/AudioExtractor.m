//
//  AudioExtractor.m
//  DataPrism
//
//  Created by Adam Fouse on 3/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AudioExtractor.h"

@interface AudioExtractor (Private)

- (void)exportOnWorkerThread:(id)inObject;
- (NSWindow*)progressWindow;

@end

@implementation AudioExtractor

@synthesize sampleSize;
@synthesize subsetMethod;

- (id) initWithMovie:(AVPlayer*)theMovie;
{
	self = [super init];
	if (self != nil) {
        AVAsset *asset = [[theMovie currentItem] asset];
        NSAssert([asset isKindOfClass:[AVURLAsset class]], @"Asset does not have URL.");
        NSURL *url = [asset URL];
		movie = [[AVPlayer playerWithURL:url] retain];
		subsetMethod = DPSubsetMethodMax;
		keepExtracting = NO;
	}
	return self;
}

- (void) dealloc
{
    [subsetArray release];
	[movie release];
	[super dealloc];
}

- (void)setDelegate:(id <DataSourceDelegate>)theDelegate
{
	delegate = theDelegate;
}

- (NSArray*)subsetArray
{
	return subsetArray;
}

- (BOOL)exportAudioSubset:(int)theSubsetSize
{
	return [self exportAudioSubset:theSubsetSize forRange:CMTimeRangeMake(kCMTimeZero, [[movie currentItem] duration])];
}

- (BOOL)exportAudioSubset:(int)theSubsetSize forRange:(CMTimeRange)timeRange
{
    BOOL extractionOnWorkerThread = NO;
    BOOL continueExport = YES;
    Handle cloneHandle = NULL;
	
    if(movie == nil)
		return NO;
	
	subsetSize = theSubsetSize;
	subsetTime = timeRange;
	[subsetArray release];
	subsetArray = [[NSMutableArray alloc] initWithCapacity:subsetSize];
	
    // if the client implemented a progress proc. call it now
    if (delegate) {
        [delegate dataSourceLoadStart];
		
        continueExport = ![delegate dataSourceCancelLoad];
		
        if (NO == continueExport) {
            if (cloneHandle) DisposeHandle(cloneHandle);
            
            return NO;
        };
    }
    
    if (extractionOnWorkerThread == YES) {
        // export on a worker thread if we can...
        [NSThread detachNewThreadSelector:@selector(exportOnWorkerThread:) toTarget:self withObject:nil];
    } else {
        // ...if not, we're on the main thread so just call the main-thread worker method
		NSLog(@"Can't export on worker thread");
		[subsetArray addObjectsFromArray:[self getAudioSubset:theSubsetSize]];
		
		if (delegate) {
			[delegate dataSourceLoadFinished];
		}
		
    }
	
    return YES;
	

}

// this method will be performed on a background thread
- (void)exportOnWorkerThread:(id)inObject
{

}


- (NSArray*) getAudioSubset:(NSInteger)theSubsetSize
{
	[[self progressWindow] makeKeyAndOrderFront:self];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setDoubleValue:0.1];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];
	
	subsetSize = theSubsetSize;

	if(!subsetArray)
    {
        subsetArray = [[NSMutableArray alloc] initWithCapacity:subsetSize];
    }
    
		
	[[self progressWindow] close];
	
	return subsetArray;
	
}



- (NSArray*) getAudioSubsetWithSampleLength:(float)sampleLength;
{
	[[self progressWindow] makeKeyAndOrderFront:self];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setDoubleValue:0.1];
	[progressIndicator setUsesThreadedAnimation:YES];
	[progressIndicator startAnimation:self];
    
	
    
	[[self progressWindow] close];
	
	return subsetArray;
	
}


- (void)cancelExtraction:(id)sender
{
	keepExtracting = NO;
	if(progressWindow)
	{
		[[self progressWindow] close];
	}
}

- (NSWindow*)progressWindow
{
	if(!progressWindow)
	{
		progressWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
													 styleMask:NSTitledWindowMask
													   backing:NSBackingStoreBuffered
														 defer:NO];
		[progressWindow setLevel:NSStatusWindowLevel];
		[progressWindow setReleasedWhenClosed:NO];
		
		progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 56, 444, 20)];
		[progressIndicator setIndeterminate:NO];
		
		cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(370,12,96,32)];
		[cancelButton setBezelStyle:NSRoundedBezelStyle];
		[cancelButton setTitle:@"Cancel"];
		[cancelButton setAction:@selector(cancelExtraction:)];
		[cancelButton setTarget:self];
		[cancelButton setEnabled:NO];
		
		progressTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(17, 84, 444, 17)];
		[progressTextField setStringValue:@"Processing Audio Data…"];
		[progressTextField setEditable:NO];
		[progressTextField setDrawsBackground:NO];
		[progressTextField setBordered:NO];
		[progressTextField setAlignment:NSLeftTextAlignment];
		
		[[progressWindow contentView] addSubview:progressIndicator];
		[[progressWindow contentView] addSubview:cancelButton];
		[[progressWindow contentView] addSubview:progressTextField];
	}
	return progressWindow;
}


@end
