//
//  PluginParameter.h
//  Annotation
//
//  Created by Adam Fouse on 9/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PluginParameter : NSObject <NSCoding> {
	NSString *parameterName;
	CGFloat parameterValue;
	CGFloat maxValue;
	CGFloat minValue;
	NSArray *possibleValues;
}

@property(retain) NSString* parameterName;
@property(copy) NSArray* possibleValues;
@property CGFloat parameterValue;
@property CGFloat maxValue;
@property CGFloat minValue;

-(float)floatValue;

@end
