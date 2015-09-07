//
//  PluginManager.m
//  Annotation
//
//  Created by Adam Fouse on 9/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PluginManager.h"
#import "AnnotationDataAnalysisPlugin.h"
#import "PluginDataSet.h"
#import "PluginDataSource.h"
#import "TimeCodedData.h"
#import "AppController.h"
#import "AnnotationDocument.h"
#import "PluginConfiguration.h"
#import "PluginConfigurationView.h"
#import "PluginScript.h"
#import "NSStringFileManagement.h"
#import "DPConsole.h"
#import "DPApplicationSupport.h"
#import <Python/Python.h>

static PluginManager* defaultPluginManager = nil;

@interface PluginManager (Reloading)

- (BOOL)checkDataSets:(AnnotationDataAnalysisPlugin*)plugin;

- (NSString*)tempDirectory;
- (NSString*)createAlternateClass:(NSString*)className;

@end

@implementation PluginManager

+(PluginManager*)defaultPluginManager
{
	if(!defaultPluginManager)
	{
		defaultPluginManager = [[PluginManager alloc] init];
	}
	return defaultPluginManager;
}

+(NSString*)userPluginsDirectory
{
	NSString *pluginsDir = [[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"PlugIns"];
	if(![[NSFileManager defaultManager] fileExistsAtPath:pluginsDir])
	{
		NSError *err;
		[[NSFileManager defaultManager] createDirectoryAtPath:pluginsDir withIntermediateDirectories:YES attributes:nil error:&err];
	}
	return pluginsDir;
}

+(void)openUserPluginsDirectory
{
	[[NSWorkspace sharedWorkspace] selectFile:[PluginManager userPluginsDirectory] inFileViewerRootedAtPath:@""];
}

- (void) dealloc
{
	[plugins release];
	[pluginScripts release];
	[pluginNames release];
    [pluginDataSources release];
	[pluginDirectories release];
	if(tempDirectory)
	{
		NSLog(@"Delete %@",tempDirectory);
		NSError *error;
		[[NSFileManager defaultManager] removeItemAtPath:tempDirectory error:&error];
		[tempDirectory release];
	}
	[super dealloc];
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		
        //setenv("VERSIONER_PYTHON_VERSION", "2.7", 1);
        
		NSError *err;
		tempDirectory = nil;
		
		plugins = [[NSMutableArray alloc] init];
		pluginScripts = [[NSMutableArray alloc] init];
		pluginNames = [[NSMutableArray alloc] init];
		pluginDataSources = [[NSMutableDictionary alloc] init];
        
		pluginDirectories = [[NSArray alloc] initWithObjects:[PluginManager userPluginsDirectory],nil];
		
		[self reloadPlugins];
		
		///////////////////////
		// Load Plugin Scripts
		///////////////////////
		
		NSString *scriptsSubpath = @"Scripts";
		NSArray *librarySearchPaths = [NSArray arrayWithObject:[DPApplicationSupport userSupportFolder]];
		
		for(NSString *currPath in librarySearchPaths)
		{
			NSString *path = [currPath stringByAppendingPathComponent:scriptsSubpath];
			NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&err];
			for(NSString *file in contents)
			{
				NSString *fileName = [path stringByAppendingPathComponent:file];
				if([[file pathExtension] isEqualToString:@"plist"] && ([[file lastPathComponent] characterAtIndex:0] != '.'))
				{
					@try {
						id script = [NSKeyedUnarchiver unarchiveObjectWithFile:fileName];
						if([script isKindOfClass:[PluginScript class]])
						{
							[script setFileName:fileName];
							[pluginScripts addObject:script];
							NSLog(@"Load script: %@",fileName);
						}
					}
					@catch (NSException *ex) {
						NSLog(@"Script %@ could not be loaded",fileName);
					}
				}
			
			}
		}
		
		
//		if ( result != 0 )
//		{
//			[NSException raise: NSInternalInconsistencyException
//						format: @"%s:%d main() PyRun_SimpleFile failed with file '%@'.  See console for errors.", __FILE__, __LINE__, mainFilePath];
//		}
	}
	return self;
}

