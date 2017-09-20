//
//  VideoProperties.m
//  Annotation
//
//  Created by Adam Fouse on 6/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "VideoProperties.h"
#import "NSColorHexadecimalValue.h"
#import "NSStringParsing.h"
#import "AnnotationCategory.h"
#import "Annotation.h"
#import "AnnotationDocument.h"
#import "DPConstants.h"
#import "AudioExtractor.h"
#import "NSStringUUID.h"
#import <Accelerate/Accelerate.h>

NSString * const DPVideoPropertiesPasteboardType = @"DPVideoPropertiesPasteboardType";

@interface VideoProperties (SerializationSupport)

- (AnnotationCategory*)categoryForName:(NSString*)categoryName;

@end

@interface VideoProperties (MovieLoading)

-(void)handleLoadStateChanged:(QTMovie *)theMovie;
-(void)movieLoadStateChanged:(NSNotification *)notification;

@end

@implementation VideoProperties

@synthesize videoFile;
@synthesize title;
@synthesize description;
@synthesize startDate;
@synthesize enabled;
@synthesize audioSubset;
@synthesize localVideo;
@synthesize uuid;

- (void) dealloc
{
	self.audioSubset = nil;
	[title release];
	[description release];
	[startDate release];
	[categories release];
	[movie release];
    [uuid release];
	[super dealloc];
}

- (id) init
{
	return [self initWithVideoFile:nil];
}

- (id) initWithVideoFile:(NSString*)theVideoFile;
{
	self = [super init];
	if (self != nil) {
		
        uuid = [[NSString stringWithUUID] retain];
        
		if(theVideoFile)
		{
			[self setVideoFile:theVideoFile];
			NSFileManager *manager = [NSFileManager defaultManager];
			NSError *err;
			if([manager fileExistsAtPath:theVideoFile])
			{
				NSDate *creationDate = [[manager attributesOfItemAtPath:theVideoFile error:&err] objectForKey:NSFileCreationDate];
				[self setStartDate:creationDate];
			}
			else
			{
				[self setStartDate:[NSDate date]];
			}
		}
		else
		{
			[self setVideoFile:@""];
			[self setStartDate:[NSDate date]];
		}		

		[self setTitle:@""];
		[self setDescription:@""];
		[self setMovie:nil];
		
		[self setMuted:NO];
		[self setEnabled:YES];
		[self setLocalVideo:NO];
		//[self setCategoryColors:[NSMutableDictionary dictionary]];
		[self setCategories:[NSArray array]];
		offset = kCMTimeZero;
		
	}
	return self;
}

- (BOOL)hasVideo
{
    return ([[movie tracksWithMediaType:AVMediaTypeVideo] count] != 0);
}

- (BOOL)hasAudio
{
	return ([[movie tracksWithMediaType:AVMediaTypeAudio] count] != 0);
}

#pragma mark Movie Loading

- (QTMovie*)loadMovie
{
	if(movie)
	{
		return movie;
	}
	
	BOOL useQuickTimeX = [[NSUserDefaults standardUserDefaults] boolForKey:AFUseQuickTimeXKey];
	
	if ([QTMovie canInitWithFile:videoFile])
	{
		QTMovie *theMovie = nil;
		NSError *err = nil;
		
		if(useQuickTimeX)
		{
			loaded = NO;
			SInt32 major = 0;
			SInt32 minor = 0;   
			Gestalt(gestaltSystemVersionMajor, &major);
			Gestalt(gestaltSystemVersionMinor, &minor);
			if ((major == 10 && minor >= 6) || major >= 11) {
				// For 10.6 or greater
				NSError *error = nil;
				NSNumber *loops = [NSNumber numberWithBool:NO];
				NSNumber *playback = [NSNumber numberWithBool:YES];
				NSDictionary *attributes =
				[NSDictionary dictionaryWithObjectsAndKeys:
				 videoFile, QTMovieFileNameAttribute,
				 loops, QTMovieLoopsAttribute,
				 playback, @"QTMovieOpenForPlaybackAttribute",
				 nil];
				
				NSLog(@"Opening with QuickTime X");
				
				theMovie = [[QTMovie alloc] initWithAttributes:attributes
														 error:&error];
				
			}
		}
		
		// This will be used in 10.5 or if the 10.6 initialization failed
		if(!theMovie)
		{
			NSLog(@"Opening with QuickTime 7");
            
			theMovie = [[QTMovie movieWithFile:videoFile error:&err] retain];
            //[theMovie setAttribute:QTMovieApertureModeClean forKey:QTMovieApertureModeAttribute];
			[theMovie setAttribute:0 forKey:QTMovieLoopsAttribute];
			
		}
		
		[self handleLoadStateChanged:theMovie];
		
        if(!loaded)
        {
    
            [[NSNotificationCenter defaultCenter]
             addObserver:self
             selector:@selector(movieLoadStateChanged:)
             name:QTMovieLoadStateDidChangeNotification
             object:theMovie];
		
		}
		
		while(!loaded)
		{
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		}
		
		
		if(theMovie == nil)
		{
			NSLog(@"Error loading movie: %@",[err localizedDescription]);
		}
		
		[self setMovie:theMovie];
        [theMovie release];
		
		return theMovie;
	}
	else 
	{
		NSLog(@"Can't load movie %@",videoFile);
		return nil;
	}
}

