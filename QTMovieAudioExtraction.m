//
//  QTMovieAudioExtraction.m
//  Annotation
//
//  Created by Adam Fouse on 12/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <QuickTime/QuickTime.h>
#import "QTMovieAudioExtraction.h"
#import "AIFFWriter.h"
#import "AudioConverter.h"
#import "AudioVisualizer.h"
#import "DataSource.h"

@implementation QTMovie (AudioExtraction)

- (BOOL)shouldContinueOperationWithProgressInfo:(id)inProgressInfo
{
	NSLog(@"Progress...");
	return YES;
}

- (NSArray*) extractAudioSubset:(NSInteger)subsetSize
{
	AIFFWriter* mAIFFWriter = [[AIFFWriter alloc] init];
	[mAIFFWriter setDelegate:self];
	[mAIFFWriter exportFromMovie:self toFile:@"/Users/afouse/tempaudio.aiff"];
	
	NSLog(@"Loaded samples");
	
	char* samples = [mAIFFWriter buffer];
	
	UInt32 sampleCount = [mAIFFWriter bufferSize];
	
	int iterationSize = (double)sampleCount/subsetSize;
	
	NSMutableArray* subset = [NSMutableArray arrayWithCapacity:subsetSize];
	int i;
	float bucketMax = -FLT_MAX;
	int bucketSize = 0;
	for(i = 0; i < sampleCount; i++)
	{
		bucketMax = fmax(bucketMax, samples[i]);
		bucketSize++;
		if(bucketSize == iterationSize)
		{
			[subset addObject:[NSNumber numberWithFloat:bucketMax]];
			bucketSize = 0;
			bucketMax = -FLT_MAX;
		}
	}
	
	for(i = 0; i < sampleCount; i += iterationSize)
	{
		//NSLog(@"Adding point: %f",samples[i]);
		[subset addObject:[NSNumber numberWithFloat:samples[i]]];
	}
		
	return [NSArray arrayWithArray:subset];
}



- (NSArray*) getAudioSubset:(NSInteger)subsetSize
{
	return [self getAudioSubset:subsetSize withCallback:nil];
}

- (NSArray*) getAudioSubset:(NSInteger)subsetSize withCallback:(AudioVisualizer*)viz
{
    return [self getAudioSubset:subsetSize withCallback:viz usingSubsetMethod:DPSubsetMethodMax];
}


- (NSArray*) getAudioSubset:(NSInteger)subsetSize withCallback:(AudioVisualizer*)viz usingSubsetMethod:(DPSubsetMethod)subsetMethod
{
	if(NO)
	{
		return [self extractAudioSubset:subsetSize];
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
	soundToPlay = [self quickTimeMovie];

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
	UInt32 loadSize = 100000;
	UInt32 loadFrames = loadSize;
	
	int iterationSize = (double)sampleCount/subsetSize;
	
	NSMutableArray* subset = [NSMutableArray arrayWithCapacity:subsetSize];
	
    float bucketMax = -FLT_MAX;
    double bucketTotal = 0;
	while(totalFrames < numFrames)
	{
		error = MovieAudioExtractionFillBuffer(extractionSessionRef, &loadFrames, buffer, &extractionFlags);
		//NSLog(@"loaded %d frames",loadFrames);
		
		UInt32 tempSampleCount = loadFrames * buffer->mBuffers[0].mNumberChannels;
		
		int i;
		bucketMax = -FLT_MAX;
        bucketTotal = 0;
		int bucketSize = 0;
		for(i = 0; i < tempSampleCount; i++)
		{
			bucketMax = fmax(bucketMax, samples[i]);
            bucketTotal += samples[i];
			bucketSize++;
			if(bucketSize == iterationSize)
			{
                if(subsetMethod == DPSubsetMethodMax)
                {
                    [subset addObject:[NSNumber numberWithFloat:bucketMax]];
                }
                else if (subsetMethod == DPSubsetMethodAverage)
                {
                    [subset addObject:[NSNumber numberWithFloat:(bucketTotal/bucketSize)]];
                }
                else
                {
                    [subset addObject:[NSNumber numberWithFloat:samples[i]]];
                }
				
				bucketSize = 0;
				bucketMax = -FLT_MAX;
                bucketTotal = 0;
			}
		}
		
		if(viz)
		{
			//[viz setData:subset];
		}
		
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
	
	
	return [NSArray arrayWithArray:subset];
	
}


@end
