//
//  AnnotationDocument.m
//  Annotation
//
//  Created by Adam Fouse on 9/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationDocument.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "VideoProperties.h"
#import "AnnotationXMLParser.h"
#import "AppController.h"
#import "TimeCodedData.h"
#import "TimeSeriesData.h"
#import "TimelineView.h"
#import "MultiTimelineView.h"
#import "DataSource.h"
#import "SenseCamDataSource.h"
#import "TimeCodedImageFiles.h"
#import "NSStringFileManagement.h"
#import "DPConstants.h"
#import "DPViewManager.h"
#import "DPActivityLog.h"
#import "AnnotationSet.h"
#import "VideoDataSource.h"
#import "CompoundDataSource.h"
#import "AFAVAssetCreator.h"
#import <Sparkle/SUUpdater.h>
#import <CoreServices/CoreServices.h>
//#import <QTKit/QTMovieModernizer.h>
// TODO: Check what depends on the above import. We can probably omit this. https://github.com/benoit-pereira-da-silva/MovieModernizer

NSString * const MediaChangedNotification = @"MediaChangedNotification";
NSString * const DPMediaAddedKey = @"MediaAdded";
NSString * const DPMediaRemovedKey = @"MediaRemoved";
NSString * const CategoriesChangedNotification = @"CategoriesChangedNotification";;

int const DPCurrentDocumentFormatVersion = 1;

@interface AnnotationDocument (Internal)

- (void)processCategoryChange:(id)sender;
- (BOOL)loadVideoProperties:(VideoProperties*)properties;
- (BOOL)loadDataSource:(DataSource*)dataSource;
- (void)updateMediaFile:(VideoProperties*)props;
- (void)updateDataFile:(DataSource*)source;
- (NSString*)createBackup;

- (BOOL)dataFile:(NSString*)file inSources:(NSArray*)sourcesArray;

+ (NSArray*)defaultCategories;

- (void)saveAnnotationsNow;

@end

@implementation AnnotationDocument

@synthesize modified;
@synthesize activityLog;

+ (AnnotationDocument*)currentDocument
{
	return [AppController currentDoc];
}

- (id)initForVideo:(NSString*)videoFile
{
	NSError *err = nil;
	NSString *defaultAnnotationFile = [[videoFile stringByDeletingPathExtension] stringByAppendingString:@"-Annotations.annotation"];
	// If the default annotation file exists, ask if we should use it
	
	if(![[NSUserDefaults standardUserDefaults] boolForKey:AFAutomaticAnnotationFileKey])
	{
		NSSavePanel *newAnnotationsPanel = [NSSavePanel savePanel];
		[newAnnotationsPanel setTitle:@"New Annotations File"];
		[newAnnotationsPanel setMessage:@"Please set the name and location for the new annotations file."];
		[newAnnotationsPanel setExtensionHidden:YES];
		[newAnnotationsPanel setCanSelectHiddenExtension:NO];
		[newAnnotationsPanel setRequiredFileType:@"annotation"];
		
		if ([newAnnotationsPanel runModalForDirectory:nil file:@"New Annotations"] == NSOKButton) {
			return [self initAtFile:[newAnnotationsPanel filename]  withVideo:videoFile];
		}
		else
		{
			[self release];
			return nil;
		}
	}
	
	if([[NSFileManager defaultManager] fileExistsAtPath:defaultAnnotationFile])
	{
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:[NSString stringWithFormat:
							   @"An existing annotation file was found for %@. Do you want to open the existing file or create a new one?",
							   [videoFile lastPathComponent]]];
		[alert addButtonWithTitle:@"Open Existing File"];
		[alert addButtonWithTitle:@"Create New File"];
		NSInteger result = [alert runModal];
		if(result == NSAlertFirstButtonReturn)
		{
			return [self initFromFile:defaultAnnotationFile];
		}
		else
		{
			NSSavePanel *newAnnotationsPanel = [NSSavePanel savePanel];
			[newAnnotationsPanel setTitle:@"New Annotations File"];
			[newAnnotationsPanel setMessage:@"Please set the name and location for the new annotations file."];
			[newAnnotationsPanel setExtensionHidden:YES];
			[newAnnotationsPanel setCanSelectHiddenExtension:NO];
			[newAnnotationsPanel setRequiredFileType:@"annotation"];
			
			if ([newAnnotationsPanel runModalForDirectory:nil file:@"New Annotations"] == NSOKButton) {
				return [self initAtFile:[newAnnotationsPanel filename]  withVideo:videoFile];
			}
			else
			{
				[self release];
				return nil;
			}
		}

	}
	// If older default annotations exist, update the name and use it
	else if([[NSFileManager defaultManager] fileExistsAtPath:[defaultAnnotationFile stringByDeletingPathExtension]])
	{
		[[NSFileManager defaultManager] moveItemAtPath:[defaultAnnotationFile stringByDeletingPathExtension] 
												toPath:defaultAnnotationFile
												 error:&err];
		NSString *videoPropertiesFile = [[defaultAnnotationFile stringByAppendingPathComponent:@"videoInfo.plist"] retain];
		if([[NSFileManager defaultManager] fileExistsAtPath:videoPropertiesFile])
		{
			VideoProperties *properties = [[VideoProperties alloc] initFromFile:videoInfoFile];
			[properties setVideoFile:videoFile];
			[properties saveToFile:videoPropertiesFile];
			[properties release];
			return [self initFromFile:defaultAnnotationFile];
		}
		else
		{
			return [self initAtFile:defaultAnnotationFile withVideo:videoFile];
		}
			
		//return [self initAtFile:defaultAnnotationFile withVideo:videoFile];
	}
	// Otherwise, create a new default annotation file
	else
	{
		return [self initAtFile:defaultAnnotationFile withVideo:videoFile];
		//return [self initFromFile:defaultAnnotationFile];
	}
}

