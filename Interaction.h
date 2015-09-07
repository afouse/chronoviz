//
//  Interaction.h
//  Annotation
//
//  Created by Adam Fouse on 11/19/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>

@interface Interaction : NSObject {
	QTTime movieTime;
	// seconds since start
	double sessionTime;
	NSString* source;
}

@property(retain) NSString* source;

- (QTTime)movieTime;
- (double)sessionTime;
- (NSString *)logOutput;
- (NSXMLElement *)xmlElement;
- (int)type;
- (NSString *)description;

+ (NSString *)typeString;


@end