-(void)reloadPlugins
{	
	
	NSError *err;
	NSBundle *mainBundle = [NSBundle mainBundle];
	NSString *resourcePath = [mainBundle resourcePath];

	NSMutableArray *pythonPathArray = [NSMutableArray arrayWithObjects:resourcePath, [resourcePath stringByAppendingPathComponent:@"PyObjC"],nil];

//	NSString *userPythonPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"DPPythonPath"];
//    if(userPythonPath)
//    {
//        NSArray *userPythonPathEntries = [userPythonPath componentsSeparatedByString:@":"];
//        [pythonPathArray addObjectsFromArray:userPythonPathEntries];
//        NSLog(@"Adding user Python Path entries: %@",[userPythonPathEntries description]);
//    }
    
	// Load Plugins
	[plugins removeAllObjects];
	[pluginNames removeAllObjects];
	
	NSArray *bundlePlugins = [mainBundle pathsForResourcesOfType:@"py" inDirectory:@"PlugIns"];
	if([bundlePlugins count] > 0)
	{
		[pythonPathArray addObject:[resourcePath stringByAppendingPathComponent:@"PlugIns"]];
		for(NSString *file in bundlePlugins)
		{
			NSString *pluginName = [[file lastPathComponent] stringByDeletingPathExtension];
			if(NSClassFromString(pluginName) != nil)
			{
				[pluginNames addObject:[self createAlternateClass:pluginName]];
			}
			else
			{
				[pluginNames addObject:pluginName];
			}
			
			NSLog(@"Found plugin in bundle: %@",pluginName);
		}
	}
	
	
	// Copy each discovered path into an array after adding
	// the Application Support/Annotation/PlugIns subpath
	for(NSString *currPath in pluginDirectories)
	{
		BOOL containsPlugin = NO;
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currPath error:&err];
		for(NSString *file in contents)
		{
			if([[file pathExtension] isEqualToString:@"py"] && ([[file lastPathComponent] characterAtIndex:0] != '.'))
			{
				NSString *pluginName = [[file lastPathComponent] stringByDeletingPathExtension];
				if(NSClassFromString(pluginName) != nil)
				{
					[pluginNames addObject:[self createAlternateClass:pluginName]];
				}
				else
				{
					[pluginNames addObject:pluginName];
				}
				//NSLog(@"Found plugin: %@",pluginName);
				containsPlugin = YES;
			}
		}
		if(containsPlugin)
		{
			[pythonPathArray addObject:currPath];
		}
	}
	

	[pythonPathArray addObject:[self tempDirectory]];
    
	setenv("PYTHONPATH", [[pythonPathArray componentsJoinedByString:@":"] UTF8String], 1);
		
	NSString *mainFilePath = [mainBundle pathForResource: @"main" ofType: @"py"];
	
	if ( !mainFilePath ) {
		NSLog(@"Couldn't initialize plugin loader");
		return;
		//[NSException raise: NSInternalInconsistencyException format: @"%s:%d main() Failed to find the Main.{py,pyc,pyo} file in the application wrapper's Resources directory.", __FILE__, __LINE__];
	}
	
    
	Py_SetProgramName("/usr/bin/python");
	Py_Initialize();
	
	const char *mainFilePathPtr = [mainFilePath UTF8String];
	FILE *mainFile = fopen(mainFilePathPtr, "r");
	int result = PyRun_SimpleFile(mainFile, (char *)[[mainFilePath lastPathComponent] UTF8String]);
	
	if( result == 0)
	{
		for(NSString *plugin in pluginNames)
		{
			const char* command = [[NSString stringWithFormat:@"import %@",plugin] UTF8String];
			result = PyRun_SimpleString(command);
			
			if(result != 0)
			{
				NSLog(@"Failed to load plugin: %@",plugin);
			}
			else
			{
				Class PluginClass = NSClassFromString(plugin);
				id pluginObj = [[PluginClass alloc] init];
				if([pluginObj isKindOfClass:[AnnotationDataAnalysisPlugin class]])
				{
					[plugins addObject:pluginObj];
					NSLog(@"Loaded plugin: %@",[pluginObj displayName]);
				}
				[pluginObj release];
			}
		}
	}
	
	fclose(mainFile);
}

-(NSString*)tempDirectory
{
	if(!tempDirectory)
	{
		NSString *tempDirectoryTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempDPplugins.XXXXXX"];
		const char *tempDirectoryTemplateCString = [tempDirectoryTemplate fileSystemRepresentation];
		char *tempDirectoryNameCString = (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
		strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);
		
		char *result = mkdtemp(tempDirectoryNameCString);
		NSString* tempDirectoryPath;
		if (!result)
		{
			// handle directory creation failure
			tempDirectoryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"tempDPplugins"];
			if(![tempDirectoryPath fileExists])
			{
				NSError* err = nil;
				[[NSFileManager defaultManager] createDirectoryAtPath:tempDirectoryPath withIntermediateDirectories:YES attributes:nil error:&err];
			}
		}
		else
		{
			tempDirectoryPath = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirectoryNameCString length:strlen(result)];
		}
		free(tempDirectoryNameCString);
		tempDirectory = [tempDirectoryPath retain];
	}
	return tempDirectory;
}