-(void)handleLoadStateChanged:(QTMovie *)theMovie
{
    NSInteger loadState = [[theMovie attributeForKey:QTMovieLoadStateAttribute] longValue];
	
    if (loadState == QTMovieLoadStateError) {
		 /* NSError *err = [movie attributeForKey:QTMovieLoadStateErrorAttribute]; */
		NSLog(@"Load state error");
    }
	
    if (loadState >= QTMovieLoadStateLoaded) {
        /* can query properties here */
        /* for instance, if you need to size a QTMovieView based on the movie's natural size, you can do so now */
        /* you can also put the movie into a view now, even though no media data might yet be available and hence
		 nothing will be drawn into the view */
		loaded = YES;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
	
    if (loadState >= QTMovieLoadStatePlayable) {
        /* can start movie playing here */
    }
    
    if (loadState >= QTMovieLoadStatePlaythroughOK)
    {
        //NSLog(@"Playthrough OK");
    }

    if (loadState >= QTMovieLoadStateComplete)
    {
       //NSLog(@"Load complete");
       // [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

-(void)movieLoadStateChanged:(NSNotification *)notification
{
    QTMovie *theMovie = (QTMovie *)[notification object];
	
    if (theMovie) {
        [self handleLoadStateChanged:theMovie];
    }
}

- (QTMovie*)movie
{
	return movie;
}

- (void)setMovie:(QTMovie *)theMovie
{
	[theMovie retain];
	[movie release];
	movie = theMovie;
	
	[movie setMuted:muted];
}

- (BOOL)muted
{
	if([self movie])
	{
		return [[self movie] muted];
	}
	else
	{
		return muted;
	}
}

- (void)setMuted:(BOOL)mute
{
	if([self movie])
	{
		[[self movie] setMuted:mute];
	}
	muted = mute;
}



-(void)setOffset:(QTTime)qttime
{
	if(QTTimeCompare(qttime, offset) != NSOrderedSame)
	{
		[self willChangeValueForKey:@"startTime"];
		[self willChangeValueForKey:@"offset"];
		
		offset = qttime;
		NSTimeInterval offsetInterval = ((double)qttime.timeValue)/((double)qttime.timeScale);
		[startDate release];
		NSDate *documentStartDate = [[[AnnotationDocument currentDocument] videoProperties] startDate];
		startDate = [[NSDate alloc] initWithTimeInterval:offsetInterval sinceDate:documentStartDate];
		
        startTime = -offsetInterval;
        
		[self didChangeValueForKey:@"offset"];
		[self didChangeValueForKey:@"startTime"];
	}
}

- (QTTime)offset
{
	return offset;
}

- (NSTimeInterval)startTime
{
    return startTime;
}

- (void)setStartTime:(NSTimeInterval)theStartTime
{
    [self setOffset:QTMakeTimeWithTimeInterval(-theStartTime)];
}

- (AnnotationCategory*)categoryForName:(NSString*)categoryName
{
	for(AnnotationCategory *category in categories)
	{
		if([categoryName isEqualToString:[category name]])
		{
			return category;
		}
	}
	return nil;
}

- (NSArray*)categories
{
	return categories;
}

- (void)setCategories:(NSArray*)array
{
	[array retain];
	[categories release];
	categories = array;
}

#pragma mark File Coding

- (id)initFromFile:(NSString*)file
{
    if (self = [super init]) {
    
        @try {
            VideoProperties *temp = (VideoProperties*)[[NSKeyedUnarchiver unarchiveObjectWithFile:file] retain];
            [self release];
            self = temp;
        }
        @catch (NSException *exception) {
            
            NSString *errorDesc = nil;
            NSPropertyListFormat format;
            NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:file];
            NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                                  propertyListFromData:plistXML
                                                  mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                                  format:&format errorDescription:&errorDesc];
            if (!temp) {
                NSLog(@"%@",errorDesc);
                [errorDesc release];
                [self release];
                return nil;
            }
            self.videoFile = [temp objectForKey:@"VideoFile"];
            self.title = [temp objectForKey:@"Title"];
            self.description = [temp objectForKey:@"Description"];
            self.startDate = [temp objectForKey:@"StartTime"];
            
            uuid = [[NSString stringWithUUID] retain];
            
            NSNumber *mutedValue = [temp objectForKey:@"Muted"];
            if(mutedValue)
            {
                [self setMuted:[mutedValue boolValue]];
            }
            else
            {
                [self setMuted:NO];
            }
            
            NSString *audio = [temp objectForKey:@"AudioSubset"];
            if(audio && ([audio length] > 0))
                self.audioSubset = [audio componentsSeparatedByString:@","];
            
            offset = QTZeroTime;
            
            NSMutableArray *categoriesTemp = [NSMutableArray array];
            [self setCategories:categoriesTemp];
            NSArray *categoryNames = [temp objectForKey:@"Categories"];
            NSDictionary *colors = [temp objectForKey:@"CategoryColors"];
            NSDictionary *superCategories = [temp objectForKey:@"ValueCategories"];
            
            for(NSString* categoryName in categoryNames)
            {
                AnnotationCategory *category = [[AnnotationCategory alloc] init];
                category.name = categoryName;
                NSString *color = [colors objectForKey:categoryName];
                if([color length])
                {
                    category.color = [NSColor colorFromHexRGB:color];
                }
                if(superCategories)
                {
                    NSString *superCategoryName = [superCategories objectForKey:categoryName];
                    if([superCategoryName length])
                    {
                        AnnotationCategory *superCategory = [self categoryForName:superCategoryName];
                        [superCategory addValue:category];
                    }
                    else
                    {
                        [categoriesTemp addObject:category];
                    }
                }
                else
                {
                    [categoriesTemp addObject:category];
                }
                
                [category release];
            }
            
        }     
	}
	return self;
}


- (void)saveToFile:(NSString*)file
{
    [NSKeyedArchiver archiveRootObject:self toFile:file];
    
}

//- (NSData*)serialize
//{
//	NSString *errorDesc;
//	
//	NSMutableArray *categoryNames = [NSMutableArray arrayWithCapacity:[categories count]];
//	NSMutableArray *colors = [NSMutableArray arrayWithCapacity:[categories count]];
//	NSMutableArray *valueCategories = [NSMutableArray arrayWithCapacity:[categories count]];
//	for(AnnotationCategory* category in categories)
//	{
//		if([category annotation])
//		{
//			[categoryNames addObject:[category name]];
//			[colors addObject:@""];
//			[valueCategories addObject:@""];
//		}
//		else if([category color])
//		{
//			[categoryNames addObject:[category name]];
//			[colors addObject:[[category color] hexadecimalValueOfAnNSColor]];
//			[valueCategories addObject:@""];
//			for(AnnotationCategory *value in [category values])
//			{
//				[categoryNames addObject:[value name]];
//				[colors addObject:[[value color] hexadecimalValueOfAnNSColor]];
//				[valueCategories addObject:[category name]];
//			}
//		}
//	}
//	
//	NSMutableString *audioCSV;
//	
//	if(audioSubset)
//	{
//		audioCSV = [NSMutableString stringWithCapacity:[audioSubset count]];
//		for(NSNumber *value in audioSubset)
//		{
//			[audioCSV appendFormat:@"%f,",[value floatValue]];
//		}
//	}
//	else
//	{
//		audioCSV = [NSMutableString stringWithString:@""];
//	}
//	
//	
//	NSNumber *mutedValue = [NSNumber numberWithBool:muted];
//	
//	NSDictionary *colorDict = [NSDictionary dictionaryWithObjects:colors forKeys:categoryNames];
//	NSDictionary *categoryDict = [NSDictionary dictionaryWithObjects:valueCategories forKeys:categoryNames];
//	
//    NSDictionary *plistDict = [NSDictionary dictionaryWithObjects:
//							   [NSArray arrayWithObjects: videoFile, title, description, startDate, categoryNames, colorDict, categoryDict, audioCSV, mutedValue, nil]
//														  forKeys:[NSArray arrayWithObjects: @"VideoFile", @"Title", @"Description", @"StartTime", @"Categories", @"CategoryColors",@"ValueCategories", @"AudioSubset",@"Muted",nil]];
//    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict
//																   format:NSPropertyListXMLFormat_v1_0
//														 errorDescription:&errorDesc];
//	if (!plistData) {
//        NSLog(@"%@",errorDesc);
//        [errorDesc release];
//    }
//	
//	return plistData;
//}

- (void)encodeWithCoder:(NSCoder *)coder
{	
    [coder encodeObject:self.uuid forKey:@"PrismVideoPropertiesUUID"];
	[coder encodeObject:videoFile forKey:@"PrismVideoPropertiesFileName"];
	[coder encodeObject:title forKey:@"PrismVideoPropertiesTitle"];
	[coder encodeObject:description forKey:@"PrismVideoPropertiesDescription"];
	[coder encodeObject:startDate forKey:@"PrismVideoPropertiesStartTime"];
	[coder encodeQTTime:offset forKey:@"PrismVideoPropertiesOffset"];
	[coder encodeBool:[self enabled] forKey:@"PrismVideoPropertiesEnabled"];
    
	NSMutableString *audioCSV;
	
	if([self movie])
	{
		[coder encodeBool:[[self movie] muted] forKey:@"PrismVideoPropertiesMuted"];
	}
	
	if(audioSubset)
	{
		audioCSV = [NSMutableString stringWithCapacity:[audioSubset count]];
		for(NSNumber *value in audioSubset)
		{
			[audioCSV appendFormat:@"%f,",[value floatValue]];
		}
	}
	else
	{
		audioCSV = [NSMutableString stringWithString:@""];
	}
	
	[coder encodeObject:audioCSV forKey:@"PrismVideoPropertiesAudioSubset"];
	
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
        uuid = [[coder decodeObjectForKey:@"PrismVideoPropertiesUUID"] retain];
        if(!uuid)
        {
            uuid = [[NSString stringWithUUID] retain];
        }
        
		[self setVideoFile:[coder decodeObjectForKey:@"PrismVideoPropertiesFileName"]];
		[self setTitle:[coder decodeObjectForKey:@"PrismVideoPropertiesTitle"]];
		[self setDescription:[coder decodeObjectForKey:@"PrismVideoPropertiesDescription"]];
		[self setOffset:[coder decodeQTTimeForKey:@"PrismVideoPropertiesOffset"]];
		[self setStartDate:[coder decodeObjectForKey:@"PrismVideoPropertiesStartTime"]];
		[self setEnabled:[coder decodeBoolForKey:@"PrismVideoPropertiesEnabled"]];
//		[self setLocalVideo:[coder decodeBoolForKey:@"PrismVideoPropertiesLocalVideo"]];
		
		if(offset.timeValue == 0)
		{
			offset = QTZeroTime;
		}
		
		[self setMuted:[coder decodeBoolForKey:@"PrismVideoPropertiesMuted"]];
		
		NSString *audio = [coder decodeObjectForKey:@"PrismVideoPropertiesAudioSubset"];
		if(audio && ([audio length] > 0))
			self.audioSubset = [audio componentsSeparatedByString:@","];
		
		[self setMovie:nil];
		
//		QTTime savedOffset = [coder decodeQTTimeForKey:@"PrismVideoPropertiesOffset"];
//		if(savedOffset.timeValue != 0)
//			[self setOffset:savedOffset];
	}
    return self;
}


