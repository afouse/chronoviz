//
//  PluginScript.h
//  Annotation
//
//  Created by Adam Fouse on 11/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PluginScript : NSObject {

	NSString *name;
	NSMutableArray *pluginConfigurations;
	
	NSString *fileName;
}

@property(retain) NSString* name;
@property(retain) NSString* fileName;
@property(readonly) NSMutableArray* pluginConfigurations;

@end
