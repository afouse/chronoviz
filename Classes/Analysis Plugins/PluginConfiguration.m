//
//  PluginConfiguration.m
//  Annotation
//
//  Created by Adam Fouse on 9/24/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PluginConfiguration.h"
#import "PluginConfigurationView.h"
#import "AnnotationDataAnalysisPlugin.h"
#import "PluginParameter.h"
#import "PluginDataSet.h"
#import "PluginAnnotationSet.h"
#import "PluginManager.h"
#import "TimeCodedData.h"
#import "AnnotationSet.h"
#import "DataSource.h"
#import "PluginDataSource.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "AnnotationCategoryFilter.h"
#import "AnnotationFilter.h"
#import "VideoProperties.h"
#import "DPViewManager.h"
#import "AppController.h"
#import "AnnotationDocument.h"

@interface PluginConfiguration (Internal)

-(NSWindow*)pluginProgressWindow;

@end

@implementation PluginConfiguration

@synthesize description;

-(id)initWithPlugin:(AnnotationDataAnalysisPlugin*)thePlugin
{
	self = [super init];
	if (self != nil) {
		plugin = [thePlugin retain];
		dataSets = [[NSMutableArray alloc] initWithCapacity:[[plugin dataParameters] count]];
		dataSetsNames = [[NSMutableArray alloc] initWithCapacity:[[plugin dataParameters] count]];
		inputValues = [[plugin inputParameters] retain];
		
		[self setDescription:[NSString stringWithFormat:@"Values determined by the plugin %@.",[plugin displayName]]];
		
		NSArray *possibleDataSets = [[AppController currentDoc] dataSetsOfClass:[plugin dataVariableClass]];
		
		int i;
		for(i = 0; i < [[plugin dataParameters] count]; i++)
		{
			id data = [NSNull null];
			
			PluginDataSet *pluginDataSet = [[plugin dataParameters] objectAtIndex:i];
			
			pluginDataSet.dataSet = nil;
			
			for(TimeCodedData* dataSet in possibleDataSets)
			{
				if([[dataSet variableName] caseInsensitiveCompare:pluginDataSet.defaultVariable] == NSOrderedSame)
				{
					data = dataSet;
					pluginDataSet.dataSet = dataSet;
					break;
				}
			}
			
			if(!pluginDataSet.dataSet)
			{
				if([[[AppController currentDoc] dataSetsOfClass:[plugin dataVariableClass]] count] > i)
                {
					data = [[[AppController currentDoc] dataSetsOfClass:[plugin dataVariableClass]] objectAtIndex:i];
                    pluginDataSet.dataSet = data;
                }
			}

			[dataSets addObject:data];
		}
        
        AnnotationCategory *category = [[[AppController currentDoc] categories] firstObject];
        for(PluginAnnotationSet *set in [plugin annotationSets])
        {
            AnnotationFilter *filter = [[AnnotationCategoryFilter alloc] initForCategories:@[category]];
            set.annotationFilter = filter;
            [filter release];
        }
	}
	return self;
}

- (void) dealloc
{
	[plugin release];
	[dataSets release];
	[dataSetsNames release];
	[inputValues release];
	[super dealloc];
}

-(void)runPluginInBackground
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // Top-level pool
	
	NSLog(@"Background thread");
	
	NSArray *annotations = [plugin analyzeData:dataSets];

	NSLog(@"Background thread done");
	
	for(Annotation* annotation in annotations)
	{
		[annotation setAutoCreated:YES];
	}
	
	[pool release];  // Release the objects in the pool.
}

-(BOOL)runPlugin:(id)sender
{
	if([sender isKindOfClass:[NSControl class]])
	{
		[[sender window] close];
	}
	
    
    for(PluginAnnotationSet *set in [plugin annotationSets])
    {
        AnnotationFilter *filter = (AnnotationFilter*) set.annotationFilter;
        set.annotations = [[[AppController currentDoc] annotations] filteredArrayUsingPredicate:[filter predicate]];
    }
    
	int index = 0;
	NSArray* allDataSets = [[AppController currentDoc] dataSetsOfClass:[plugin dataVariableClass]];
	for(id data in dataSets)
	{
		if(data == [NSNull null])
		{
			NSString *name = [dataSetsNames objectAtIndex:index];
			if(name)
			{
				for(TimeCodedData* dataSet in allDataSets)
				{
					if([name isEqualToString:[dataSet name]])
					{
						[dataSets replaceObjectAtIndex:index withObject:dataSet];
						break;
					}
				}
			}
			else 
			{
				NSLog(@"DataSets for plugin %@ were not set.",[plugin displayName]);
				NSLog(@"Values: %f, %f",[[inputValues objectAtIndex:0] parameterValue],[[inputValues objectAtIndex:1] parameterValue]);
				return NO;
			}
		}
		
		index++;
		
	}
	
//	NSThread* myThread = [[NSThread alloc] initWithTarget:self
//												 selector:@selector(runPluginInBackground)
//												   object:nil];
//	[myThread start];  // Actually create the thread
	
    NSWindow *pluginProgressWindow = nil;
    if([plugin shouldShowProgress])
    {
        pluginProgressWindow = [self pluginProgressWindow];
        [NSApp beginSheet:pluginProgressWindow
           modalForWindow:[[AppController currentApp] window]
            modalDelegate:nil
           didEndSelector:NULL
              contextInfo:nil];
    }
    
    
	NSArray *annotations = [plugin analyzeData:dataSets];

    AnnotationDocument *currentDocument = [AnnotationDocument currentDocument];

	if(annotations)
	{
        PluginDataSource *source = [[PluginManager defaultPluginManager] dataSourceForPlugin:plugin];
        
        AnnotationSet *annotationSet = [[AnnotationSet alloc] init];
        
		AnnotationCategory *category = [[AppController currentDoc] categoryForName:[plugin displayName]];
		if(!category)
		{
			category = [[AppController currentDoc] createCategoryWithName:[plugin displayName]]; //[[AnnotationCategory alloc] init];
			[category setColor:[NSColor greenColor]];
		}
		for(Annotation* annotation in annotations)
		{
			[annotation setAutoCreated:YES];
			[annotation setCategory:category];
			if([[annotation title] length] < 1)
			{
				[annotation setTitle:[plugin displayName]];
			}
			if([[annotation annotation] length] < 1)
			{
				[annotation setAnnotation:description];
			}
            
            [annotation setSource:[source uuid]];
            [annotationSet addAnnotation:annotation];
		}
        
        [source addDataSet:annotationSet];
        
		[currentDocument addAnnotations:annotations];
	}
    
    if(plugin.resultAnnotations)
	{
        DataSource *source = [[PluginManager defaultPluginManager] dataSourceForPlugin:plugin];
        
        AnnotationSet *annotationSet = [[AnnotationSet alloc] init];
        
		for(Annotation* annotation in plugin.resultAnnotations)
		{
			[annotation setAutoCreated:YES];
            [annotation setSource:[source uuid]];
            [annotationSet addAnnotation:annotation];
		}
        [currentDocument addAnnotations:plugin.resultAnnotations];
        
        [source addDataSet:annotationSet];
        
        [annotationSet release];
	}
    
	
    if([plugin.resultData count])
    {
        DataSource *source = [[PluginManager defaultPluginManager] dataSourceForPlugin:plugin];
        
        for(TimeCodedData* data in plugin.resultData)
        {
            [source addDataSet:data];
            [[[AppController currentApp] viewManager] showData:data];
        }
    }
	
    if(pluginProgressWindow)
    {
        [NSApp endSheet:pluginProgressWindow];
        [pluginProgressWindow orderOut:self];
        [pluginProgressWindow release];
    }
    
	return YES;
}


