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
	if(!DPQuicktimeFileTypes)
	{
		DPQuicktimeFileTypes = [[QTMovie movieFileTypes:QTIncludeCommonTypes] retain];
	}
	//return [DPQuicktimeFileTypes containsObject:[fileName pathExtension]];
	//return [QTMovie canInitWithFile:fileName];
    
    NSString *fileExt = [fileName pathExtension];
    for(NSString *ext in DPQuicktimeFileTypes)
    {
        if([fileExt caseInsensitiveCompare:ext] == NSOrderedSame)
        {
            return YES;
        }
    }
    
    return NO;
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
			range.time = [videoProperties offset];
			range.time.timeValue = -range.time.timeValue;
			range.duration = [[videoProperties movie] duration];
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
	if([QTMovie canInitWithFile:theFile])
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
		range.time = [videoProperties offset];
		range.time.timeValue = -range.time.timeValue;
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:DPDataSetRangeChangeNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:DataSourceUpdatedNotification object:self];
}

-(void)setRange:(QTTimeRange)newRange
{
	range = newRange;
	QTTime offset = range.time;
	offset.timeValue = -offset.timeValue;
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

-(QTTime)timeForRowArray:(NSArray*)row;
{
	return QTZeroTime;
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