- (id)initAtFile:(NSString*)filename withVideo:(NSString*)videoFile
{
	NSString *imageDirectory = [filename stringByAppendingPathComponent:@"images"];
	NSString *videoPropertiesFile = [filename stringByAppendingPathComponent:@"videoInfo.plist"];
	
	if(![[NSFileManager defaultManager] fileExistsAtPath:imageDirectory])
	{
		BOOL result = [[NSFileManager defaultManager] createDirectoryAtPath:imageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		if(!result)
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:[NSString stringWithFormat:@"The file %@ could not be created.",[filename lastPathComponent]]];
			[alert runModal];
			[alert release];
			return nil;
		}
	}
	
	VideoProperties *properties = [[VideoProperties alloc] initWithVideoFile:videoFile];
	//[properties setVideoFile:videoFile];
	[properties saveToFile:videoPropertiesFile];
	[properties release];
	
	// Create and save the default categories
	
	NSArray *defaultCategories = [AnnotationDocument defaultCategories];
		
	NSString *errorDesc;
	
	NSData *categoriesData = [NSKeyedArchiver archivedDataWithRootObject:defaultCategories];
	
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:[NSDictionary dictionaryWithObject:categoriesData
																									  forKey:@"DPCategories"]
																   format:NSPropertyListXMLFormat_v1_0
														 errorDescription:&errorDesc];
	if (!plistData) {
        NSLog(@"%@",errorDesc);
        [errorDesc release];
    }
	else
	{
		[plistData writeToFile:[filename stringByAppendingPathComponent:@"properties.plist"] atomically:YES];	
	}
	
	
	return [self initFromFile:filename];
}

