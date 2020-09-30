//
//  VideoDataSource.m
//  ChronoViz
//
//  Created by Adam Fouse on 7/13/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "VideoDataSource.h"
#import "VideoProperties.h"
#import "DPConstants.h"

static NSArray *DPQuicktimeFileTypes = nil; 

@interface AudioDataSource : VideoDataSource {}

+ (NSString*)dataTypeName;

@end


@implementation VideoDataSource

@synthesize videoProperties;

+(NSString*)dataTypeName
{
	return @"Video File";
}


+(BOOL)validateFileName:(NSString*)fileName
{
    CFStringRef pathExtension = (CFStringRef)[fileName pathExtension];
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    
    return [[AVURLAsset audiovisualTypes] containsObject:(NSString*)type];
}

-(id)initWithVideoProperties:(VideoProperties*)props
{
	self = [super initWithPath:[props videoFile]];
	if (self != nil) {
		
		if(![props movie])
		{
			[props loadMovie];
		}
		
		if (![props hasVideo] && ![self isKindOfClass:[AudioDataSource class]])
		{
			[self release];
			return [[AudioDataSource alloc] initWithVideoProperties:props];
		}
		else {
			[self setPredefinedTimeCode:YES];
			[self setTimeCoded:YES];
			videoProperties = [props retain];
			range.start = [videoProperties offset];
			range.start.value = -range.start.value;
			range.duration = [[[videoProperties movie] currentItem] duration];
			[videoProperties addObserver:self
							  forKeyPath:@"offset"
								 options:0
								 context:NULL];	
		}
	}
	return self;
}

-(id)initWithPath:(NSString*)theFile
{
	VideoProperties *props = nil;
	if([VideoDataSource validateFileName:theFile])
	{
		props = [[[VideoProperties alloc] initWithVideoFile:theFile] autorelease];
		[props setTitle:[[theFile lastPathComponent] stringByDeletingPathExtension]];
		return [self initWithVideoProperties:props];
	}
	else
	{
		[self release];
	}
	return nil;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:videoProperties forKey:@"AnnotationDataSourceVideoProperties"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		videoProperties = [[coder decodeObjectForKey:@"AnnotationDataSourceVideoProperties"] retain];
        [videoProperties addObserver:self
                          forKeyPath:@"offset"
                             options:0
                             context:NULL];	
	}
    return self;
}

- (void) dealloc
{
    [videoProperties removeObserver:self forKeyPath:@"offset"];
	[videoProperties release];
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"offset"])
	{
		range.start = [videoProperties offset];
		range.start.value = -range.start.value;
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:DPDataSetRangeChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:DataSourceUpdatedNotification object:self];
}

-(void)setRange:(CMTimeRange)newRange
{
	range = newRange;
	CMTime offset = range.start;
	offset.value = -offset.value;
	[videoProperties setOffset:offset];
	[[NSNotificationCenter defaultCenter] postNotificationName:DPDataSetRangeChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:DataSourceUpdatedNotification object:self];
}

-(NSArray*)possibleDataTypes
{
	return [NSArray array];
}

-(NSArray*)importVariables:(NSArray*)variables asTypes:(NSArray*)types
{
	return [NSArray array];
}

-(CMTime)timeForRowArray:(NSArray*)row;
{
	return kCMTimeZero;
}

-(NSArray*)dataArray
{
	if(!dataArray)
	{
		[self setDataArray:[NSArray array]];
	}
	return dataArray;
}

@end

@implementation AudioDataSource

+(NSString*)dataTypeName
{
	return @"Audio File";
}

@end

