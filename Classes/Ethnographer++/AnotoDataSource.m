//
//  AnotoDataSource.m
//  DataPrism
//
//  Created by Adam Fouse on 2/2/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AnotoDataSource.h"
#import "AnotoTrace.h"
#import "AnotoNotesData.h"
#import "AnnotationSet.h"
#import "Annotation.h"
#import "TimeCodedPenPoint.h"
#import "AnnotationDocument.h"
#import "NSStringFileManagement.h"
#import "DPBluetoothPen.h"
#import "AppController.h"
#import "DPConstants.h"

@implementation AnotoDataSource

@synthesize createAnnotations;


+(NSString*)dataTypeName
{
	return @"Anoto Pen Data";
}

+(BOOL)validateFileName:(NSString*)fileName
{
	return ([[fileName pathExtension] isEqualToString:@"xml"] && ([[fileName lastPathComponent] rangeOfString:@"note"].location == 0));
}

-(id)initWithPath:(NSString *)directory
{	
	BOOL isDirectory = NO;
	
	BOOL isFile = [[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDirectory];
	
	if(!isFile)
	{
		[self release];
		return nil;
	}

	if(!isDirectory)
		directory = [directory stringByDeletingLastPathComponent];;
	
	self = [super initWithPath:directory];
	
	if (self != nil) {
		
		startTime = 0;
		self.predefinedTimeCode = YES;
		self.timeCoded = YES;
		createAnnotations = YES;	
		range = QTMakeTimeRange(QTMakeTimeWithTimeInterval(0), QTMakeTimeWithTimeInterval(0));
		traces = [[NSMutableArray alloc] init];
		annotations = [[NSMutableArray alloc] init];
		backgrounds = [[NSMutableDictionary alloc] init];
		backgroundOffsets = [[NSMutableDictionary alloc] init];
		backgroundScaleCorrection = [[NSMutableDictionary alloc] init];
		pages = [[NSMutableSet alloc] init];
		//[self setName:[@"Anoto Traces - " stringByAppendingString:[directory lastPathComponent]]];
		
		metadataDirectory = [@"chronoviz" retain];
		serverFile = [[metadataDirectory stringByAppendingPathComponent:@"iserver.xml"] retain];
		postscriptFile = nil;
	}
	return self;
}

- (void) dealloc
{
	[metadataDirectory release];
	[serverFile release];
	[postscriptFile release];
	[traces release];
	[annotations release];
	[audio release];
	[backgrounds release];
	[backgroundOffsets release];
	[backgroundScaleCorrection release];
	[pages release];
	[super dealloc];
}

- (NSString*)name
{
	return [@"Digital Notes - " stringByAppendingString:[super name]];
}

-(NSString*)postscriptFile
{
	if(!postscriptFile)
	{
		NSError *error = nil;
		
		NSFileManager *manager = [NSFileManager defaultManager];
		
		NSString* metadataPath = [dataFile stringByAppendingPathComponent:metadataDirectory];
		
		if([metadataPath fileExists])
		{
			NSArray *fileList = [manager contentsOfDirectoryAtPath:metadataPath error:&error];
			for(NSString *file in fileList)
			{
				if([[file pathExtension] caseInsensitiveCompare:@"ps"] == NSOrderedSame)
				{
					postscriptFile = [[metadataPath stringByAppendingPathComponent:file] retain];
					return postscriptFile;
				}
			}
		}
	}
	
	return postscriptFile;
}

-(NSArray*)defaultVariablesToImport
{
	return [NSArray arrayWithObjects:@"Traces",@"Annotations",nil];
}

-(NSArray*)possibleDataTypes
{
	return [NSArray arrayWithObjects:
			DataTypeAnotoTraces,
			DataTypeAnnotation,
			nil];
}

-(NSString*)defaultDataType:(NSString*)variableName
{
	if([variableName rangeOfString:@"Traces" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		return DataTypeAnotoTraces;
	}
	else if([variableName rangeOfString:@"Annotations" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		return DataTypeAnnotation;
	}
	else
	{
		return DataTypeAnnotation;
	}
}

-(NSArray*)dataArray
{
	if(!traces)
		traces = [[NSMutableArray alloc] init];
	
	if(!annotations)
		annotations = [[NSMutableArray alloc] init];
	
	if(!dataArray)
	{
		QTTimeRange rangeTemp = range;
		
		[delegate dataSourceLoadStart];
		[delegate dataSourceLoadStatus:0];
		
		NSError *error;
		
		NSFileManager *manager = [NSFileManager defaultManager];
		
		if(![dataFile fileExists])
		{
			NSString *newFolder = [dataFile stringByAskingForReplacementDirectory];
			[dataFile release];
			dataFile = [newFolder retain];
		}
		
		NSArray *fileList = [manager contentsOfDirectoryAtPath:dataFile error:&error];
		
//		if([fileList containsObject:metadataDirectory])
//		{
//			NSString *penBrowserMappings = [dataFile stringByAppendingPathComponent:mappingFile];
//			NSString *serverFilePath = [dataFile stringByAppendingPathComponent:serverFile];
//			if([penBrowserMappings fileExists] && [serverFilePath fileExists])
//			{
//				[[DPBluetoothPen penClient] updateServerWithMappings:penBrowserMappings andServerXML:serverFilePath];
//			}
//		}
		
		NSMutableArray *fileArray = [NSMutableArray arrayWithCapacity:[fileList count]];
		
		[fileArray addObject:[NSArray arrayWithObjects:@"Traces",@"Annotations",@"Audio",nil]];
		
		float count = 0;
		for(NSString* fileName in fileList)
		{
			count++;
			if([[fileName pathExtension] isEqualToString:@"xml"] && ([[fileName lastPathComponent] rangeOfString:@"note"].location == 0))
			{
				NSLog(@"Load file:%@",fileName);
				NSString *file = [dataFile stringByAppendingPathComponent:fileName];
				//[fileArray addObject:[NSArray arrayWithObject:fileName]];
				[traces addObjectsFromArray:[self tracesFromFile:file]];
				if([delegate dataSourceCancelLoad])
				{
					return nil;
				}
			}
			[delegate dataSourceLoadStatus:(count/[fileList count])];
		}
		NSLog(@"Total traces: %i",[traces count]);
		
		[fileArray addObject:[NSArray arrayWithObjects:
							  [NSNumber numberWithInt:[traces count]],
							  [NSNumber numberWithInt:[annotations count]],
							  [NSNumber numberWithInt:0],
							  nil]];
		
		[self setDataArray:fileArray];
		[delegate dataSourceLoadFinished];
		
		if(rangeTemp.duration.timeValue != 0)
		{
			range = rangeTemp;
		}
	}
	return dataArray;
}

-(NSArray*)importVariables:(NSArray*)variables asTypes:(NSArray*)types
{
	NSMutableArray *newDataSets = [NSMutableArray array];
	
	NSUInteger index;
	for(index = 0; index < [variables count]; index++)
	{
		NSString *variable = [variables objectAtIndex:index];
		NSString *type = [types objectAtIndex:index];
		
		BOOL alreadyIn = NO;
		
		// If this dataSet has already been imported, don't import it again
		for(TimeCodedData *dataSet in dataSets)
		{
			if([variable isEqualToString:[dataSet variableName]])
			{
				[newDataSets addObject:variable];
				alreadyIn = YES;
				break;
			}
		}
		
		if(!alreadyIn)
		{
			if([variable isEqualToString:@"Traces"] && [type isEqualToString:DataTypeAnotoTraces])
			{
				AnotoNotesData *data = [[AnotoNotesData alloc] init];
				[dataSets addObject:data];
				[data setSource:self];
				[data setVariableName:variable];
				[newDataSets addObject:data];
				[data release];
			}
			else if([variable isEqualToString:@"Annotations"] && [type isEqualToString:DataTypeAnnotation])
			{
				AnnotationSet *data = [[AnnotationSet alloc] init];
				[dataSets addObject:data];
				[data setSource:self];
				
				for(Annotation* annotation in [self annotations])
				{
					[data addAnnotation:annotation];
				}
				
				[data setVariableName:variable];
				[newDataSets addObject:data];
				[data release];
			}
			else
			{
				[newDataSets addObject:[NSNull null]];
			}
		}
	}
	
	return newDataSets;
}

-(void)setRange:(QTTimeRange)newRange
{
	QTTime previousDiff = range.time;
	QTTime diff = newRange.time;
	
	//[super setRange:newRange];
	range = newRange;
	
	for(Annotation *annotation in annotations)
	{
		[annotation setStartTime:QTTimeIncrement(QTTimeDecrement([annotation startTime],previousDiff), diff)];
		if([annotation isDuration])
		{
			[annotation setEndTime:QTTimeIncrement(QTTimeDecrement([annotation endTime],previousDiff), diff)];
		}
		
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:DPDataSetRangeChangeNotification object:self];
	
	[[AppController currentDoc] saveAnnotations];
}

-(NSDictionary*)backgrounds
{	
	return [[backgrounds copy] autorelease];
}

-(NSDictionary*)backgroundOffsets
{	
	return [[backgroundOffsets copy] autorelease];
}

-(NSDictionary*)backgroundScaleCorrection
{	
	return [[backgroundScaleCorrection copy] autorelease];
}


-(void)setBackgroundFile:(NSString*)imageFile forPage:(NSString*)pageID
{
	[backgrounds setObject:imageFile forKey:pageID];
}

-(void)setBackgroundXoffset:(CGFloat)xOff andYoffset:(CGFloat)yOff forPage:(NSString*)pageID
{
	[backgroundOffsets setObject:[NSValue valueWithPoint:NSMakePoint(xOff, yOff)] forKey:pageID];
}

-(void)setBackgroundScaleCorrection:(CGFloat)sc forPage:(NSString*)pageID
{
	[backgroundScaleCorrection setObject:[NSNumber numberWithFloat:sc] forKey:pageID];
}

- (NSArray*)traces
{
	[self dataArray];
	return traces;
}

- (NSArray*)audio
{
	if(!audio)
	{
		
	}
	return audio;
}

- (NSArray*)annotations
{
	if([annotations count] == 0)
	{
		NSTimeInterval previousTime = 0;
		NSTimeInterval timeInterval = 0;
		NSMutableArray *currentTraces = [NSMutableArray array];
		
		for(AnotoTrace *trace in traces)
		{
			QTGetTimeInterval(QTTimeRangeEnd([trace range]), &timeInterval);
			if(((timeInterval - previousTime) > 5))
			{
				if([currentTraces count] > 0)
				{
					[self addAnnotation:[self createAnnotationFromTraces:currentTraces]];
					
					[currentTraces removeAllObjects];
				}
			}
			[currentTraces addObject:trace];
			previousTime = timeInterval;
		}
	}
	return annotations;
}

- (NSSet*)pages
{
	return [[pages copy] autorelease];
}

-(void)addAnnotation:(Annotation*)annotation
{
	if(!annotations)
	{
		annotations = [[NSMutableArray alloc] init];
	}
	[annotation setSource:[self uuid]];
	[annotations addObject:annotation];
}

- (NSArray*)tracesFromFile:(NSString *)file {
    NSError *err=nil;
    NSURL *furl = [NSURL fileURLWithPath:file];
    if (!furl) {
        NSLog(@"Can't create an URL from file %@.", file);
        return nil;
    }
	
    NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
												  options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
													error:&err];
    if (xmlDoc == nil) {
        xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
													  options:NSXMLDocumentTidyXML
														error:&err];
    }
    if ((xmlDoc == nil) || err)  {
        if (err) {
			//            [self handleError:err];
			NSLog(@"Error: %@",[err localizedDescription]);
        }
        return nil;
    }
	
	
	NSXMLNode *aNode = [xmlDoc rootElement];
	if([[aNode name] caseInsensitiveCompare:@"ipaper"] != NSOrderedSame)
	{
		NSLog(@"Tried to open a document that wasn't an ipaper xml document");
		return nil;
	}
	
	aNode = [aNode nextNode];
	
	NSString* page = [[(NSXMLElement*)aNode attributeForName:@"page"] stringValue];
	
	if(!page && ([pages count] > 0))
	{
		page = [pages anyObject];
	}
	
	NSXMLNode* copy = [(NSXMLElement*)aNode attributeForName:@"copy"];
	if(copy)
	{
		page = [page stringByAppendingFormat:@"_%@",[copy stringValue]];
	}
	
	[pages addObject:page];

	NSMutableArray *allTraces = [NSMutableArray array];
	NSMutableArray *currentTraces = [NSMutableArray array];
		
	NSTimeInterval previousTime = 0;
	NSTimeInterval timeInterval = 0;
	
	while ((aNode = [aNode nextNode])) {
		if (([aNode kind] == NSXMLElementKind) && ([[aNode name] caseInsensitiveCompare:@"trace"] == NSOrderedSame)) {
			NSXMLElement *element = (NSXMLElement*)aNode;
			
			AnotoTrace *trace = [[AnotoTrace alloc] init];
			//[trace setPage:[[[element attributeForName:@"page"] stringValue] longLongValue]];
			[trace setPage:page];
			
			for(NSXMLElement* point in [element elementsForName:@"point"])
			{
				TimeCodedPenPoint *penPoint = [[TimeCodedPenPoint alloc] init];
				
				NSXMLElement* x = [[point elementsForName:@"x"] objectAtIndex:0];
				NSXMLElement* y = [[point elementsForName:@"y"] objectAtIndex:0];
				NSXMLElement* timestamp = [[point elementsForName:@"timestamp"] objectAtIndex:0];
				NSXMLElement* force = [[point elementsForName:@"force"] objectAtIndex:0];
				
				[penPoint setX:[[x stringValue] floatValue]];
				[penPoint setY:[[y stringValue] floatValue]];
				[penPoint setForce:[[force stringValue] floatValue]];
				
				timeInterval = ((double)[[timestamp stringValue] longLongValue])/1000.0;
				
				if(startTime == 0)
				{
					startTime = timeInterval;
				}
				
				[penPoint setTime:QTMakeTimeWithTimeInterval(timeInterval - startTime)];
				
				[trace addPoint:penPoint];
				
				if([delegate dataSourceCancelLoad])
				{
					[trace release];
					return nil;
				}
				
			}
			
			//NSLog(@"Add trace: %@",[trace name]);
			
			//NSLog(@"Trace MinY: %f, MaxY: %f",[trace minY],[trace maxY]);
			
			[allTraces addObject:trace];
			range = QTUnionTimeRange(range, [trace range]);
			
			// If it's a new note
			//if([trace maxY] > (annotationMinY + 5))
			if(createAnnotations && ((timeInterval - previousTime) > 5))
			{
								
				if([currentTraces count] > 0)
				{
					[self addAnnotation:[self createAnnotationFromTraces:currentTraces]];
					
					[currentTraces removeAllObjects];
				}
				
			}

			[currentTraces addObject:trace];
			previousTime = timeInterval;
			[trace release];

		}
	}
	
	if(createAnnotations && ([currentTraces count] > 0))
	{
		[self addAnnotation:[self createAnnotationFromTraces:currentTraces]];
		
		[currentTraces removeAllObjects];
	}
	
	NSLog(@"Number of annotations: %i",[annotations count]);
	
	return allTraces;
}

-(Annotation*)createAnnotationFromTraces:(NSArray*)currentTraces
{
	return [self createAnnotationFromTraces:currentTraces saveImage:YES];
}

-(Annotation*)createAnnotationFromTraces:(NSArray*)currentTraces saveImage:(BOOL)saveImage
{
	float scaleFactor = 3.0;
	
	AnotoTrace *firstTrace = [currentTraces objectAtIndex:0];
	
	Annotation *currentAnnotation = [[Annotation alloc] initWithQTTime:QTTimeIncrement(range.time,[firstTrace startTime])];
	[currentAnnotation setIsDuration:YES];
	[currentAnnotation setEndTime:QTTimeIncrement(range.time,[(AnotoTrace*)[currentTraces lastObject] endTime])];
	
	CGFloat minX = [firstTrace minX];
	CGFloat minY = [firstTrace minY];
	CGFloat maxX = [firstTrace maxX];
	CGFloat maxY = [firstTrace maxY];
	
	
	for(AnotoTrace* testTrace in currentTraces)
	{
		minX = fmin(minX, [testTrace minX]);
		minY = fmin(minY, [testTrace minY]);
		maxX = fmax(maxX, [testTrace maxX]);
		maxY = fmax(maxY, [testTrace maxY]);
	}
	
	
	CGFloat width = ceil(((maxX - minX) * scaleFactor) + 10);
	CGFloat height = ceil(((maxY - minY) * scaleFactor) + 10);
	minX = (minX * scaleFactor) - 5;
	minY = (minY * scaleFactor) - 5;
	
	//NSLog(@"Make image: %f x %f",width,height);
	
	NSImage* anImage = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
	
	[anImage lockFocus];
	
	[[NSColor whiteColor] setFill];
	NSRectFill(NSMakeRect(0,0,width,height));
	
	[[NSColor darkGrayColor] setStroke];
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	
	for(AnotoTrace *imageTrace in currentTraces)
	{
		TimeCodedPenPoint* start = [[imageTrace dataPoints] objectAtIndex:0];
		[path moveToPoint:NSMakePoint(([start x] * scaleFactor) - minX, ([start y] * scaleFactor) - minY)];
		for(TimeCodedPenPoint* point in [imageTrace dataPoints])
		{
			[path lineToPoint:NSMakePoint(([point x] * scaleFactor) - minX, ([point y] * scaleFactor) - minY)];
		}
	}
	
	
	NSAffineTransform *t = [NSAffineTransform transform];
	NSAffineTransformStruct at;
	at.m11 = 1.0;
	at.m12 = 0.0;
	at.tX = 0;
	at.m21 = 0.0;
	at.m22 = -1.0;
	at.tY = height;
	[t setTransformStruct:at];
	[path transformUsingAffineTransform:t];
	
	[path stroke];
	
	NSSize size = [anImage size];
	NSBitmapImageRep* rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:
							 NSMakeRect(0,0,size.width,size.height)];
	
	[anImage unlockFocus];
	
	[currentAnnotation setFrameRepresentation:anImage];
	
	if(saveImage)
	{
		NSString *dataSetID = [[[[self dataFile] lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
		NSString *imageName = [NSString stringWithFormat:@"anotoNote-%@-%qi.png",dataSetID,[firstTrace startTime].timeValue];
		NSString *imageFile = [[[AppController currentDoc] annotationsImageDirectory] stringByAppendingPathComponent:imageName];
		NSDictionary *imageProps = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithFloat:0.7],NSImageCompressionFactor,
									[NSNumber numberWithBool:NO],NSImageProgressive,
									nil];
		NSData *imageData = [rep representationUsingType:NSPNGFileType properties:imageProps];
		[imageData writeToFile:imageFile atomically:NO];
		
		[currentAnnotation setImage:[NSURL URLWithString:[NSString stringWithFormat:@"images/%@",imageName]]];	
	}
	[currentAnnotation setKeyframeImage:NO];
	
	return [currentAnnotation autorelease];
}

#pragma mark File Coding


- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		self.predefinedTimeCode = YES;
		self.timeCoded = YES;	
		traces = [[NSMutableArray alloc] init];
		annotations = [[NSMutableArray alloc] init];
		backgrounds = [[NSMutableDictionary alloc] init];
		backgroundOffsets = [[NSMutableDictionary alloc] init];
		backgroundScaleCorrection = [[NSMutableDictionary alloc] init];
		pages = [[NSMutableSet alloc] init];
		
		metadataDirectory = [@"chronoviz" retain];
		serverFile = [[metadataDirectory stringByAppendingPathComponent:@"iserver.xml"] retain];
		postscriptFile = nil;
	}
    return self;
}

@end
