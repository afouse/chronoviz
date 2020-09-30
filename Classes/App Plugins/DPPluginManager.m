//
//  DPPluginManager.m
//  ChronoViz
//
//  Created by Adam Fouse on 12/13/11.
//  Copyright (c) 2011 University of California, San Diego. All rights reserved.
//

#import "DPPluginManager.h"
#import "DPAppPlugin.h"
#import "DPAppProxy.h"
#import "AppController.h"
#import "DPConstants.h"
#import "DPSpatialDataPlugin.h"
#import "DPApplicationSupport.h"

@interface DPPluginManager (Interal)

- (void)activatePlugin:(NSString*)path;

@end

@implementation DPPluginManager

- (id)init {
    self = [super init];
    if (self) {
        plugins = [[NSMutableArray alloc] init];
        appProxy = [[DPAppProxy alloc] init];
    }
    return self;
}

- (void)dealloc {
    [appProxy release];
    [plugins release];
    [super dealloc];
}

- (void)loadPlugins
{
    AppController *currentApp = [AppController currentApp];
    
    [currentApp addMenuItem:[NSMenuItem separatorItem] toMenuNamed:@"File"];
    
    DPSpatialDataPlugin *spatialPlugin = [[DPSpatialDataPlugin alloc] initWithAppProxy:appProxy];
    [plugins addObject:spatialPlugin];
    [spatialPlugin release];
    
    
    NSError *err;
	//NSBundle *mainBundle = [NSBundle mainBundle];
    

    NSString *pluginsDir = [[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"PlugIns"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:pluginsDir])
    {
        NSError *err;
        [[NSFileManager defaultManager] createDirectoryAtPath:pluginsDir withIntermediateDirectories:YES attributes:nil error:&err];
    }
    
    NSArray *pluginDirectories = [[NSArray alloc] initWithObjects:pluginsDir,nil];
    
//	NSArray *bundlePlugins = [mainBundle pathsForResourcesOfType:@"chronovizplugin" inDirectory:@"PlugIns"];
//	if([bundlePlugins count] > 0)
//	{
//		[pythonPathArray addObject:[resourcePath stringByAppendingPathComponent:@"PlugIns"]];
//		for(NSString *file in bundlePlugins)
//		{
//			NSString *pluginName = [[file lastPathComponent] stringByDeletingPathExtension];
//			if(NSClassFromString(pluginName) != nil)
//			{
//				[pluginNames addObject:[self createAlternateClass:pluginName]];
//			}
//			else
//			{
//				[pluginNames addObject:pluginName];
//			}
//			
//			NSLog(@"Found plugin in bundle: %@",pluginName);
//		}
//	}
	
	
	// Copy each discovered path into an array after adding
	// the Application Support/Annotation/PlugIns subpath
	for(NSString *currPath in pluginDirectories)
	{
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currPath error:&err];
		for(NSString *file in contents)
		{
			if([[file pathExtension] isEqualToString:@"plugin"] && ([[file lastPathComponent] characterAtIndex:0] != '.'))
			{
                [self activatePlugin:[currPath stringByAppendingPathComponent:file]];
				NSLog(@"Found plugin: %@",file);
			}
		}
	}

    
}


- (void)activatePlugin:(NSString*)path
{
    NSBundle* pluginBundle = [NSBundle bundleWithPath:path];
    
    if (pluginBundle) {
        NSDictionary* pluginDict = [pluginBundle infoDictionary];
        NSString* pluginName = [pluginDict objectForKey:@"NSPrincipalClass"];
        if (pluginName)
        {
            Class pluginClass = NSClassFromString(pluginName);
            if (!pluginClass) 
            {
                pluginClass = [pluginBundle principalClass];
                if ([pluginClass conformsToProtocol:@protocol(DPAppPlugin)] &&
                    [pluginClass isKindOfClass:[NSObject class]]) 
                {
                    NSObject* plugin = [[pluginClass alloc] initWithAppProxy:appProxy];
                    [plugins addObject:plugin];
                    [plugin release];
                }
            }
        }
    }
}

- (void)resetPlugins
{
    for(id<DPAppPlugin> plugin in plugins)
    {
        [plugin reset];
    }
}

@end