- (NSString*)createAlternateClass:(NSString*)className
{
	// Find a suitable new class name
	NSString *newClassName = className;
	int iteration = 1;
	while(NSClassFromString(newClassName) != nil)
	{
		newClassName = [className stringByAppendingFormat:@"%i",iteration];
		iteration++;
	}
	
	NSString *newFile = [[self tempDirectory] stringByAppendingPathComponent:[newClassName stringByAppendingPathExtension:@"py"]];
	
	// Find the python file
	NSError *err = nil;
	for(NSString *currPath in pluginDirectories)
	{
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:currPath error:&err];
		for(NSString *file in contents)
		{
			if([[file pathExtension] isEqualToString:@"py"] && 
			   ([[file lastPathComponent] characterAtIndex:0] != '.') &&
			   [className isEqualToString:[[file lastPathComponent] stringByDeletingPathExtension]])
			{
				NSStringEncoding enc;
				NSString *code = [NSString stringWithContentsOfFile:[currPath stringByAppendingPathComponent:file] usedEncoding:&enc error:&err];
				NSString *newCode = [code stringByReplacingOccurrencesOfString:className withString:newClassName];
				[newCode writeToFile:newFile atomically:YES encoding:NSUTF8StringEncoding error:&err];
				if(err)
				{
					NSLog(@"error reloading plugin: %@",[err localizedDescription]);
				}
				return newClassName;
			}
		}
	}
	return nil;
}

-(void)handleNotification:(NSNotification*)notification
{
	[pipeReadHandle readInBackgroundAndNotify] ;
	NSString *str = [[NSString alloc] initWithData: [[notification userInfo] objectForKey: NSFileHandleNotificationDataItem] encoding: NSASCIIStringEncoding] ;
	//NSLog(@"STDOUT:%@",str);
	[DPConsole defaultConsoleEntry:str];
}

-(NSArray*)plugins
{
	return plugins;
}

-(void)runPlugin:(id)sender
{
	Class PluginClass = [[sender representedObject] class];
	AnnotationDataAnalysisPlugin *plugin = [[PluginClass alloc] init];
	
	////////
	// Check for needed document variables
	////////
	
	NSArray *requiredDocVariables = [plugin documentVariables];
	NSMutableDictionary *existingDocVariables = [[AnnotationDocument currentDocument] documentVariables];
	NSMutableArray *neededVariables = [NSMutableArray array];
	
	for(NSString *varName in requiredDocVariables)
	{
		id value = [existingDocVariables objectForKey:varName];
		if(value == nil)
		{
			[neededVariables addObject:varName];
		}
	}
	
	if([neededVariables count] > 0)
	{
		
		
		NSMutableString *neededVariablesString = [NSMutableString stringWithString:@"Needed variables:\n"];
		for(NSString *variable in neededVariables)
		{
			if(variable == [neededVariables lastObject])
			{
				[neededVariablesString appendFormat:@"%@",variable];
			}
			else
			{
				[neededVariablesString appendFormat:@"%@, ",variable];
			}
		}
		
		NSAlert* alert = [[NSAlert alloc] init];
		[alert setMessageText:[NSString stringWithFormat:
							   @"Some variables need to be defined before running the plugin \"%@\".\nWould you like to define them now?",
							   [plugin displayName]]];
		[alert setInformativeText:neededVariablesString];
		[alert addButtonWithTitle:@"Define variables…"];
		[alert addButtonWithTitle:@"Cancel"];
		NSInteger result = [alert runModal];
		if(result == NSAlertFirstButtonReturn)
		{
			NSMutableDictionary *dict = [[AnnotationDocument currentDocument] documentVariables];
			for(NSString *variable in neededVariables)
			{
				[dict setObject:@"0" forKey:variable];
			}
			[[AppController currentApp] showDocumentVariablesWindow:self];
			[plugin release];
			return;
		}
		else if(result == NSAlertSecondButtonReturn)
		{
			[plugin release];
			return;
		}
		
		
	}
	
	BOOL result = [self checkDataSets:plugin];
	if(!result)
	{
		[plugin release];
		return;
	}
	
	NSUInteger parameterCount = [[plugin dataParameters] count];
	if(parameterCount > [[[AppController currentDoc] dataSetsOfClass:[plugin dataVariableClass]] count])
	{
		NSAlert* alert = [[NSAlert alloc] init];
		[alert setMessageText:[NSString stringWithFormat:
							   @"%@ plugin requires at least %i data set%@ to be loaded.",
							   [plugin displayName],
							   [[plugin dataParameters] count],
							   (parameterCount > 1) ? @"s" : @""]];
		[alert setInformativeText:@"Please try to run the plugin again after loading more data."];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Load data…"];
		NSInteger result = [alert runModal];
		if(result == NSAlertSecondButtonReturn)
		{
			[[AppController currentApp] importData:self];
		}
	}
	else
	{	
		PluginConfiguration *config = [[PluginConfiguration alloc] initWithPlugin:plugin];
		
		PluginConfigurationView *configView = [[PluginConfigurationView alloc] initWithPluginConfiguration:config];
		
		NSSize size = [configView bounds].size;
		
		NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,200,size.width,size.height) styleMask:(NSTitledWindowMask | NSClosableWindowMask) backing:NSBackingStoreBuffered defer:NO];
		[window setTitle:[plugin displayName]];
		[window setContentView:configView];
		[window makeKeyAndOrderFront:self];
	}
	[plugin release];
}