- (NSWindow*)pluginProgressWindow
{
    NSWindow *pluginProgressWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
                                                       styleMask:NSTitledWindowMask
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
    [pluginProgressWindow setReleasedWhenClosed:NO];
    
    NSProgressIndicator *progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(18, 56, 444, 20)];
    [progressIndicator setIndeterminate:YES];
    
    NSTextField *progressTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(17, 84, 444, 17)];
    [progressTextField setStringValue:[NSString stringWithFormat:@"Running %@ …",[plugin displayName]]];
    [progressTextField setEditable:NO];
    [progressTextField setDrawsBackground:NO];
    [progressTextField setBordered:NO];
    [progressTextField setAlignment:NSLeftTextAlignment];
    
    [[pluginProgressWindow contentView] addSubview:progressIndicator];
    [[pluginProgressWindow contentView] addSubview:progressTextField];
    
    [progressIndicator setUsesThreadedAnimation:YES];
    [progressIndicator startAnimation:self];
    
    [progressIndicator release];
    [progressTextField release];
    
	return pluginProgressWindow;
}

-(void)setDataSet:(TimeCodedData*)dataSet forIndex:(NSUInteger)index
{
	[(PluginDataSet*)[[plugin dataParameters] objectAtIndex:index] setDataSet:dataSet];
	
	[dataSets replaceObjectAtIndex:index withObject:dataSet];
}

-(TimeCodedData*)dataSetForIndex:(NSUInteger)index
{
	return [dataSets objectAtIndex:index];
}

-(void)setInputValue:(CGFloat)value forIndex:(NSUInteger)index
{
	[[inputValues objectAtIndex:index] setParameterValue:value];
}

-(PluginParameter*)inputValueForIndex:(NSUInteger)index
{
	return [inputValues objectAtIndex:index];
}

-(void)setAnnotationFilter:(AnnotationFilter*)filter forIndex:(NSUInteger)index
{
    [(PluginAnnotationSet*)[[plugin annotationSets] objectAtIndex:index] setAnnotationFilter:filter];
}

-(PluginAnnotationSet*)annotationSetForIndex:(NSUInteger)index
{
    return [[plugin annotationSets] objectAtIndex:index];
}

-(AnnotationDataAnalysisPlugin*)plugin
{
	return plugin;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:plugin forKey:@"AnnotationPluginConfigurationPlugin"];
	[coder encodeObject:description forKey:@"AnnotationPluginConfigurationDescription"];
	[coder encodeObject:dataSetsNames forKey:@"AnnotationPluginConfigurationDataSetNames"];
	[coder encodeObject:inputValues forKey:@"AnnotationPluginConfigurationInputValues"];
	
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		plugin = [[coder decodeObjectForKey:@"AnnotationPluginConfigurationPlugin"] retain];
		inputValues = [[plugin inputParameters] retain];
		description = [[coder decodeObjectForKey:@"AnnotationPluginConfigurationDescription"] retain];
		dataSetsNames = [[coder decodeObjectForKey:@"AnnotationPluginConfigurationDataSetNames"] retain];
		
		// Set parameter values in the plugin from the saved parameter values;
		NSArray* savedInputValues = [coder decodeObjectForKey:@"AnnotationPluginConfigurationInputValues"];
		for(PluginParameter *savedParameter in savedInputValues)
		{
			for(PluginParameter *parameter in inputValues)
			{
				if([[savedParameter parameterName] isEqualToString:[parameter parameterName]])
				{
					[parameter setParameterValue:[savedParameter parameterValue]];
					break;
				}
			}
		}
		
		dataSets = [[NSMutableArray alloc] initWithCapacity:[[plugin dataParameters] count]];
	}
    return self;
}

@end
