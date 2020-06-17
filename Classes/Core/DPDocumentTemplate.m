//
//  DPDocumentTemplate.m
//  ChronoViz
//
//  Created by Adam Fouse on 11/13/12.
//
//

#import "DPDocumentTemplate.h"
#import "AnnotationDocument.h"
#import "AppController.h"
#import "DPViewManager.h"
#import "VideoProperties.h"
#import "DataSource.h"
#import "TimeCodedData.h"
#import "NSStringFileManagement.h"
#import "AnnotationCategory.h"
#import "NSColorHexadecimalValue.h"

@interface DPDocumentTemplate (Internal)

-(AnnotationCategory*)createCategoryFromElement:(NSXMLElement*)categoryElement;

@end

@implementation DPDocumentTemplate

-(id)initFromURL:(NSURL*)fileURL
{
    self = [super init];
    if (self) {
        NSString *filePath = [fileURL path];
        if([[filePath pathExtension] caseInsensitiveCompare:@"chronoviztemplate"] == NSOrderedSame)
        {
            NSError *err = nil;
            templateXMLDoc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath]
                                                                 options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
                                                                   error:&err];
            
            
            
            if ((templateXMLDoc == nil) || err)
            {
                if (err)
                {
                    NSLog(@"Error: %@",[err localizedDescription]);
                }
                [self release];
                return nil;
            }
            
            if([[[templateXMLDoc rootElement] name] caseInsensitiveCompare:@"chronoVizDocumentTemplate"] != NSOrderedSame)
            {
                NSLog(@"Expected root element of template file to be 'chronoVizDocumentTemplate'.");
                [templateXMLDoc release];
                templateXMLDoc = nil;
                [self release];
                return nil;
            }
            
            templateURL = [fileURL retain];
            
            dataTypes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                       DataTypeTimeSeries,@"DataTypeTimeSeries",
                                       DataTypeGeographicLat,@"DataTypeGeographicLat",
                                       DataTypeGeographicLon,@"DataTypeGeographicLon",
                                       DataTypeImageSequence,@"DataTypeImageSequence",
                                       DataTypeAnnotationTime,@"DataTypeAnnotationTime",
                                       DataTypeAnnotationEndTime,@"DataTypeAnnotationEndTime",
                                       DataTypeAnnotationTitle,@"DataTypeAnnotationTitle",
                                       DataTypeAnnotationCategory,@"DataTypeAnnotationCategory",
                                       DataTypeAnnotation,@"DataTypeAnnotation",
                                       DataTypeAudio,@"DataTypeAudio",
                                       DataTypeTranscript,@"DataTypeTranscript",
                                       DataTypeSpatialX,@"DataTypeSpatialX",
                                       DataTypeSpatialY,@"DataTypeSpatialY", nil];
        }
    }
    return self;
}

- (void)dealloc
{
    [templateXMLDoc release];
    [templateURL release];
    [dataTypes release];
    [super dealloc];
}