-(PluginDataSource*)dataSourceForPlugin:(AnnotationDataAnalysisPlugin*)plugin
{
    PluginDataSource *source = [pluginDataSources objectForKey:[plugin displayName]];
    if(!source)
    {
        source = [[PluginDataSource alloc] initWithPath:nil];
        [source setName:[NSString stringWithString:[plugin displayName]]];
        [[AnnotationDocument currentDocument] addDataSource:source];
        [pluginDataSources setObject:source forKey:[plugin displayName]];
        [source release];
    }
    return source;
}

/////////////////////////////
// Check for needed data sets to run a plugin
/////////////////////////////
- (BOOL)checkDataSets:(AnnotationDataAnalysisPlugin*)plugin
{
	NSArray *dataParameters = [plugin dataParameters];
	
	NSMutableArray *possibleDataSets = [[[[AppController currentDoc] dataSets] mutableCopy] autorelease];
	
	NSMutableArray *missing = [NSMutableArray array];
	
	
	if(([possibleDataSets count] == 0) && ([dataParameters count] > 0))
	{
		NSAlert* alert = [[NSAlert alloc] init];
		[alert setMessageText:[NSString stringWithFormat:
							   @"%@ plugin requires at least %i data set%@ to be loaded.",
							   [plugin displayName],
							   [[plugin dataParameters] count],
							   ([dataParameters count] > 1) ? @"s" : @""]];
		[alert setInformativeText:@"Please try to run the plugin again after loading more data."];
		[alert addButtonWithTitle:@"OK"];
		[alert addButtonWithTitle:@"Load data…"];
		NSInteger result = [alert runModal];
		if(result == NSAlertSecondButtonReturn)
		{
			[[AppController currentApp] importData:self];
		}
		return NO;
	}
	
	
	// First, match up default variables
	
	for(PluginDataSet *pluginDataSet in dataParameters)
	{
		if([pluginDataSet.defaultVariable length] > 0)
		{
			pluginDataSet.dataSet = nil;
			
			for(TimeCodedData* dataSet in possibleDataSets)
			{
				if([[dataSet variableName] caseInsensitiveCompare:pluginDataSet.defaultVariable] == NSOrderedSame)
				{
					pluginDataSet.dataSet = dataSet;
					break;
				}
			}
			if(!pluginDataSet.dataSet)
			{
				[missing addObject:pluginDataSet];
			}
		}
	}
	
	if([missing count] > 0)
	{
		NSMutableDictionary *foundVariables = [NSMutableDictionary dictionary];
		NSArray *dataSources = [[AnnotationDocument currentDocument] dataSources];
		// Load missing data sets
		for(PluginDataSet *missingData in missing)
		{
			for(DataSource *dataSource in dataSources)
			{
				for(NSString *variable in [dataSource variables])
				{
					if([variable caseInsensitiveCompare:missingData.defaultVariable] == NSOrderedSame)
					{
						[foundVariables setObject:dataSource forKey:variable];
						break;
					}
				}
			}
			
		}
		
		
		NSMutableArray *types = [NSMutableArray array];
		
		for(DataSource *source in dataSources)
		{
			NSArray *variables = [foundVariables allKeysForObject:source];
			if([variables count] > 0)
			{
				[types removeAllObjects];
				for(NSString *variable in variables)
				{
					[types addObject:DataTypeTimeSeries];
				}
				//					[importController setDataSource:source];
				//					[importController importVariables:variables asTypes:types withLabels:nil];
			}
		}
	}
	
	
	// Assign any remaining dataSets that didn't have matches
	for(PluginDataSet *pluginDataSet in dataParameters)
	{
		if(pluginDataSet.dataSet == nil)
		{
			pluginDataSet.dataSet = [possibleDataSets objectAtIndex:0];
		}
		[possibleDataSets removeObject:pluginDataSet.dataSet];
	}
	
	
//	if(!pluginDataSet.dataSet)
//	{
//		[missing addObject:pluginDataSet];
//	}
//	else if([possibleDataSets count] > 0)
//	{
//		pluginDataSet.dataSet = [possibleDataSets objectAtIndex:0];
//	}
	
//	if([missing count] > 0)
//	{
//		NSMutableDictionary *foundVariables = [NSMutableDictionary dictionary];
//		NSArray *dataSources = [[AnnotationDocument currentDocument] dataSources];
//		// Load missing data sets
//		for(PluginDataSet *missingData in missing)
//		{
//			for(DataSource *dataSource in dataSources)
//			{
//				for(NSString *variable in [dataSource variables])
//				{
//					if([variable caseInsensitiveCompare:missingData.defaultVariable] == NSOrderedSame)
//					{
//						[foundVariables setObject:dataSource forKey:variable];
//						break;
//					}
//				}
//			}
//			
//		}
//		
//		NSMutableString *matchingData = [NSMutableString stringWithString:@"Data that will be loaded:\n"];
//		for(NSString *variable in [foundVariables allKeys])
//		{
//			[matchingData appendFormat:@"%@ from %@\n",variable,[(DataSource*)[foundVariables objectForKey:variable] name]];
//		}
//		
//		NSAlert* alert = [[NSAlert alloc] init];
//		[alert setMessageText:[NSString stringWithFormat:
//							   @"There %@ missing data set%@ for the plugin \"%@\".\nWould you like to automatically load matching data sets before running the plugin?",
//							   ([missing count] > 1) ? @"are" : @"is a",
//							   ([missing count] > 1) ? @"s" : @"",
//							   [plugin displayName]]];
//		[alert setInformativeText:matchingData];
//		[alert addButtonWithTitle:@"Load matching data"];
//		[alert addButtonWithTitle:@"Manually select data…"];
//		[alert addButtonWithTitle:@"Cancel"];
//		NSInteger result = [alert runModal];
//		if(result == NSAlertSecondButtonReturn)
//		{
//			[[AppController currentApp] importData:self];
//			return NO;
//		}
//		else if(result == NSAlertThirdButtonReturn)
//		{
//			return NO;
//		}
//		else if (result == NSAlertFirstButtonReturn)
//		{
//			NSMutableArray *types = [NSMutableArray array];
//			
//			for(DataSource *source in dataSources)
//			{
//				NSArray *variables = [foundVariables allKeysForObject:source];
//				if([variables count] > 0)
//				{
//					[types removeAllObjects];
//					for(NSString *variable in variables)
//					{
//						[types addObject:DataTypeTimeSeries];
//					}
////					[importController setDataSource:source];
////					[importController importVariables:variables asTypes:types withLabels:nil];
//				}
//			}
//		}
//	}
	
	return YES;
}

