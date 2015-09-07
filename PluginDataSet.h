//
//  PluginDataSet.h
//  DataPrism
//
//  Created by Adam Fouse on 7/22/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TimeCodedData;

@interface PluginDataSet : NSObject {
	NSString *name;
	NSString *defaultVariable;
	
	TimeCodedData *dataSet;
}

@property(retain) NSString* name;
@property(retain) NSString* defaultVariable;
@property(assign) TimeCodedData* dataSet;

-(NSArray*)dataPoints;

@end
