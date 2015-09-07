//
//  PluginDataSource.m
//  ChronoViz
//
//  Created by Adam Fouse on 1/6/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "PluginDataSource.h"

@implementation PluginDataSource

+(NSString*)dataTypeName
{
	return @"Plugin";
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
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{  
        self.local = YES;
        self.timeCoded = YES;
	}
    return self;
}


@end