- (id)initFromFile:(NSString*)filename
{	
	self = [super init];
	if (self != nil) {
		NSError *err = nil;
		int documentFormatVersion = 0;
        
        //NSDate *startLoadingDate = [NSDate date];
        
		// Basic setup
		annotationsDirectory = [filename retain];
		annotationsImageDirectory = [[annotationsDirectory stringByAppendingPathComponent:@"images"] retain];
		videoInfoFile = [[annotationsDirectory stringByAppendingPathComponent:@"videoInfo.plist"] retain];
		annotationsFile = [[annotationsDirectory stringByAppendingPathComponent:@"annotations.xml"] retain];
		
		NSLog(@"Loading Annotations File: %@", annotationsDirectory);
		if(![[NSFileManager defaultManager] fileExistsAtPath:annotationsImageDirectory])
		{
			[[NSFileManager defaultManager] createDirectoryAtPath:annotationsImageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
		}
		
		///////////////////////////
		// Load the properties file
		///////////////////////////
		NSLog(@"Loading properties");
        
        
		NSString *propertiesFile = [annotationsDirectory stringByAppendingPathComponent:@"properties.plist"];
		if(![[NSFileManager defaultManager] fileExistsAtPath:propertiesFile])
		{
			documentProperties = [[NSMutableDictionary alloc] init];
		}
		else
		{
			NSString *errorDesc = nil;
			NSPropertyListFormat format;
			NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:propertiesFile];
			documentProperties = [(NSDictionary *)[NSPropertyListSerialization
												  propertyListFromData:plistXML
												  mutabilityOption:0
												  format:&format errorDescription:&errorDesc] mutableCopy];
			
			NSDictionary *userVariables = [documentProperties objectForKey:@"DPUserVariables"];
			if(userVariables)
			{
				[documentProperties setObject:[userVariables mutableCopy] forKey:@"DPUserVariables"];
			}
            
		}
		
		documentFormatVersion = [[documentProperties valueForKey:@"DPDocumentFormatVersion"] intValue];
        if(documentFormatVersion > DPCurrentDocumentFormatVersion)
        {
            NSAlert *alert = [[NSAlert alloc] init];
            [alert setMessageText:@"This document can't be opened because it was created with a newer version of ChronoViz."];
            [alert setInformativeText:@"Please update ChronoViz to open this file."];
            
            [alert addButtonWithTitle:@"OK"];
            [alert addButtonWithTitle:@"Update Now"];
            
            NSInteger result = [alert runModal];
            [alert release];
            if(result == NSAlertSecondButtonReturn)
            {
                [[SUUpdater sharedUpdater] checkForUpdates:nil];
            }
            
            
            [self release];
            return nil;
        }
        
        savedLayouts = [[documentProperties valueForKey:@"DPSavedLayouts"] mutableCopy];
		if(!savedLayouts)
		{
			savedLayouts = [[NSMutableDictionary alloc] init];
		}
        [documentProperties setValue:savedLayouts
                              forKey:@"DPSavedLayouts"];
        
		keywords = [[documentProperties valueForKey:@"DPKeywords"] mutableCopy];
		if(!keywords)
		{
			keywords = [[NSMutableArray alloc] init];
		}
        [documentProperties setValue:keywords
                              forKey:@"DPKeywords"];
		
		categories = [[NSMutableArray alloc] init];
		
		NSData *categoriesData = [documentProperties valueForKey:@"DPCategories"];
		
		if(categoriesData)
		{
			NSArray *storedCategories = [NSKeyedUnarchiver unarchiveObjectWithData:categoriesData];
			for(AnnotationCategory* category in storedCategories)
			{
				[self addCategory:category];
			}
		}
		
		///////////////////////////
		// Load the video info file
		///////////////////////////
        NSLog(@"Loading video info");
		
		// If the video info file doesn't exist, create one.
		if(![[NSFileManager defaultManager] fileExistsAtPath:videoInfoFile])
		{
			VideoProperties *properties = [[VideoProperties alloc] init];
			[properties saveToFile:videoInfoFile];
			[properties release];
		}
		
		// If we created one successfully, load it.
		if([[NSFileManager defaultManager] fileExistsAtPath:videoInfoFile])
		{
			videoProperties = [[VideoProperties alloc] initFromFile:videoInfoFile];
						
			if([videoProperties videoFile] == nil || ([[videoProperties videoFile] length] == 0))
			{
				// Find if a video exists (support for older file format)
				if([filename rangeOfString:@"-Annotations"].location != NSNotFound)
				{
					NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[filename stringByDeletingLastPathComponent] error:&err];
					for(NSString* file in files)
					{
                        /*
                        NSError* err;
						if (![QTMovieModernizer requiresModernization:[NSURL URLWithString:file] error:&err]) {
							[videoProperties setVideoFile:file];
							[videoProperties saveToFile:videoInfoFile];
							break;
						}
                        */
                        // TODO: Remove Modernization?
					}
				}
				
				// If there's still no video file, create a placeholder video.
				if([videoProperties videoFile] == nil || ([[videoProperties videoFile] length] == 0))
				{
                    CMTime duration = CMTimeMakeWithSeconds([[AppController currentApp] newDocumentDuration], 600);
									
                    NSString* movieFile = [self createVideoFileWithDuration:duration];
					
					[videoProperties setVideoFile:movieFile];
					[videoProperties saveToFile:videoInfoFile];
					
					if([categories count] == 0)
					{
						NSArray *defaultCategories = [AnnotationDocument defaultCategories];
						for(AnnotationCategory* category in defaultCategories)
						{
							[self addCategory:category];
						}
					}
				}
				
			}
			
			[self updateMediaFile:videoProperties];
            
			AVAsset *movie = [videoProperties loadMovie];
			if(movie)
			{
				[[AppController currentApp] setMovie:movie];
				if([[videoProperties videoFile] rangeOfString:annotationsDirectory].location != NSNotFound)
				{
					[videoProperties setLocalVideo:YES];
				}
			}
			else
			{
				NSLog(@"Error opening base movie");
			}
			
		} else {
			NSLog(@"Can't find video info file...");
		}
				
		if([categories count] == 0)
		{
			for(AnnotationCategory* category in [videoProperties categories])
			{
				[self addCategory:category];
			}	
		}
		
		[videoProperties setCategories:[self categories]];
		
		//////////////////////////////
		// Load additional media files (older method)
		//////////////////////////////
        NSLog(@"Loading media");
		
		media = [[NSMutableArray alloc] init];
		mediaProperties = [[NSMutableArray alloc] init];
		NSMutableArray *mediaDataSources = [[NSMutableArray alloc] init];
		NSString *mediaPath = [annotationsDirectory stringByAppendingPathComponent:@"media.plist"];
		if((documentFormatVersion == 0) && [[NSFileManager defaultManager] fileExistsAtPath:mediaPath])
		{
			NSArray *storedProperties = [[NSKeyedUnarchiver unarchiveObjectWithFile:mediaPath] retain];	
			if(storedProperties)
			{			
				for(VideoProperties *properties in storedProperties)
				{
					BOOL success = [self loadVideoProperties:properties];
					if(success)
					{
						VideoDataSource *videoDataSource = [[VideoDataSource alloc] initWithVideoProperties:properties];
						[mediaDataSources addObject:videoDataSource];
						[videoDataSource release];
					}
				}
			}
			
		} 

        
		////////////////////////
		// Load the annotations
        ////////////////////////
        NSLog(@"Loading annotations");
        
		if([[NSFileManager defaultManager] fileExistsAtPath:annotationsFile])
		{
			xmlParser = [[AnnotationXMLParser alloc] initWithFile:annotationsFile forDocument:self];
		} else {
			xmlParser = [[AnnotationXMLParser alloc] initForDocument:self];
		}
		
		// Clear out temporary annotations
		NSMutableArray *tempCategories = [[NSMutableArray alloc] init];
		for(AnnotationCategory *category in categories)
		{
			if([category temporary])
			{
				[tempCategories addObject:category];
				NSArray *annotations = [self annotationsForCategory:category];
				[self removeAnnotations:annotations];
			}
		}
		while([tempCategories count] > 0)
		{
			[self removeCategory:[tempCategories lastObject]];
			[tempCategories removeObject:[tempCategories lastObject]];
		}
		[tempCategories release];
		
        
		/////////////////
		// Initialize the data sources and load data sets
        /////////////////
        NSLog(@"Loading data");
        
		NSString *dataSourcesPath = [annotationsDirectory stringByAppendingPathComponent:@"dataSources.archive"];
		NSString *dataPath = [annotationsDirectory stringByAppendingPathComponent:@"data.archive"];
		if([[NSFileManager defaultManager] fileExistsAtPath:dataSourcesPath])
		{
            if([[[NSFileManager defaultManager] attributesOfItemAtPath:dataSourcesPath error:&err] fileSize] > 10000000L)
            {
                [[AppController currentApp] showDocumentLoading:self];
            }
            
			dataSources = [[NSKeyedUnarchiver unarchiveObjectWithFile:dataSourcesPath] retain];	
			if(!dataSources)
			{
				dataSources = [[NSMutableArray alloc] init];
			}
            
            if([dataSources count] > 1)
            {
                [[AppController currentApp] showDocumentLoading:self];
            }
            
			NSMutableArray *dataSourcesCopy = [dataSources copy];
			for(DataSource* dataSource in dataSourcesCopy)
			{
				BOOL success = [self loadDataSource:dataSource];
				if(!success)
				{
					[dataSources removeObject:dataSource];
				}
			}
			[dataSourcesCopy release];
			
		} 
		else if([[NSFileManager defaultManager] fileExistsAtPath:dataPath]) 
		{
			NSArray *tempData = [[NSKeyedUnarchiver unarchiveObjectWithFile:dataPath] retain];
			if([tempData count] > 0)
			{
				NSAlert *alert = [[NSAlert alloc] init];
				[alert setMessageText:
				 [NSString stringWithFormat:@"The file %@ was created with an older version of ChronoViz, and the time series data format is no longer supported.",[filename lastPathComponent]]];
				[alert setInformativeText:@"Would you like to cancel opening, or remove the old time series data and continue opening?"];
				[alert addButtonWithTitle:@"Open Without Data"];
				[alert addButtonWithTitle:@"Cancel Opening"];
				
				NSInteger result = [alert runModal];
				
				if(result != NSAlertFirstButtonReturn)
				{
					[self release];
					return nil;
				}	
			}
			
			dataSources = [[NSMutableArray alloc] init]; 
			
			[[NSFileManager defaultManager] removeItemAtPath:dataPath error:&err];
			
		}
		else
		{
			dataSources = [[NSMutableArray alloc] init]; 
		}
		
		[dataSources addObjectsFromArray:mediaDataSources];
		[mediaDataSources release];
		
		for(Annotation* annotation in [self annotations])
		{
			if([annotation source])
			{
				for(DataSource *dataSource in dataSources)
				{
					if([[annotation source] isEqualToString:[dataSource uuid]] ||
					   [[annotation source] isEqualToString:[dataSource dataFile]] ||
					   [[annotation source] isEqualToString:[dataSource name]])
					{
						[dataSource addAnnotation:annotation];
					}
				}
			}
		}
		
		if([annotationsDirectory rangeOfString:@"tempannotation"].location == NSNotFound)
		{
			[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:filename]];
		}
		
		if([[NSUserDefaults standardUserDefaults] boolForKey:AFTrackActivityKey])
		{
            NSData *activityData = [documentProperties valueForKey:@"DPActivityData"];
            
            if(activityData)
            {
                self.activityLog = (DPActivityLog*)[NSKeyedUnarchiver unarchiveObjectWithData:activityData];
            }
            else
            {
                DPActivityLog *log = [[DPActivityLog alloc] initForDocument:self];
                self.activityLog = log;
                [log release];	
            }

		}
		
	}
    
	return self;
}


