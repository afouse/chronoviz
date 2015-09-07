//
//  EthnographerProject.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/10/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class EthnographerTemplate;

@interface EthnographerProject : NSObject {

	NSString* projectName;
	NSString* mappingsFile;
	NSMutableArray *templates;
    NSMutableArray *sessions;
    NSArray *visibleTemplates;
	
}

@property(copy) NSString* projectName;
@property(copy) NSString* mappingsFile;

- (id)initWithMappingsFile:(NSString*)theMappingsFile;

- (NSArray*)templates;
- (NSArray*)sessions;

- (EthnographerTemplate*)templateForPage:(NSString*)page;

- (void)reload;
- (void)saveTemplates;

@end
