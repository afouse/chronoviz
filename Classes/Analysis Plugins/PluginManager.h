//
//  PluginManager.h
//  Annotation
//
//  Created by Adam Fouse on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PluginScript;
@class AnnotationDataAnalysisPlugin;
@class PluginDataSource;

@interface PluginManager : NSObject {

	NSMutableArray *plugins;
	NSMutableArray *pluginNames;
	NSMutableArray *pluginScripts;
	NSArray *pluginDirectories;
    NSMutableDictionary *pluginDataSources;
	
	NSPipe *pipe;
	NSFileHandle *pipeReadHandle;
	
	NSString *tempDirectory;
	
}

+(NSString*)userPluginsDirectory;
+(void)openUserPluginsDirectory;
+(PluginManager*)defaultPluginManager;
-(void)reloadPlugins;
-(NSArray*)plugins;
-(void)runPlugin:(id)sender;

-(PluginDataSource*)dataSourceForPlugin:(AnnotationDataAnalysisPlugin*)plugin;

-(NSArray*)pluginScripts;
-(void)addPluginScript:(PluginScript*)script;
-(void)deletePluginScript:(PluginScript*)script;

-(void)saveScripts;
-(void)saveScript:(PluginScript*)script;

@end