//
// Takes a VideoProperties object that has been loaded from a file on disk
// prepares it for use and adds it to the document
//
- (BOOL)loadVideoProperties:(VideoProperties*)properties
{
	[self updateMediaFile:properties];
	AVAsset *mediaObject = [properties loadMovie];
	if(!mediaObject)
	{
		return NO;
		//[mediaProperties removeObject:properties];
	}
	else
	{
		//[mediaObject setAttribute:0 forKey:QTMovieLoopsAttribute];
		[media addObject:mediaObject];
		[mediaProperties addObject:properties];
		[properties setMovie:mediaObject];
		[[AppController currentApp] registerMedia:properties andDisplay:NO];
	}
	return YES;
}

//
// Takes a DataSource object that has been loaded from a file on disk
// Prepares it for use and adds it to the document
//
- (BOOL)loadDataSource:(DataSource*)dataSource
{
	NSLog(@"Data Source: %@ %@",[dataSource name],[dataSource dataFile]);
	
	if([dataSource isKindOfClass:[CompoundDataSource class]])
	{
		NSArray *sources = [(CompoundDataSource*)dataSource dataSources];
		for(DataSource *source in sources)
		{
			BOOL success = [self loadDataSource:source];
			if(!success)
			{
				[(CompoundDataSource*)dataSource removeDataSource:source];
			}
		}
		return YES;
	}
	
	if([dataSource isKindOfClass:[VideoDataSource class]])
	{
		return [self loadVideoProperties:[(VideoDataSource*)dataSource videoProperties]];
	}
	else if([dataSource dataFile])
	{
		[self updateDataFile:dataSource];	
	}
	else if(![dataSource local])
	{
		[dataSource setDataFile:@""];
		return NO;
	}
	
//    BOOL showingImages = NO;
	for(TimeCodedData* dataSet in [dataSource dataSets])
	{
		[dataSet setSource:dataSource];
        
//		if([dataSet isKindOfClass:[TimeCodedImageFiles class]] && !showingImages)
//		{
//            [[[AppController currentApp] viewManager] showDataInMainView:dataSet];
//            showingImages = YES;
//			//[[AppController currentApp] showImageSequence:(TimeCodedImageFiles*)dataSet  inMainWindow:[videoProperties localVideo]];
//		}
	}
	
	[dataSource load];
	
	return YES;
			
}



- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.activityLog = nil;
	
	[annotationsDirectory release];
	[annotationsImageDirectory release];
	[videoInfoFile release];
	[annotationsFile release];
	[documentProperties release];
	[videoProperties release];
	[xmlParser release];
	[media release];
	[mediaProperties release];
	[dataSources release];
	[categories release];
	[keywords release];
	
	[super dealloc];
}

- (AVAsset*)setVideoFile:(NSString*)videoFile
{
    AVAsset *movie = nil;
    NSError *err = nil;
    /*
	if (![QTMovieModernizer requiresModernization:[NSURL URLWithString:videoFile] error:&err])
	{
        [videoProperties setMovie:nil];
        [videoProperties setVideoFile:videoFile];
        movie = [videoProperties loadMovie];
        if(!movie)
        {
            NSLog(@"Error loading movie: %@",videoFile);
        }
        else
        {
            [[AppController currentApp] setMovie:movie];
        }
	}
    */
    // TODO: Omit modernizer?
	return movie;
}

- (NSString*)createVideoFileWithDuration:(CMTime)time
{
    NSString *movieFile = [annotationsDirectory stringByAppendingPathComponent:@"video.mov"];
    NSString *altMovieFile = [annotationsDirectory stringByAppendingPathComponent:@"video1.mov"];
    NSString* imageName = [[NSBundle mainBundle] pathForResource:@"black" ofType:@"gif"];
    NSImage* imageObj = [[NSImage alloc] initWithContentsOfFile:imageName];
    
    NSString *deleteFile = nil;
    if([movieFile fileExists])
    {
        deleteFile = movieFile;
        movieFile = altMovieFile;
    }
    else if([altMovieFile fileExists])
    {
        deleteFile = altMovieFile;
    }
    
    [AFAVAssetCreator createNewMovieAtPath:[NSURL URLWithString:movieFile]
                                 fromImage:imageObj
                              withDuration:CMTimeGetSeconds([self duration])];
    
    [imageObj release];
    
    if(deleteFile)
    {
        [deleteFile deleteFile];
    }
}

- (BOOL)setDuration:(CMTime)duration
{
	if([videoProperties localVideo])
	{
        [self createVideoFileWithDuration:duration];
		
		// [self setVideoFile:movieFile];
        // TODO: Is this required?
		
		return YES;
	}
	else
	{
		return NO;
	}
}

