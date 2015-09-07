//
//  DPTimeUtilities.c
//  ChronoViz
//
//  Created by Adam Fouse on 11/18/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPTimeUtilities.h"
#import <QTKit/QTKit.h>

int dpQTTimeValueSort( id obj1, id obj2, void *context ) {
	
	QTTime time1 = [(NSValue*)obj1 QTTimeValue];
	QTTime time2 = [(NSValue*)obj2 QTTimeValue];
	
	return QTTimeCompare(time1,time2);
}