-(void)applyToDocument:(AnnotationDocument*)document
{
    
    // Process Data Sets
    
    NSArray *datasourcecollections = [[templateXMLDoc rootElement] elementsForName:@"dataSources"];
	
    NSString *basePath = [[templateURL path] stringByDeletingLastPathComponent];
    
	for(NSXMLElement *datasourcecollection in datasourcecollections)
	{
		NSArray *datasources = [datasourcecollection elementsForName:@"dataSource"];

		for(NSXMLElement *datasource in datasources)
		{
            NSArray *pathElements = [datasource elementsForName:@"filePath"];
            NSArray *typeElements = [datasource elementsForName:@"type"];
            NSArray *startTimeElements = [datasource elementsForName:@"startTime"];
            
            if(([pathElements count] == 0) || ([typeElements count] == 0) || ([startTimeElements count] == 0))
            {
                NSLog(@"Template Loading Error: Data source missing filePath, type, or startTime.");
                continue;
            }
            
            NSString* path = [[pathElements objectAtIndex:0] stringValue];
            NSString* type = [[typeElements objectAtIndex:0] stringValue];
            CGFloat starttime = [[[startTimeElements objectAtIndex:0] stringValue] floatValue];
            
            if([[basePath stringByAppendingPathComponent:path] fileExists])
            {
                path = [basePath stringByAppendingPathComponent:path];
            }
            else if (![path fileExists])
            {
                NSLog(@"Template Loading Error: File does not exist: %@",path);
                continue;
            }
            
            DataSource *source = nil;
            if([type isEqualToString:@"CSVDataSource"])
            {
                NSArray *timeCodingElements = [datasource elementsForName:@"timeCoding"];
                NSArray *timeColumnElements = [datasource elementsForName:@"timeColumn"];
                
                if(([timeCodingElements count] == 0) || ([timeColumnElements count] == 0))
                {
                    NSLog(@"Template Loading Error: timeCoding and timeColumn must be defined for a CSV data source");
                    continue;
                }
                
                NSString* timeCoding = [[timeCodingElements objectAtIndex:0] stringValue];
                NSString* timeColumn = [[timeColumnElements objectAtIndex:0] stringValue];
                
                source = [[DataSource alloc] initWithPath:path];
                NSArray *dataArray = [source dataArray];
                
                NSUInteger timeColumnIndex = [[dataArray objectAtIndex:0] indexOfObject:timeColumn];
                
                if(timeColumnIndex == NSNotFound)
                {
                    NSLog(@"Template Loading Error: Time colum %@ could not be found",timeColumn);
                    continue;
                }
                
                [source setTimeCoded:YES];
                [source setAbsoluteTime:([timeCoding caseInsensitiveCompare:@"Absolute"] == NSOrderedSame)];
                [source setTimeColumn:timeColumnIndex];
                
            }
            else
            {
                Class DataSourceClass = NSClassFromString(type);
                if([DataSourceClass isSubclassOfClass:[DataSource class]])
                {
                    source = [[DataSourceClass alloc] initWithPath:path];
                }
            }
            
            if(source == nil)
            {
                continue;
            }
            
            NSArray *datasetcollections = [datasource elementsForName:@"dataSets"];
            if([datasetcollections count])
            {
                NSArray *datasets = [[datasetcollections objectAtIndex:0] elementsForName:@"dataSet"];
                
                NSMutableArray *variables = [NSMutableArray array];
                NSMutableDictionary *variablesToDisplay = [NSMutableDictionary dictionary];
                NSMutableArray *types = [NSMutableArray array];
                NSMutableDictionary *labels = [NSMutableDictionary dictionary];
                
                for(NSXMLElement *dataset in datasets)
                {
                    NSXMLNode *displayNode = [dataset attributeForName:@"display"];
                    BOOL display = YES;
                    if(displayNode)
                    {
                        display = [[displayNode stringValue] boolValue];
                    }
                    
                    NSArray *variableNameElements = [dataset elementsForName:@"variableName"];
                    NSArray *dataLabelElements = [dataset elementsForName:@"dataLabel"];
                    NSArray *dataTypeElements = [dataset elementsForName:@"dataType"];
                    
                    if(([dataTypeElements count] == 0) || ([variableNameElements count] == 0))
                    {
                        NSLog(@"Template Loading Error: Data Type and Variable Name are both required.");
                        continue;
                    }
                    
                    NSString* variableName = [[variableNameElements objectAtIndex:0] stringValue];
                    NSString* dataTypeString = [[dataTypeElements objectAtIndex:0] stringValue];
                    NSString* dataType = [dataTypes objectForKey:dataTypeString];
                    
                    if(!dataType)
                    {
                        NSLog(@"Template Loading Error: Data type %@ is not supported.",dataTypeString);
                        continue;
                    }
                    
                    NSString *dataLabel;
                    if([dataLabelElements count] == 0)
                    {
                        dataLabel = variableName;
                    }
                    else
                    {
                        dataLabel = [[dataLabelElements objectAtIndex:0] stringValue];
                    }
                    
                    [variables addObject:variableName];
                    [variablesToDisplay setObject:[NSNumber numberWithBool:display] forKey:variableName];
                    [labels setObject:dataLabel forKey:variableName];
                    [types addObject:dataType];
                }
                
                NSArray *importedDataSets = [source importVariables:variables asTypes:types];
                
                CMTimeRange range = [source range];
                range.start = CMTimeMake(starttime, 1000000); // TODO: Check if the timescale is correct.
                [source setRange:range];
                
                BOOL setMovie = NO;
                
                NSTimeInterval oldTI;
                NSTimeInterval newTI;
                
                oldTI = CMTimeGetSeconds([[[document movie] currentItem] duration]);
                newTI = CMTimeGetSeconds([source range].duration);
                
                if([[document videoProperties] localVideo] && ((newTI - oldTI) > 1))
                {
                    NSLog(@"Set duration: Old Time: %f, New Time: %f",oldTI,newTI);
                    setMovie = YES;
                }
                
                if(setMovie)
                {
                    [document setDuration:[source range].duration];
                }
                
                
                NSArray *views = [[AppController currentApp] annotationViews];
                NSMutableArray *displayedData = [NSMutableArray array];
                for(id<AnnotationView> view in views)
                {
                    [displayedData addObjectsFromArray:[view dataSets]];
                }
                
                NSMutableArray *dataSetsToDisplay = [NSMutableArray array];
                
                //[NSMutableArray arrayWithArray:importedDataSets];
                
                for(id obj in importedDataSets)
                {
                    if([obj isKindOfClass:[TimeCodedData class]])
                    {
                        TimeCodedData *dataSet = (TimeCodedData*)obj;
                        NSString *variable = [dataSet variableName];
                        NSString *label = [labels objectForKey:variable];
                        if(!label)
                        {
                            label = variable;
                        }
                        [dataSet setName:label];
                        
                        if([[variablesToDisplay objectForKey:variable] boolValue])
                        {
                            [dataSetsToDisplay addObject:dataSet];
                        }
                        
                    }
                }
                
                [[[AppController currentApp] viewManager] showDataSets:dataSetsToDisplay ifRepeats:NO];
            }
            
            [source setImported:YES];
            
            [document addDataSource:source];
		}
    }
    
    [document saveData];
    
    NSArray *categoryCollections = [[templateXMLDoc rootElement] elementsForName:@"categories"];
    
	for(NSXMLElement *categoryCollection in categoryCollections)
	{
        NSArray *categories = [categoryCollection elementsForName:@"category"];
        
		for(NSXMLElement *categoryElement in categories)
		{
            
            AnnotationCategory *category = [self createCategoryFromElement:categoryElement];
            AnnotationCategory *existingCategory = [document categoryForName:[category name]];
            if(existingCategory) {
                [existingCategory setName:[[existingCategory name] stringByAppendingString:@"-Original"]];
            }
            
            [document addCategory:category];
        }
    }
    
    
    NSArray *annotationCollections = [[templateXMLDoc rootElement] elementsForName:@"annotations"];
    
	for(NSXMLElement *annotationCollection in annotationCollections)
	{
        NSArray *file = [annotationCollection elementsForName:@"filePath"];
        
        if([file count] == 0) {
            NSLog(@"Template Loading Error: Annotations tag must have a filePath child tag.");
            continue;
        }
        
        NSString* path = [[file lastObject] stringValue];
        
        if([[basePath stringByAppendingPathComponent:path] fileExists])
        {
            path = [basePath stringByAppendingPathComponent:path];
        }
        else if (![path fileExists])
        {
            NSLog(@"Template Loading Error: File does not exist: %@",path);
            continue;
        }
        
        [[AppController currentApp] loadAnnotations:path];
        
    }
    
    

    [[AppController currentApp] updateViewMenu];

}