- (CMTime)duration
{
	return [[[self movie] currentItem] duration];
}

- (int32_t)defaultTimebase
{
    return (int32_t)[[NSUserDefaults standardUserDefaults] integerForKey:AFTimebaseKey];
}

#pragma mark Annotations

- (void)addAnnotation:(Annotation*)annotation
{	
	[self addAnnotations:[NSArray arrayWithObject:annotation]];
}

- (void)addAnnotations:(NSArray*)annotations
{
	for(Annotation *annotation in annotations)
	{
		[annotation retain];
		//[self addAnnotation:annotation];
		if([annotation document] && ([annotation document] != self))
		{
			[[annotation document] removeAnnotation:annotation];
		}
		[annotation setDocument:self];
		[xmlParser addAnnotation:annotation];
		[[AppController currentApp] addAnnotation:annotation];
		[annotation release];
	}
	
	[self saveAnnotations];

}

- (void)removeAnnotation:(Annotation*)annotation
{
	
	[self removeAnnotations:[NSArray arrayWithObject:annotation]];
}

- (void)removeAnnotations:(NSArray*)annotations
{
	for(Annotation *annotation in annotations)
	{
		[annotation setDocument:nil];
		[[AppController currentApp] removeAnnotation:annotation];
		[xmlParser removeAnnotation:annotation];
	}
	
	[self saveAnnotations];
}

- (void)saveAnnotations
{
	[xmlParser writeToFile:annotationsFile];
}

- (void)saveAnnotationsNow
{
	[xmlParser writeToFile:annotationsFile waitUntilDone:YES];
}

#pragma mark Categories

+ (NSArray*)defaultCategories
{
	NSMutableArray *defaultCategories = [NSMutableArray array];
	
	NSArray *defaultColors = [[NSArray alloc] initWithObjects:
							  @"Blue",
							  @"Red",
							  @"Green",
							  @"Orange",
							  @"Yellow",
							  nil];
	
	int categoryIndex = 1;
	for(NSString *colorName in defaultColors)
	{
		AnnotationCategory *category = [[AnnotationCategory alloc] init];
		category.name = [NSString stringWithFormat:@"Category %i",categoryIndex];
		categoryIndex++;
		category.color = [Annotation colorForString:colorName];
		[defaultCategories addObject:category];
		[category release];
	}
	
	return defaultCategories;
}

- (AnnotationCategory*)categoryForName:(NSString*)categoryName
{
	for(AnnotationCategory *category in [self categories])
	{
		if([categoryName isEqualToString:[category name]])
		{
			return category;
		}
	}
	return nil;
}

- (AnnotationCategory*)categoryForIdentifier:(NSString*)qualifiedCategoryName
{
	NSArray *components = [qualifiedCategoryName componentsSeparatedByString:DPAltColon];
	if([components count] == 2)
	{
		AnnotationCategory *category = [self categoryForName:[components objectAtIndex:0]];
		return [category valueForName:[components objectAtIndex:1]];
	}
	else if ([components count] == 1)
	{
		return [self categoryForName:[components objectAtIndex:0]];
	}
	else
	{
		return nil;
	}
}

- (AnnotationCategory*)createCategoryForIdentifier:(NSString*)qualifiedCategoryName
{
	NSArray *components = [qualifiedCategoryName componentsSeparatedByString:DPAltColon];
	if([components count] == 2)
	{
		AnnotationCategory *category = [self categoryForName:[components objectAtIndex:0]];
        if(!category)
        {
            category = [self createCategoryWithName:[components objectAtIndex:0]];
        }
		return [category valueForName:[components objectAtIndex:1]];
	}
	else if ([components count] == 1)
	{
        AnnotationCategory *category = [self categoryForName:[components objectAtIndex:0]];
        if(!category)
        {
            category = [self createCategoryWithName:[components objectAtIndex:0]];
        }
        return category;
	}
	else
	{
		return nil;
	}
}

- (AnnotationCategory*)createCategoryWithName:(NSString*)name
{
    if(!name)
    {
        return nil;
    }
    
	for(AnnotationCategory *existing in [self categories])
	{
		if([name isEqualToString:[existing name]])
		{
			return nil;
		}
	}
	AnnotationCategory *category = [[AnnotationCategory alloc] init];
	[category setName:name];
	[category setColor:[NSColor whiteColor]];
	[self addCategory:category];
	[category release];
	return category;
}

- (AnnotationCategory*)annotationCategoryForKeyEquivalent:(NSString*)key
{
	for(AnnotationCategory *category in [self categories])
	{
		if([[category keyEquivalent] caseInsensitiveCompare:key] == NSOrderedSame)
		{
			return category;
		}
		for(AnnotationCategory *value in [category values])
		{
			if([[value keyEquivalent] caseInsensitiveCompare:key] == NSOrderedSame)
			{
				return value;
			}
		}
	}
	
	return nil;
}

- (Annotation*)addAnnotationForCategoryKeyEquivalent:(NSString*)key
{	
	AnnotationCategory *category = [self annotationCategoryForKeyEquivalent:key];
	
	if(category)
	{
		Annotation* annotation = [[Annotation alloc] initWithCMTime:[[AppController currentApp] currentTime]];
		[annotation setCategory:category];
		[annotation setAnnotation:@""];
		[self addAnnotation:annotation];
		[annotation release];
		return annotation;
	}
	else
	{
		return nil;
	}
}

- (NSString*)identifierForCategory:(AnnotationCategory*)category
{
	if([category category])
	{
		return [[[self identifierForCategory:[category category]] stringByAppendingString:DPAltColon] stringByAppendingString:[category name]];
	}
	else
	{
		return [category name];
	}
}

- (void)addCategory:(AnnotationCategory*)category
{
	[self addCategory:category atIndex:[categories count]];
//	if(![categories containsObject:category])
//	{
//		[categories addObject:category];	
//	}
}

