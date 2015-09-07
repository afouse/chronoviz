//
//  CompoundDataSource.h
//  ChronoViz
//
//  Created by Adam Fouse on 7/12/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataSource.h"

@interface CompoundDataSource : DataSource {

	NSMutableArray *dataSources;
	
}

- (id) init;
- (void)addDataSource:(DataSource*)source;
- (void)removeDataSource:(DataSource*)source;
- (NSArray*)dataSources;

@end
