//
//  TimeCodedDataPoint.h
//  Annotation
//
//  Created by Adam Fouse on 8/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface TimeCodedDataPoint : NSObject <NSCoding> {
	QTTime time;
	double value;	
}

@property QTTime time;
@property double value;

-(NSString*)csvString;
-(double)numericValue;

-(NSTimeInterval)seconds;

@end