- (void)addCategory:(AnnotationCategory*)category atIndex:(NSInteger)index
{
	if(category 
	   && ![categories containsObject:category]
	   && (index <= [categories count]))
	{
		[categories insertObject:category atIndex:index];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(processCategoryChange:)
													 name:DPCategoryChangeNotification
												   object:category];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:CategoriesChangedNotification object:self];
	}
}

- (void)moveCategory:(AnnotationCategory*)category toIndex:(NSInteger)index
{
	if(category 
	   && [categories containsObject:category]
	   && (index <= [categories count]))
	{
		if(index > [categories indexOfObject:category])
		{
			index--;
		}
		
		[categories removeObject:category];
		
		[categories insertObject:category atIndex:index];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:CategoriesChangedNotification object:self];
	}
}

- (void)removeCategory:(AnnotationCategory*)category
{
	NSArray* annotations = [self annotations];
	
	for(Annotation* annotation in annotations)
	{
		if([annotation category] == category)
		{
			[annotation setCategory:nil];
			[annotation setColorObject:nil];
			[annotation setUpdated];
		}
	}
	
	[categories removeObject:category];
	
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:CategoriesChangedNotification object:self];
	
}

- (void)saveCategories
{	
	//[self saveVideoProperties:videoProperties];
    [self saveDocumentProperties];
}

- (void)processCategoryChange:(id)sender
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:CategoriesChangedNotification object:self];
}

#pragma mark Keywords

- (void)addKeyword:(NSString*)keyword
{
	[keywords addObject:keyword];
}

- (void)removeKeyword:(NSString*)keyword
{
	[keywords removeObject:keyword];
}

- (BOOL)keywordExists:(NSString*)keyword
{
	return [keywords containsObject:keyword];
}

#pragma mark Data

- (void)addDataSource:(DataSource*)dataSource
{
	if(![dataSources containsObject:dataSource])
	{
		if([dataSource isKindOfClass:[VideoDataSource class]])
		{
            VideoProperties *properties = [(VideoDataSource*)dataSource videoProperties];
            if(([dataSources count] == 0) && ([[self annotations] count] == 0) &&
               ([[videoProperties videoFile] rangeOfString:annotationsDirectory].location != NSNotFound))
            {
                [properties loadMovie];
                if(![properties hasVideo])
                {
                    [self setDuration:[[[properties movie] currentItem] duration]];
                    [media addObject:[properties loadMovie]];
                    [mediaProperties addObject:properties];
                    [self saveVideoProperties:properties];
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:MediaChangedNotification
                     object:self
                     userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:properties]
                                                          forKey:DPMediaAddedKey]];
                }
                else
                {
                    [properties retain];
                    [videoProperties release];
                    videoProperties = properties;
                    [[AppController currentApp] setMovie:[videoProperties loadMovie]];
                    [self saveVideoProperties:videoProperties];
                    
                    [[NSNotificationCenter defaultCenter]
                     postNotificationName:MediaChangedNotification
                     object:self
                     userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:properties]
                                                          forKey:DPMediaAddedKey]];
                    
                    return;
                }
            }
            else
            {            
                [media addObject:[properties loadMovie]];
                [mediaProperties addObject:properties];
                [self saveVideoProperties:properties];
                
                [[NSNotificationCenter defaultCenter]
                 postNotificationName:MediaChangedNotification 
                 object:self
                 userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:properties] 
                                                      forKey:DPMediaAddedKey]];
                
                [properties addObserver:self forKeyPath:@"title" options:0 context:NULL];
            }
		}
		
		[dataSources addObject:dataSource];
//		[[NSNotificationCenter defaultCenter] addObserver:self
//												 selector:@selector(saveData)
//													 name:DataSourceUpdatedNotification
//												   object:dataSource];
		[self saveData];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:DataSetsChangedNotification object:self];
	}
}

- (void)removeDataSource:(DataSource*)dataSource
{
	if([dataSources containsObject:dataSource])
	{
		if([dataSource isKindOfClass:[VideoDataSource class]])
		{
			VideoProperties *properties = [(VideoDataSource*)dataSource videoProperties];
			if([mediaProperties containsObject:properties] && [properties movie])
			{
                [properties retain];
				[media removeObject:[properties movie]];
				[mediaProperties removeObject:properties];
				[self saveMediaFiles];
				
				[[NSNotificationCenter defaultCenter]
				 postNotificationName:MediaChangedNotification
				 object:self
				 userInfo:[NSDictionary dictionaryWithObject:[NSArray arrayWithObject:properties] 
													  forKey:DPMediaRemovedKey]];
                [properties release];
			}
		}
		
		for(TimeCodedData* dataSet in [dataSource dataSets])
		{
			NSLog(@"Remove data %@",[dataSet name]);
			if([dataSet isKindOfClass:[AnnotationSet class]])
			{
				[self removeAnnotations:[(AnnotationSet*)dataSet annotations]];
			}
			else
			{
				[[[AppController currentApp] viewManager] removeData:dataSet];
			}
			
		}
		
		[dataSources removeObject:dataSource];
		[self saveData];
		
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:DataSetsChangedNotification object:self];
	}
}

- (BOOL)hasDataFile:(NSString*)file
{
	return [self dataFile:file inSources:dataSources];
}

- (BOOL)dataFile:(NSString*)file inSources:(NSArray*)sourcesArray
{
	for(DataSource *source in sourcesArray)
	{
		if([source isKindOfClass:[CompoundDataSource class]])
		{
			if([self dataFile:file inSources:[(CompoundDataSource*)source dataSources]])
			{
				return YES;
			}
		}
		else
		{
			if([[source dataFile] isEqualToString:file])
			{
				return YES;
			}
		}
	}
	return NO;
}

- (CompoundDataSource*)createCompoundDataSource:(NSArray*)sources
{
	if(!sources || [sources count] == 0)
	{
		return nil;
	}
	
	CompoundDataSource *compound = [[CompoundDataSource alloc] init];
	[compound setName:[[sources objectAtIndex:0] name]];
	
	for(DataSource *data in sources)
	{
		if([dataSources containsObject:data])
		{
			[compound addDataSource:data];
			[dataSources removeObject:data];
		}
	}
	
	[self addDataSource:compound];
	
	[compound release];
	
	return compound;
}