+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
	BOOL automatic = NO;
	
    if ([theKey isEqualToString:@"offset"] || [theKey isEqualToString:@"startTime"]) {
        automatic=NO;
    } else {
        automatic=[super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}


#pragma mark Auto Alignment



- (NSTimeInterval)computeAlignment:(VideoProperties*)otherProps
{
    
    float          *signal, *filter, *result;
    int32_t         signalStride, filterStride, resultStride;
    uint32_t        lenSignal, filterLength, resultLength;
    uint32_t        i;
    
    
    CGFloat sampleLength = 0.033;
    DPSubsetMethod subsetMethod = DPSubsetMethodRMS;
    
    AudioExtractor *ownExtractor = [[AudioExtractor alloc] initWithQTMovie:[self movie]];
    ownExtractor.subsetMethod = subsetMethod;
    NSArray *ownAudio = [[ownExtractor getAudioSubsetWithSampleLength:sampleLength] retain];
    NSTimeInterval ownSampleSize = ownExtractor.sampleSize;
    [ownExtractor release];

    NSLog(@"Own Audio: %i samples, %f sampleSize",[ownAudio count],ownSampleSize);
    
    AudioExtractor *otherExtractor = [[AudioExtractor alloc] initWithQTMovie:[otherProps movie]];
    otherExtractor.subsetMethod = subsetMethod;
    NSArray *otherAudio = [[otherExtractor getAudioSubsetWithSampleLength:sampleLength] retain];
    NSTimeInterval otherSampleSize = otherExtractor.sampleSize;
    [otherExtractor release];
    
    NSLog(@"Other Audio: %i samples, %f sampleSize",[otherAudio count],otherSampleSize);
    
    
    NSArray *signalArray = ownAudio;
    NSArray *filterArray = otherAudio;
    CGFloat filterMargin = 0;
    
    lenSignal = [signalArray count];
    filterLength = [filterArray count];
    
    CGFloat marginDiff = filterLength - (lenSignal - (1.0/sampleLength * 10));
    if(marginDiff > 0)
    {
        filterMargin = floor(marginDiff/2.0); 
        filterLength -= (filterMargin * 2);
    }
    
    resultLength = lenSignal - filterLength + 1;
    
    signalStride = filterStride = resultStride = 1;
    
    printf("\nConvolution ( resultLength = %d, "
           "filterLength = %d )\n\n", resultLength, filterLength);
    
    /* Allocate memory for the input operands and check its availability. */
    signal = (float *) malloc(lenSignal * sizeof(float));
    filter = (float *) malloc(filterLength * sizeof(float));
    result = (float *) malloc(resultLength * sizeof(float));
    
    
    if (signal == NULL || filter == NULL || result == NULL) {
        printf("\nmalloc failed to allocate memory for the "
               "convolution sample.\n");
        exit(0);
    }
    
    i = 0;
    for(NSNumber *val in signalArray)
    {
        signal[i] = [val floatValue];
        i++;
    }
    
    i = 0;
    for(NSNumber *val in filterArray)
    {
        if((filterMargin == 0) || 
           ((i > filterMargin) &&  (i < (filterMargin + filterLength))))
        {
            filter[i] = [val floatValue];
        }
        i++; 
    }
    
    /* Correlation. */
    vDSP_conv(signal, signalStride, filter, filterStride,
              result, resultStride, resultLength, filterLength);
    
    NSMutableString *output = [[NSMutableString alloc] initWithCapacity:resultLength];
    
    float maxCorr = 0;
    NSTimeInterval maxCorrTime = 0;
    for(i = 0; i < resultLength; i++)
    {
        [output appendFormat:@"%f,%f\n",(i*ownSampleSize),result[i]];
        if(result[i] > maxCorr)
        {
            maxCorr = result[i];
            maxCorrTime = (i - filterMargin)*ownSampleSize;
        }
    }
    
    
    NSError *err = nil;
    
    [[ownAudio description] writeToFile:@"/Users/afouse/ownaudio.csv"
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:&err];

    [[otherAudio description] writeToFile:@"/Users/afouse/otheraudio.csv"
                             atomically:YES
                               encoding:NSUTF8StringEncoding
                                  error:&err];
    
    [output writeToFile:@"/Users/afouse/correlation.csv"
             atomically:YES
               encoding:NSUTF8StringEncoding
                  error:&err];
    [output release];

    if(err)
    {
        NSLog(@"Error writing file: %@",[err localizedDescription]);
    }
    
    NSLog(@"Max Corr: %f Time: %f",maxCorr,maxCorrTime);
    
    
    /* Free allocated memory. */
    free(signal);
    free(filter);
    free(result);
    
    [ownAudio release];
    [otherAudio release];
    
    
    
    return maxCorrTime;
}



@end