-(NSArray*)pluginScripts
{
	return pluginScripts;
}

-(void)addPluginScript:(PluginScript*)script
{
	[pluginScripts addObject:script];
	[self saveScript:script];
}

-(void)deletePluginScript:(PluginScript*)script
{
	NSString *scriptFile = [script fileName];
	
	NSLog(@"Delete script: %@",scriptFile);
	NSError *err;
	[[NSFileManager defaultManager] removeItemAtPath:scriptFile error:&err];
	
	[pluginScripts removeObject:script];
	
}

-(void)saveScripts
{
	for(PluginScript* script in pluginScripts)
	{
		[self saveScript:script];
	}
}

-(void)saveScript:(PluginScript*)script
{
	if([script fileName])
	{
		[NSKeyedArchiver archiveRootObject:script toFile:[script fileName]];
	}
	else
	{
		NSError *err;

		NSString *userScriptsFolder = [[DPApplicationSupport userSupportFolder] stringByAppendingPathComponent:@"Scripts"];
		if(![[NSFileManager defaultManager] fileExistsAtPath:userScriptsFolder])
		{
			[[NSFileManager defaultManager] createDirectoryAtPath:userScriptsFolder withIntermediateDirectories:YES attributes:nil error:&err];
		}
		
		NSString *scriptName = [NSString stringWithFormat:@"%@.plist",[script name]];
		NSString *scriptFile = [userScriptsFolder stringByAppendingPathComponent:scriptName];

		[NSKeyedArchiver archiveRootObject:script toFile:scriptFile];
		[script setFileName:scriptFile];
	}
}

@end
