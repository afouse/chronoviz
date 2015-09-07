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
		
        if (NO == continueExport) goto bail;
    }
    
    // clone the movie and see if we can migrate it to a worker thread for extraction
    cloneHandle = NewHandle(0);
    if (NULL == cloneHandle) { goto bail; }
	
    err = PutMovieIntoHandle([movie quickTimeMovie], cloneHandle);
    if (err) goto bail;
    
    err = NewMovieFromHandle(&mCloneMovie, cloneHandle, newMovieActive, NULL);
    if (err != noErr || mCloneMovie == NULL) goto bail;
    
    // if we couldn't migrate this movie, export from the movie on the main thread
    if (DetachMovieFromCurrentThread(mCloneMovie) == noErr) {
        extractionOnWorkerThread = YES;
    } else {
        DisposeMovie(mCloneMovie);
        mCloneMovie = NULL;
    }
    
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
	
bail:
	
    if (cloneHandle) DisposeHandle(cloneHandle);
    
	return NO;
}

// this method will be performed on a background thread
- (void)exportOnWorkerThread:(id)inObject
{
#pragma unused(inObject)
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    OSStatus err;
	
	[NSThread setThreadPriority:[NSThread threadPriority]+.1];
    
	// attach the movie to this thread
	err = EnterMoviesOnThread(0);
	if (err) goto bail;
	
	err = AttachMovieToCurrentThread(mCloneMovie);
	if (err) goto bail;
    
	

	UInt32 sampleCount;
	float* samples;
	
	OSErr						error; 
	//	Handle						dataRef; 
	//	OSType						dataRefType; 
	//	CFURLRef					fileLocation;
	Movie						soundToPlay;
	MovieAudioExtractionRef		extractionSessionRef = nil;
	AudioChannelLayout*			layout			 = nil;
	UInt32						size				= 0;
	AudioStreamBasicDescription	asbd;
	
	soundToPlay = mCloneMovie;
	
//	SetMovieActive(soundToPlay, TRUE);
	
	NSLog(@"Beginning extraction session...");
	error = MovieAudioExtractionBegin(soundToPlay, 0, &extractionSessionRef); 

	error = MovieAudioExtractionGetPropertyInfo(extractionSessionRef,
												kQTPropertyClass_MovieAudioExtraction_Audio,
												kQTMovieAudioExtractionAudioPropertyID_AudioChannelLayout,
												NULL, &size, NULL);
	
	if (error == noErr) {
		// Allocate memory for the channel layout
		layout = (AudioChannelLayout *) calloc(1, size);
		if (layout == nil) {
			error = memFullErr;
			NSLog(@"Oops, out of memory");
		}
		// Get the layout for the current extraction configuration.
		// This will have already been expanded into channel descriptions.
		//NSLog(@"Getting property...");
		error = MovieAudioExtractionGetProperty(extractionSessionRef,
												kQTPropertyClass_MovieAudioExtraction_Audio,
												kQTMovieAudioExtractionAudioPropertyID_AudioChannelLayout,
												size, layout, nil);   
	}
	
	//NSLog(@"Getting audio stream basic description (absd)...");
	error = MovieAudioExtractionGetProperty(extractionSessionRef,
											kQTPropertyClass_MovieAudioExtraction_Audio,
											kQTMovieAudioExtractionAudioPropertyID_AudioStreamBasicDescription,
											sizeof (asbd), &asbd, nil);
	
	if (asbd.mChannelsPerFrame != 2) {
		//NSLog(@"Cannot import non-stereo audio!");
	}
	
	asbd.mFormatFlags = kAudioFormatFlagIsFloat |
	kAudioFormatFlagIsPacked |
	kAudioFormatFlagsNativeEndian; // NOT kAudioFormatFlagIsNonInterleaved!
	//asbd.mChannelsPerFrame = 2;
	asbd.mBitsPerChannel = sizeof(float) * 8;
	asbd.mBytesPerFrame = sizeof(float) * asbd.mChannelsPerFrame;
	asbd.mBytesPerPacket = asbd.mBytesPerFrame;
	
	//NSLog(@"Setting new asbd...");
	error = MovieAudioExtractionSetProperty(extractionSessionRef,
											kQTPropertyClass_MovieAudioExtraction_Audio,
											kQTMovieAudioExtractionAudioPropertyID_AudioStreamBasicDescription,
											sizeof (asbd), &asbd);
	NSTimeInterval duration;
	QTGetTimeInterval(subsetTime.duration, &duration);
	float				numFramesF = asbd.mSampleRate * duration; //((float) GetMovieDuration(soundToPlay) / (float) GetMovieTimeScale(soundToPlay));
	UInt32				numFrames				= (UInt32) numFramesF;
	NSLog(@"numFrames is %lu",numFrames);
	
	if(numFrames == 0)
	{
		NSLog(@"Ending extraction session...");
		error = MovieAudioExtractionEnd(extractionSessionRef);
		NSLog(@"   %d",error);
		return;
	}
	
	UInt32				extractionFlags			= 0;
	AudioBufferList*	buffer					= calloc(sizeof(AudioBufferList), 1);
	
	buffer->mNumberBuffers = 1;
	buffer->mBuffers[0].mNumberChannels = asbd.mChannelsPerFrame;
	buffer->mBuffers[0].mDataByteSize = sizeof(float) * buffer->mBuffers[0].mNumberChannels * numFrames;
	
	samples = calloc(buffer->mBuffers[0].mDataByteSize, 1);
	buffer->mBuffers[0].mData = samples;
	sampleCount = numFrames * buffer->mBuffers[0].mNumberChannels;
	
	NSTimeInterval start;
	QTGetTimeInterval(subsetTime.time, &start);
	TimeRecord timeRec;
	timeRec.scale	= GetMovieTimeScale(soundToPlay);
	timeRec.base	= NULL;
	timeRec.value.hi = 0;
	timeRec.value.lo = start * timeRec.scale;
	// Set the extraction current time.  The duration will 
	// be determined by how much is pulled.
	error = MovieAudioExtractionSetProperty(extractionSessionRef,
										  kQTPropertyClass_MovieAudioExtraction_Movie,
										  kQTMovieAudioExtractionMoviePropertyID_CurrentTime,
										  sizeof(TimeRecord), &timeRec);
	
	UInt32 totalFrames = 0;
	UInt32 loadSize = (numFrames/subsetSize) * 50;
	UInt32 loadFrames = loadSize;
	
	float loadLoops = numFrames/loadSize;
	float loadLoopCount = 1;
	
	int iterationSize = (double)sampleCount/subsetSize;
    sampleSize = (float)iterationSize / (asbd.mSampleRate * buffer->mBuffers[0].mNumberChannels);
	
	keepExtracting = YES;
	
	while(totalFrames < numFrames)
	{
		error = MovieAudioExtractionFillBuffer(extractionSessionRef, &loadFrames, buffer, &extractionFlags);
		//NSLog(@"loaded %d frames",loadFrames);
		
		totalFrames += loadFrames;
		
		UInt32 tempSampleCount = loadFrames * buffer->mBuffers[0].mNumberChannels;
		
		int i;
		float bucketMax = -FLT_MAX;
        double bucketTotal = 0;
		int bucketSize = 0;
		for(i = 0; i < tempSampleCount; i++)
		{
			bucketMax = fmax(bucketMax, samples[i]);
            bucketTotal += samples[i];
			bucketSize++;
			if(bucketSize == iterationSize)
			{
				if(!delegate || [delegate dataSourceCancelLoad] || !keepExtracting)
				{
					break;
				}
				else
				{
                    if(subsetMethod == DPSubsetMethodMax)
                    {
                        [subsetArray addObject:[NSNumber numberWithFloat:bucketMax]];
                    }
                    else if (subsetMethod == DPSubsetMethodAverage)
                    {
                        [subsetArray addObject:[NSNumber numberWithFloat:(bucketTotal/bucketSize)]];
                    }
                    else
                    {
                        [subsetArray addObject:[NSNumber numberWithFloat:samples[i]]];
                    }
                    
					bucketSize = 0;
                    bucketTotal = 0;
					bucketMax = -FLT_MAX;
					if([subsetArray count] > subsetSize)
					{
						break;
					}	
				}
			}
		}
		
		[delegate dataSourceLoadStatus:(loadLoopCount/loadLoops)];
		loadLoopCount++;
		
		if(!delegate || [delegate dataSourceCancelLoad] || (loadFrames < loadSize) || !keepExtracting)
		{
			break;
		}
	}
	
	free(samples);
	
	NSLog(@"total frames: %lu",totalFrames);
	NSLog(@"total buckets: %i",[subsetArray count]);
	
	[delegate dataSourceLoadFinished];

	NSLog(@"Ending extraction session...");
	error = MovieAudioExtractionEnd(extractionSessionRef);
	NSLog(@"   %d",error);
	
	NSLog(@"Loaded %lu samples",sampleCount);

done:
	
    // detach the exported movie from this thread
	DetachMovieFromCurrentThread(mCloneMovie);
    ExitMoviesOnThread(); 

bail:
    [pool release];
}


