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

- (AVAsset*)loadMovie
{
	if(movie)
	{
		return movie;
	}
    
    NSURL* fileURL = [NSURL fileURLWithPath:videoFile];
    AVAsset *asset = [AVAsset assetWithURL:fileURL];
    NSArray *assetKeysToLoadAndTest = @[@"playable", @"hasProtectedContent", @"tracks"];
    [asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
        
        // The asset invokes its completion handler on an arbitrary queue when loading is complete.
        // Because we want to access our AVPlayer in our ensuing set-up, we must dispatch our handler to the main queue.
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            [self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
            
        });
        
    }];
    
    if(asset == nil)
    {
        NSLog(@"Error loading movie: %@",videoFile);
    }
    
    [self setMovie:asset];
    
    return asset;
}

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys
{
    // This method is called when the AVAsset for our URL has completing the loading of the values of the specified array of keys.
    // We set up playback of the asset here.
    
    // First test whether the values of each of the keys we need have been successfully loaded.
    for (NSString *key in keys)
    {
        NSError *error = nil;
        
        if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed)
        {
            NSLog(@"Error loading movie: %@",[error localizedDescription]);
            return;
        }
    }
    
    loaded = true;
}



- (AVAsset*)movie
{
	return movie;
}

- (void)setMovie:(AVAsset *)theMovie
{
	[theMovie retain];
	[movie release];
	movie = theMovie;
}


-(void)setOffset:(CMTime)cmtime
{
	if(CMTimeCompare(cmtime, offset) != NSOrderedSame)
	{
		[self willChangeValueForKey:@"startTime"];
		[self willChangeValueForKey:@"offset"];
		
		offset = cmtime;
        
        NSTimeInterval offsetInterval = CMTimeGetSeconds(cmtime);
		[startDate release];
		NSDate *documentStartDate = [[[AnnotationDocument currentDocument] videoProperties] startDate];
		startDate = [[NSDate alloc] initWithTimeInterval:offsetInterval sinceDate:documentStartDate];
		
        startTime = -offsetInterval;
        
		[self didChangeValueForKey:@"offset"];
		[self didChangeValueForKey:@"startTime"];
	}
}

- (CMTime)offset
{
	return offset;
}

- (NSTimeInterval)startTime
{
    return startTime;
}

- (void)setStartTime:(NSTimeInterval)theStartTime
{
    [self setOffset:CMTimeMakeWithSeconds(-theStartTime,[[AnnotationDocument currentDocument] defaultTimebase])];
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
            
            offset = kCMTimeZero;
            
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

- (void)encodeWithCoder:(NSCoder *)coder
{	
    [coder encodeObject:self.uuid forKey:@"PrismVideoPropertiesUUID"];
	[coder encodeObject:videoFile forKey:@"PrismVideoPropertiesFileName"];
	[coder encodeObject:title forKey:@"PrismVideoPropertiesTitle"];
	[coder encodeObject:description forKey:@"PrismVideoPropertiesDescription"];
	[coder encodeObject:startDate forKey:@"PrismVideoPropertiesStartTime"];
	[coder encodeCMTime:offset forKey:@"PrismVideoPropertiesOffset"];
	[coder encodeBool:[self enabled] forKey:@"PrismVideoPropertiesEnabled"];
    [coder encodeBool:[self muted] forKey:@"PrismVideoPropertiesMuted"];
    
	NSMutableString *audioCSV;

	
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
		[self setOffset:[coder decodeCMTimeForKey:@"PrismVideoPropertiesOffset"]];
		[self setStartDate:[coder decodeObjectForKey:@"PrismVideoPropertiesStartTime"]];
		[self setEnabled:[coder decodeBoolForKey:@"PrismVideoPropertiesEnabled"]];
//		[self setLocalVideo:[coder decodeBoolForKey:@"PrismVideoPropertiesLocalVideo"]];
		
		if(offset.value == 0)
		{
			offset = kCMTimeZero;
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




@end
