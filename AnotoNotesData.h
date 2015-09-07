//
//  AnotoNotesData.h
//  DataPrism
//
//  Created by Adam Fouse on 3/19/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TimeCodedData.h"

@interface AnotoNotesData : TimeCodedData {

	NSMutableArray *traces;
	
}

@property(retain) NSArray* traces;

@end
