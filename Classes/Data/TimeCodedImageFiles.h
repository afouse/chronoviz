//
//  TimeCodedStringData.h
//  Annotation
//
//  Created by Adam Fouse on 11/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeSeriesData.h"
@class TimeCodedString;

@interface TimeCodedImageFiles : TimeSeriesData {

    BOOL relativeToSource;
    
}

@property BOOL relativeToSource;

- (NSString*)imageFileForTimeCodedString:(TimeCodedString*)dataPoint;

@end
