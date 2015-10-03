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

- (id) initWithQTMovie:(QTMovie*)theMovie;
{
	self = [super init];
	if (self != nil) {
		
		
		NSError *error = nil;
		NSURL *url = [[theMovie movieAttributes] objectForKey:QTMovieURLAttribute];
		movie = [[QTMovie movieWithURL:url error:&error] retain];
		subsetMethod = DPSubsetMethodMax;
		//movie = [theMovie retain];
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
	return [self exportAudioSubset:theSubsetSize forRange:QTMakeTimeRange(QTZeroTime, [movie duration])];
}

- (BOOL)exportAudioSubset:(int)theSubsetSize forRange:(QTTimeRange)timeRange
{
    BOOL extractionOnWorkerThread = NO;
    BOOL continueExport = YES;
    Handle cloneHandle = NULL;
	
	OSErr err;
	
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
    
    // clone the movie and see if we can migrate it to a worker thread for extraction
//    cloneHandle = NewHandle(0);
//    if (NULL == cloneHandle) { goto bail; }
//	
//    err = PutMovieIntoHandle([movie quickTimeMovie], cloneHandle);
//    if (err) goto bail;
//    
//    err = NewMovieFromHandle(&mCloneMovie, cloneHandle, newMovieActive, NULL);
//    if (err != noErr || mCloneMovie == NULL) goto bail;
//    
//    // if we couldn't migrate this movie, export from the movie on the main thread
//    if (DetachMovieFromCurrentThread(mCloneMovie) == noErr) {
//        extractionOnWorkerThread = YES;
//    } else {
//        DisposeMovie(mCloneMovie);
//        mCloneMovie = NULL;
//    }
    
    if (extractionOnWorkerThread == YES) {
        // export on a worker thread if we can...
        [NSThread detachNewThreadSelector:@selector(exportOnWorkerThread:) toTarget:self withObject:nil];
    } else {
        // ...if not, we're on the main thread so just call the main-thread worker method
		NSLog(@"Can't export on worker thread");
        //[self exportOnMainThreadCallBack:nil];
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