- (DataSource*)dataSourceForAnnotation:(Annotation*)annotation
{
	if([annotation source])
	{
		for(DataSource *dataSource in dataSources)
		{
			if([[annotation source] isEqualToString:[dataSource uuid]] ||
			   [[annotation source] isEqualToString:[dataSource dataFile]] ||
			   [[annotation source] isEqualToString:[dataSource name]])
			{
				return dataSource;
			}
		}
	}
	return nil;
}


#pragma mark Saving

- (void)save
{
    [self saveData];
	[self saveCategories];
    
	for(Annotation* annotation in [self annotations])
	{
		[xmlParser updateAnnotation:annotation];
	}
    [self saveAnnotationsNow];
    
    [self saveVideoProperties:videoProperties];
	[self saveMediaFiles];
	[self saveDocumentProperties];
}

- (void)saveState:(NSData*)stateData
{
	NSError *err;
	
	[stateData writeToFile:[annotationsDirectory stringByAppendingPathComponent:@"State.data"] options:0 error:&err];
}

- (NSData*)stateData
{
	NSString* stateFile = [annotationsDirectory stringByAppendingPathComponent:@"State.data"];
	if([stateFile fileExists])
	{
		return [NSData dataWithContentsOfFile:stateFile];
	}
	else
	{
		return nil;
	}	
}

- (void)saveData
{
	NSString *archivePath = [annotationsDirectory stringByAppendingPathComponent:@"dataSources.archive"];
	[NSKeyedArchiver archiveRootObject:dataSources toFile:archivePath];
}

- (void)saveVideoProperties:(VideoProperties*)properties
{
	if(properties == [self videoProperties])
	{
		[properties saveToFile:[self videoInfoFile]];
	}
	else if([mediaProperties containsObject:properties])
	{
		[self saveMediaFiles];
	}
}

- (void)saveMediaFiles
{
	NSString *archivePath = [annotationsDirectory stringByAppendingPathComponent:@"media.plist"];
	[NSKeyedArchiver archiveRootObject:mediaProperties toFile:archivePath];	
}

- (BOOL)saveToPackage:(NSString*)newPath
{
	NSError *err;
	NSFileManager *manager=[NSFileManager defaultManager];
	NSString *currentFileName=annotationsDirectory;
	if ([currentFileName isEqualToString:newPath])
		return NO;
	if ([manager fileExistsAtPath:newPath]
		&& ![manager removeItemAtPath:newPath error:&err])
		return NO;
	
	//NSFileWrapper *newMain = [[NSFileWrapper alloc] initRegularFileWithContents:[videoProperties serialize]];
    NSFileWrapper *newMain = [[NSFileWrapper alloc] initRegularFileWithContents:[NSKeyedArchiver archivedDataWithRootObject:videoProperties]];
	NSFileWrapper *newFile = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:
							  [NSDictionary dictionaryWithObjectsAndKeys:newMain,@"videoInfo.plist",nil]];
	
	//save it at the new location
	BOOL returnedFlag=[newFile writeToFile:newPath atomically:YES updateFilenames:NO];
	
	if(returnedFlag)
	{
		// If we're using a video that's part of the annotation document
		if([[videoProperties videoFile] rangeOfString:annotationsDirectory].location != NSNotFound)
		{
			[[NSFileManager defaultManager] copyItemAtPath:[videoProperties videoFile]
													toPath:[newPath stringByAppendingPathComponent:[[videoProperties videoFile] lastPathComponent]] 
													 error:&err];
			[videoProperties setVideoFile:[newPath stringByAppendingPathComponent:[[videoProperties videoFile] lastPathComponent]]];
		}
		
		[[NSFileManager defaultManager] copyItemAtPath:annotationsImageDirectory 
												toPath:[newPath stringByAppendingPathComponent:@"images"] 
												 error:&err];
		
		[annotationsImageDirectory release];
		[videoInfoFile release];
		[annotationsFile release];
		[annotationsDirectory release];
		annotationsDirectory = [newPath retain];
		annotationsImageDirectory = [[annotationsDirectory stringByAppendingPathComponent:@"images"] retain];
		videoInfoFile = [[annotationsDirectory stringByAppendingPathComponent:@"videoInfo.plist"] retain];
		annotationsFile = [[annotationsDirectory stringByAppendingPathComponent:@"annotations.xml"] retain];
		
		[self save];
		
		[[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:newPath]];
        [[[AppController currentApp] window] setTitle:[[annotationsDirectory lastPathComponent] stringByDeletingPathExtension]];

	}
	else 
	{
		NSLog(@"Error saving annotation package.");
	}
	
	
	[newFile release];
	[newMain release];
	return returnedFlag;
}


- (void)saveDocumentProperties
{
	NSString *errorDesc;
	
	[documentProperties setObject:[NSNumber numberWithInt:1] forKey:@"DPDocumentFormatVersion"];
	
	[documentProperties setObject:annotationsDirectory forKey:@"SavedLocation"];

	NSData *categoriesData = [NSKeyedArchiver archivedDataWithRootObject:[self categories]];
	
	[documentProperties setObject:categoriesData forKey:@"DPCategories"];
	
	[documentProperties setObject:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"] forKey:@"DPChronoVizVersion"];
	
    if(self.activityLog && [[NSUserDefaults standardUserDefaults] boolForKey:AFTrackActivityKey])
    {
        NSData *activityData = [NSKeyedArchiver archivedDataWithRootObject:self.activityLog];
        [documentProperties setObject:activityData forKey:@"DPActivityData"];
    }
    
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:documentProperties
																   format:NSPropertyListXMLFormat_v1_0
														 errorDescription:&errorDesc];
	if (!plistData) {
        NSLog(@"%@",errorDesc);
        [errorDesc release];
		return;
    }
	
	[plistData writeToFile:[annotationsDirectory stringByAppendingPathComponent:@"properties.plist"] atomically:YES];
	
}

