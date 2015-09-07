//
//  InternalDataSource.h
//  ChronoViz
//
//  Created by Adam Fouse on 7/31/12.
//
//

#import "DataSource.h"

@interface InternalDataSource : DataSource {
    id originalDataSource;
    NSString *originalDataSourceID;
}

@property(retain) id originalDataSource;

@end