// import from a URL, such as file:///test.mov
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
    
	UInt32 sampleCount;
	float* samples;
	
	OSErr						error; 
	//	Handle						dataRef; 
	//	OSType						dataRefType; 
	//	CFURLRef					fileLocation;
	Movie						soundToPlay;
	MovieAudioExtractionRef		extractionSessionRef = nil;
	AudioChannelLayout*			layout			 = nil;
	UInt32						size				= 0;
	AudioStreamBasicDescription	asbd;
	
	EnterMovies();
	
	//	NSLog(@"Setting fileLocation...");
	//	fileLocation = CFURLCreateWithString(NULL, path, NULL);
	
	//	NSLog(@"Creating new data reference...");
	//	error = QTNewDataReferenceFromCFURL(fileLocation, 0, &dataRef, &dataRefType);
	//	NSLog(@"   %d",error);
	
	//	NSLog(@"Creating new movie...");
	//	short fileID = movieInDataForkResID; 
	//	short flags = 0; 
	//	error = NewMovieFromDataRef(&soundToPlay, flags, &fileID, dataRef, dataRefType);
	//	NSLog(@"   %d",error);
	
	//QTMovie* movie = [self copy];
	soundToPlay = [movie quickTimeMovie];
	
	SetMovieActive(soundToPlay, TRUE);
	
	NSLog(@"Beginning extraction session...");
	error = MovieAudioExtractionBegin(soundToPlay, 0, &extractionSessionRef); 
	//NSLog(@"   %d",error);
	
	//NSLog(@"Getting property info...");
	error = MovieAudioExtractionGetPropertyInfo(extractionSessionRef,
												kQTPropertyClass_MovieAudioExtraction_Audio,
												kQTMovieAudioExtractionAudioPropertyID_AudioChannelLayout,
												NULL, &size, NULL);
	//NSLog(@"   %d",error);
	
	if (error == noErr) {
		// Allocate memory for the channel layout
		layout = (AudioChannelLayout *) calloc(1, size);
		if (layout == nil) {
			error = memFullErr;
			NSLog(@"Oops, out of memory");
		}
		// Get the layout for the current extraction configuration.
		// This will have already been expanded into channel descriptions.
		//NSLog(@"Getting property...");
		error = MovieAudioExtractionGetProperty(extractionSessionRef,
												kQTPropertyClass_MovieAudioExtraction_Audio,
												kQTMovieAudioExtractionAudioPropertyID_AudioChannelLayout,
												size, layout, nil);   
		//NSLog(@"   %d",error);
	}
	
	//NSLog(@"Getting audio stream basic description (absd)...");
	error = MovieAudioExtractionGetProperty(extractionSessionRef,
											kQTPropertyClass_MovieAudioExtraction_Audio,
											kQTMovieAudioExtractionAudioPropertyID_AudioStreamBasicDescription,
											sizeof (asbd), &asbd, nil);
	//NSLog(@"   %d",error);
	
	//NSLog(@"   format flags   = %d",asbd.mFormatFlags);
	//NSLog(@"   sample rate    = %f",asbd.mSampleRate);
	//NSLog(@"   b/packet       = %d",asbd.mBytesPerPacket);
	//NSLog(@"   f/packet       = %d",asbd.mFramesPerPacket);
	//NSLog(@"   b/frame        = %d",asbd.mBytesPerFrame);
	//NSLog(@"   channels/frame = %d",asbd.mChannelsPerFrame);
	//NSLog(@"   b/channel      = %d",asbd.mBitsPerChannel);
	
	if (asbd.mChannelsPerFrame != 2) {
		//NSLog(@"Cannot import non-stereo audio!");
	}
	
	asbd.mFormatFlags = kAudioFormatFlagIsFloat |
	kAudioFormatFlagIsPacked |
	kAudioFormatFlagsNativeEndian; // NOT kAudioFormatFlagIsNonInterleaved!
	//asbd.mChannelsPerFrame = 2;
	asbd.mBitsPerChannel = sizeof(float) * 8;
	asbd.mBytesPerFrame = sizeof(float) * asbd.mChannelsPerFrame;
	asbd.mBytesPerPacket = asbd.mBytesPerFrame;
	
	//NSLog(@"Setting new asbd...");
	error = MovieAudioExtractionSetProperty(extractionSessionRef,
											kQTPropertyClass_MovieAudioExtraction_Audio,
											kQTMovieAudioExtractionAudioPropertyID_AudioStreamBasicDescription,
											sizeof (asbd), &asbd);
	//NSLog(@"   %d",error);
	
	
	//NSLog(@"   format flags   = %d",asbd.mFormatFlags);
	//NSLog(@"   sample rate    = %f",asbd.mSampleRate);
	//NSLog(@"   b/packet       = %d",asbd.mBytesPerPacket);
	//NSLog(@"   f/packet       = %d",asbd.mFramesPerPacket);
	//NSLog(@"   b/frame        = %d",asbd.mBytesPerFrame);
	//NSLog(@"   channels/frame = %d",asbd.mChannelsPerFrame);
	//NSLog(@"   b/channel      = %d",asbd.mBitsPerChannel);
	
	float				numFramesF = asbd.mSampleRate * ((float) GetMovieDuration(soundToPlay) / (float) GetMovieTimeScale(soundToPlay));
	UInt32				numFrames				= (UInt32) numFramesF;
	NSLog(@"numFrames is %lu",numFrames);
	
	UInt32				extractionFlags			= 0;
	AudioBufferList*	buffer					= calloc(sizeof(AudioBufferList), 1);
	
	buffer->mNumberBuffers = 1;
	buffer->mBuffers[0].mNumberChannels = asbd.mChannelsPerFrame;
	buffer->mBuffers[0].mDataByteSize = sizeof(float) * buffer->mBuffers[0].mNumberChannels * numFrames;
	
	samples = calloc(buffer->mBuffers[0].mDataByteSize, 1);
	buffer->mBuffers[0].mData = samples;
	sampleCount = numFrames * buffer->mBuffers[0].mNumberChannels;
	
	UInt32 totalFrames = 0;
	UInt32 loadSize = (numFrames/subsetSize) * 50; //100000;
	UInt32 loadFrames = loadSize;
	
	int iterationSize = (double)sampleCount/subsetSize;
	sampleSize = (float)iterationSize / (asbd.mSampleRate * buffer->mBuffers[0].mNumberChannels);
	
	keepExtracting = YES;
	
	while(keepExtracting) //totalFrames < numFrames)
	{
		error = MovieAudioExtractionFillBuffer(extractionSessionRef, &loadFrames, buffer, &extractionFlags);
		//NSLog(@"loaded %d frames",loadFrames);
		
		UInt32 tempSampleCount = loadFrames * buffer->mBuffers[0].mNumberChannels;
		
		int i;
		float bucketMax = -FLT_MAX;
		int bucketSize = 0;
        double bucketTotal = 0;
		for(i = 0; i < tempSampleCount; i++)
		{
			bucketMax = fmax(bucketMax, samples[i]);
            bucketTotal += samples[i];
			bucketSize++;
			if(bucketSize == iterationSize)
			{
                if(subsetMethod == DPSubsetMethodMax)
                {
                    [subsetArray addObject:[NSNumber numberWithFloat:bucketMax]];
                }
                else if (subsetMethod == DPSubsetMethodAverage)
                {
                    [subsetArray addObject:[NSNumber numberWithFloat:(bucketTotal/bucketSize)]];
                }
                else
                {
                    [subsetArray addObject:[NSNumber numberWithFloat:samples[i]]];
                }
                
                bucketSize = 0;
                bucketTotal = 0;
				bucketMax = -FLT_MAX;
			}
		}
		
		totalFrames += loadFrames;
		[progressIndicator setDoubleValue:((double)totalFrames/(double)numFrames) * 100];
		[progressIndicator displayIfNeeded];
		NSLog(@"Percent: %f",((double)totalFrames/(double)numFrames));
		
		//[NSThread sleepForTimeInterval:0.1];
		
		if(loadFrames < loadSize)
		{
			break;
		}
	}
	
	//NSLog(@"Filling buffer of audio...");
	//error = MovieAudioExtractionFillBuffer(extractionSessionRef, &numFrames, buffer, &extractionFlags);
	//NSLog(@"   %d",error);
	//NSLog(@"   Extraction flags = %d (contains %d?)",extractionFlags,kQTMovieAudioExtractionComplete);
 	
	NSLog(@"Ending extraction session...");
	error = MovieAudioExtractionEnd(extractionSessionRef);
	NSLog(@"   %d",error);
	
	//	NSLog(@"ExitMovies...");
	//	ExitMovies();
	
	NSLog(@"Loaded %lu samples",sampleCount);
	
	//	int iterationSize = (double)sampleCount/subsetSize;
	//	
	//	NSMutableArray* subset = [NSMutableArray arrayWithCapacity:subsetSize];
	//	int i;
	//	float bucketMax = -FLT_MAX;
	//	int bucketSize = 0;
	//	for(i = 0; i < sampleCount; i++)
	//	{
	//		bucketMax = fmax(bucketMax, samples[i]);
	//		bucketSize++;
	//		if(bucketSize == iterationSize)
	//		{
	//			[subset addObject:[NSNumber numberWithFloat:bucketMax]];
	//			bucketSize = 0;
	//			bucketMax = -FLT_MAX;
	//		}
	//	}
	
	//	for(i = 0; i < sampleCount; i += iterationSize)
	//	{
	//		//NSLog(@"Adding point: %f",samples[i]);
	//		[subset addObject:[NSNumber numberWithFloat:samples[i]]];
	//	}
	
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
    
	UInt32 sampleCount;
	float* samples;
	
	OSErr						error; 
	Movie						soundToPlay;
	MovieAudioExtractionRef		extractionSessionRef = nil;
	AudioChannelLayout*			layout			 = nil;
	UInt32						size				= 0;
	AudioStreamBasicDescription	asbd;
	
	EnterMovies();
	
	soundToPlay = [movie quickTimeMovie];
	
    float movieDuration = ((float) GetMovieDuration(soundToPlay) / (float) GetMovieTimeScale(soundToPlay));
    
    subsetSize = movieDuration / sampleLength;
    
	if(!subsetArray)
    {
        subsetArray = [[NSMutableArray alloc] initWithCapacity:subsetSize];
    }
    
	SetMovieActive(soundToPlay, TRUE);
	
	NSLog(@"Beginning extraction session...");
	error = MovieAudioExtractionBegin(soundToPlay, 0, &extractionSessionRef); 
	//NSLog(@"   %d",error);
	
	//NSLog(@"Getting property info...");
	error = MovieAudioExtractionGetPropertyInfo(extractionSessionRef,
												kQTPropertyClass_MovieAudioExtraction_Audio,
												kQTMovieAudioExtractionAudioPropertyID_AudioChannelLayout,
												NULL, &size, NULL);
	//NSLog(@"   %d",error);
	
	if (error == noErr) {
		// Allocate memory for the channel layout
		layout = (AudioChannelLayout *) calloc(1, size);
		if (layout == nil) {
			error = memFullErr;
			NSLog(@"Oops, out of memory");
		}
		error = MovieAudioExtractionGetProperty(extractionSessionRef,
												kQTPropertyClass_MovieAudioExtraction_Audio,
												kQTMovieAudioExtractionAudioPropertyID_AudioChannelLayout,
												size, layout, nil);   
		//NSLog(@"   %d",error);
	}
	
	//NSLog(@"Getting audio stream basic description (absd)...");
	error = MovieAudioExtractionGetProperty(extractionSessionRef,
											kQTPropertyClass_MovieAudioExtraction_Audio,
											kQTMovieAudioExtractionAudioPropertyID_AudioStreamBasicDescription,
											sizeof (asbd), &asbd, nil);
	
	if (asbd.mChannelsPerFrame != 2) {
		//NSLog(@"Cannot import non-stereo audio!");
	}
	
	asbd.mFormatFlags = kAudioFormatFlagIsFloat |
	kAudioFormatFlagIsPacked |
	kAudioFormatFlagsNativeEndian; // NOT kAudioFormatFlagIsNonInterleaved!
	asbd.mBitsPerChannel = sizeof(float) * 8;
	asbd.mBytesPerFrame = sizeof(float) * asbd.mChannelsPerFrame;
	asbd.mBytesPerPacket = asbd.mBytesPerFrame;

	error = MovieAudioExtractionSetProperty(extractionSessionRef,
											kQTPropertyClass_MovieAudioExtraction_Audio,
											kQTMovieAudioExtractionAudioPropertyID_AudioStreamBasicDescription,
											sizeof (asbd), &asbd);
	
	float				numFramesF = asbd.mSampleRate * movieDuration;
	UInt32				numFrames				= (UInt32) numFramesF;
	NSLog(@"numFrames is %lu",numFrames);
	
    UInt32 totalFrames = 0;
	UInt32 loadSize = (numFrames/subsetSize) * 50; //100000;
	UInt32 loadFrames = loadSize;
    
	UInt32				extractionFlags			= 0;
	AudioBufferList*	buffer					= calloc(sizeof(AudioBufferList), 1);
	
	buffer->mNumberBuffers = 1;
	buffer->mBuffers[0].mNumberChannels = asbd.mChannelsPerFrame;
	buffer->mBuffers[0].mDataByteSize = sizeof(float) * buffer->mBuffers[0].mNumberChannels * loadFrames;
	
    samples = calloc(buffer->mBuffers[0].mDataByteSize, 1);
	buffer->mBuffers[0].mData = samples;
	sampleCount = numFrames * buffer->mBuffers[0].mNumberChannels;
    
	int iterationSize = (asbd.mSampleRate * buffer->mBuffers[0].mNumberChannels) * sampleLength;
	sampleSize = (float)iterationSize / (asbd.mSampleRate * buffer->mBuffers[0].mNumberChannels);
	
	keepExtracting = YES;
	
	while(keepExtracting) //totalFrames < numFrames)
	{
		error = MovieAudioExtractionFillBuffer(extractionSessionRef, &loadFrames, buffer, &extractionFlags);
		//NSLog(@"loaded %d frames",loadFrames);
		
		UInt32 tempSampleCount = loadFrames * buffer->mBuffers[0].mNumberChannels;
		
		int i;
		float bucketMax = -FLT_MAX;
		int bucketSize = 0;
        double bucketTotal = 0;
		for(i = 0; i < tempSampleCount; i++)
		{
			bucketMax = fmax(bucketMax, samples[i]);
            if (subsetMethod == DPSubsetMethodAverage)
            {
                bucketTotal += samples[i];
            }
            else if (subsetMethod == DPSubsetMethodRMS)
            {
                bucketTotal += (samples[i] * samples[i]);
            }
			bucketSize++;
			if(bucketSize == iterationSize)
			{
                if(subsetMethod == DPSubsetMethodMax)
                {
                    [subsetArray addObject:[NSNumber numberWithFloat:bucketMax]];
                }
                else if (subsetMethod == DPSubsetMethodAverage)
                {
                    [subsetArray addObject:[NSNumber numberWithFloat:(bucketTotal/bucketSize)]];
                }
                else if (subsetMethod == DPSubsetMethodRMS)
                {
                    [subsetArray addObject:[NSNumber numberWithFloat:sqrt((bucketTotal/bucketSize))]];
                }
                else
                {
                    [subsetArray addObject:[NSNumber numberWithFloat:samples[i]]];
                }
                
                bucketSize = 0;
                bucketTotal = 0;
				bucketMax = -FLT_MAX;
			}
		}
		
		totalFrames += loadFrames;
		[progressIndicator setDoubleValue:((double)totalFrames/(double)numFrames) * 100];
		[progressIndicator displayIfNeeded];
		NSLog(@"Percent: %f",((double)totalFrames/(double)numFrames));
		
		//[NSThread sleepForTimeInterval:0.1];
		
		if(loadFrames < loadSize)
		{
			break;
		}
	}
 	
	NSLog(@"Ending extraction session...");
	error = MovieAudioExtractionEnd(extractionSessionRef);
	NSLog(@"   %d",error);
	
	NSLog(@"Loaded %lu samples",sampleCount);
	
    free(samples);
    
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