#pragma mark Named States

- (void)saveState:(NSData*)stateData withName:(NSString*)stateName
{
    [savedLayouts setObject:stateData forKey:stateName];
}

- (NSArray*)savedStates
{
    return [savedLayouts allKeys];
}

- (NSData*)stateForName:(NSString*)stateName
{
    return [savedLayouts objectForKey:stateName];
}

- (void)removeStateNamed:(NSString*)stateName
{
    [savedLayouts removeObjectForKey:stateName];
}

#pragma mark Updating Paths

- (void)updateMediaFile:(VideoProperties*)props
{
	NSString *videoFile = [props videoFile];
    
    NSString *newFile = nil;
    if([props localVideo]
       && ![videoFile fileExists])
    {
        newFile = [[self annotationsDirectory] stringByAppendingPathComponent:[videoFile lastPathComponent]];
        if(![newFile fileExists])
        {
            newFile = nil;
        }
    }
    else
    {
        newFile = [self resolveFile:videoFile];
    }
	
	if(!newFile)
	{
		newFile = [videoFile stringByAskingForReplacement];
	}
	
	if(newFile != videoFile)
	{
		[props setVideoFile:newFile];
	}

}

- (void)updateDataFile:(DataSource*)source
{
	NSString *dataFile = [source dataFile];
	NSString *newFile = [self resolveFile:dataFile];
	
	if(!newFile)
	{
		if([source directoryDataFile])
		{
			newFile = [dataFile stringByAskingForReplacementDirectory];
		}
		else
		{
			newFile = [dataFile stringByAskingForReplacement];
		}
	}
	
	if(newFile != dataFile)
	{
		[source setDataFile:newFile];
	}
}

- (NSString*)resolveFile:(NSString*)file
{
	if([file fileExists])
	{
		return file;
	}
	else if([file rangeOfString:@"/Dropbox/"].location != NSNotFound)
	{
		
		NSString *relativePath = [@"~" stringByAppendingString:[file substringFromIndex:[file rangeOfString:@"/Dropbox/"].location]];
		NSString *newFile = [relativePath stringByStandardizingPath];
		NSLog(@"Updating Dropbox File: %@",newFile);
		if([newFile fileExists])
		{
			return newFile;
		}
		
	}
	else if([documentProperties objectForKey:@"SavedLocation"])
	{
		NSString *savedLocation = [documentProperties objectForKey:@"SavedLocation"];
		NSString *relativePath = [file relativePathFromBaseDirPath:savedLocation];
		NSString *newPath = [relativePath absolutePathFromBaseDirPath:annotationsDirectory];
		
		NSLog(@"Checking relative path...");
		NSLog(@"Original path: %@",file);
		NSLog(@"Relative path: %@",relativePath);
		NSLog(@"New path: %@",newPath);
		
		if([newPath fileExists])
		{
			return newPath;
		}

	}

	return nil;
}

#pragma mark Accessors

- (NSArray*)annotations
{
	return [xmlParser annotations];
}

- (NSArray*)annotationsForCategory:(AnnotationCategory*)category
{
	NSMutableArray *results = [NSMutableArray array];
	for(Annotation* annotation in [xmlParser annotations])
	{
		if([[annotation categories] containsObject:category])
		{
			[results addObject:annotation];
		}
	}
	return results;
}

- (NSArray*)categories
{
	return categories;
}

- (NSArray*)keywords
{
	return keywords;
}

- (NSString*)annotationsDirectory
{
	return annotationsDirectory;
}

- (NSString*)annotationsImageDirectory
{
	return annotationsImageDirectory;
}

- (NSString*)annotationsFile
{
	return annotationsFile;
}

- (NSString*)videoInfoFile
{
	return videoInfoFile;
}

- (VideoProperties*)videoProperties
{
	return videoProperties;
}

- (AnnotationXMLParser*)xmlParser
{
	return xmlParser;
}

- (NSArray*)dataSets
{
	NSMutableArray *dataSets = [NSMutableArray array];
	
	for(DataSource *source in dataSources)
	{
		[dataSets addObjectsFromArray:[source dataSets]];	
	}
	
	return dataSets;
	
	//return data;
}

- (NSArray*)dataSetsOfClass:(Class)dataSetClass
{
	NSMutableArray *set = [NSMutableArray array];
	for(TimeCodedData* dataSet in [self dataSets])
	{
		if([dataSet isKindOfClass:dataSetClass])
		{
			[set addObject:dataSet];
		}
	}
	return set;
}

- (NSArray*)timeSeriesData
{
	return [self dataSetsOfClass:[TimeSeriesData class]];
	
//	NSMutableArray *timeSeriesData = [NSMutableArray array];
//	for(TimeCodedData* dataSet in [self dataSets])
//	{
//		if([dataSet isKindOfClass:[TimeSeriesData class]])
//		{
//			[timeSeriesData addObject:dataSet];
//		}
//	}
//	return timeSeriesData;
}

- (NSArray*)dataSources
{
	return dataSources;
}

- (AVAsset*)movie
{
	return [videoProperties loadMovie];
}

- (NSArray*)media
{
	return media;
}

- (NSArray*)mediaProperties
{
	return mediaProperties;
}

- (NSArray*)allMediaProperties
{
    return [[NSArray arrayWithObject:videoProperties] arrayByAddingObjectsFromArray:mediaProperties];
}

- (NSMutableDictionary*)documentVariables
{
	NSMutableDictionary *userVariables = [documentProperties objectForKey:@"DPUserVariables"];
	if(!userVariables)
	{
		userVariables = [NSMutableDictionary dictionary];
		[documentProperties setObject:userVariables forKey:@"DPUserVariables"];
	}
	return userVariables;
}

- (NSDate*)startDate
{
	return [videoProperties startDate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"title"])
	{
		[[NSNotificationCenter defaultCenter]
		 postNotificationName:MediaChangedNotification object:self];
    }
	else
	{
		[super observeValueForKeyPath:keyPath
							 ofObject:object
							   change:change
							  context:context];
	}
}



@end
