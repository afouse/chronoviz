//
//  InternalDataSource.m
//  ChronoViz
//
//  Created by Adam Fouse on 7/31/12.
//
//

#import "InternalDataSource.h"
#import "TimeCodedData.h"
#import "AnnotationDocument.h"

@implementation InternalDataSource

+(NSString*)dataTypeName
{
	return @"Internal";
}

+(BOOL)validateFileName:(NSString*)fileName
{
	return NO;
}

-(id)initWithPath:(NSString*)theFile
{
	self = [super initWithPath:theFile];
	if (self != nil) {
        self.local = YES;
        self.timeCoded = YES;
        self.originalDataSource = nil;
        originalDataSourceID = [@"" retain];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
        self.local = YES;
        self.timeCoded = YES;
        
        originalDataSourceID = [[coder decodeObjectForKey:@"InternalDataSourceOriginalDataSourceID"] retain];
	}
    return self;
}

- (void)dealloc
{
    [originalDataSourceID release];
    [originalDataSource release];
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	[coder encodeObject:originalDataSourceID forKey:@"InternalDataSourceOriginalDataSourceID"];
}

- (DataSource*)originalDataSource
{
    if(!originalDataSource && ([originalDataSourceID length] > 0))
    {
        for(DataSource *source in [[AnnotationDocument currentDocument] dataSources])
        {
            if([[source uuid] isEqualToString:originalDataSourceID])
            {
                originalDataSource = [source retain];
                break;
            }
        }
        for(TimeCodedData *data in [[AnnotationDocument currentDocument] dataSets])
        {
            if([[data uuid] isEqualToString:originalDataSourceID])
            {
                originalDataSource = [data retain];
            }
        }
    }
    return originalDataSource;
}

- (void)setOriginalDataSource:(id)dataSource
{
    if([dataSource respondsToSelector:@selector(uuid)])
    {
        [originalDataSource release];
        originalDataSource = [dataSource retain];
        
        [originalDataSourceID release];
        originalDataSourceID = [[originalDataSource uuid] retain];
    }
}

-(void)removeDataSet:(TimeCodedData*)dataSet
{
	if([dataSets containsObject:dataSet])
	{        
		[dataSet setSource:nil];
		[dataSets removeObject:dataSet];
    }
}

@end