-(AnnotationCategory*)createCategoryFromElement:(NSXMLElement*)categoryElement
{
    NSArray *nameElements = [categoryElement elementsForName:@"name"];
    NSArray *colorElements = [categoryElement elementsForName:@"color"];
    NSArray *valuesElements = [categoryElement elementsForName:@"values"];
    
    
    if([nameElements count] == 0)
    {
        NSLog(@"Template Loading Error: Categories must have a name.");
        return nil;
    }
    
    AnnotationCategory *category = [[AnnotationCategory alloc] init];
    
    [category setName:[[nameElements lastObject] stringValue]];
    
    if([colorElements count] > 0) {
        NSColor *color = [NSColor colorFromHexRGB:[[colorElements lastObject] stringValue]];
        if(color)
        {
            [category setColor:color];
        }
        else
        {
            NSLog(@"Error loading color for category %@",[category name]);
        }
    } else {
        [category autoColor];
    }
    
    if(([valuesElements count] > 0) && (![[categoryElement name] isEqualToString:@"value"]))
    {
        for(NSXMLElement *valuesElement in valuesElements)
        {
            NSArray *valueElements = [valuesElement elementsForName:@"value"];
            for(NSXMLElement *valueElement in valueElements) {
                AnnotationCategory *value = [self createCategoryFromElement:valueElement];
                [category addValue:value];
            }
        }
    }
    
    return [category autorelease];
    
}

@end
