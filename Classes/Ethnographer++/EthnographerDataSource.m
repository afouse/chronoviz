//
//  EthnographerDataSource.m
//  ChronoViz
//
//  Created by Adam Fouse on 1/22/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerDataSource.h"
#import "AnnotationDocument.h"
#import "Annotation.h"
#import "AnnotationCategory.h"
#import "NSStringFileManagement.h"
#import "AnotoNotesData.h"
#import "AnotoTrace.h"
#import "TimeCodedDataPoint.h"
#import "TimeCodedPenPoint.h"
#import "AnnotationSet.h"
#import "DPBluetoothPen.h"
#import "NSStringEthnographer.h"
#import "EthnographerPlugin.h"
#import "EthnographerProject.h"
#import "EthnographerTemplate.h"
#import "NSColorHexadecimalValue.h"
#import "NSColorUniqueColors.h"
#import "DPConstants.h"

int ethnographerxmldatecompare( id obj1, id obj2, void *context ) {
	
	NSDateFormatter *formatter = (NSDateFormatter*)context;
	
	NSString* start1 = [[(NSXMLElement*)obj1 attributeForName:@"starttime"] stringValue];
	NSString* start2 = [[(NSXMLElement*)obj2 attributeForName:@"starttime"] stringValue];
	
	NSDate* date1 = [formatter dateFromString:start1];
	NSDate* date2 = [formatter dateFromString:start2];
	
	return [date1 compare:date2];
}

@interface EthnographerDataSource (Internal)

- (void)addAnnotation:(Annotation*)annotation forSession:(AnotoNotesData*)session;

- (void)createAllAnnotations;
- (NSArray*)createAnnotationsFromSession:(AnotoNotesData*)session;

- (NSXMLDocument*)sessionXMLDoc;
- (void)processSessionXML;
- (void)saveSessionXML;

@end;

@implementation EthnographerDataSource

@synthesize mappingsImported,backgroundTemplate,currentAnnotations;

#pragma mark DataSource Setup Methods

+(NSString*)dataTypeName
{
	return @"Digital Notes Data";
}

+(BOOL)validateFileName:(NSString*)fileName
{
	return ([[fileName pathExtension] isEqualToString:@"xml"] && ([[fileName lastPathComponent] rangeOfString:@"session"].location != NSNotFound));
}

-(NSString*)defaultDataType:(NSString*)variableName
{
	if(([[[self dataArray] objectAtIndex:0] indexOfObject:variableName] % 2) == 0)
	{
		return DataTypeAnotoTraces;
	}
	else
	{
		return DataTypeAnnotation;
	}
}

-(NSArray*)defaultVariablesToImport
{
	return [[self dataArray] objectAtIndex:0];
}

#pragma mark Initialization

-(id)initWithPath:(NSString *)sessionFile
{	
	
	BOOL isFile = [[NSFileManager defaultManager] fileExistsAtPath:sessionFile];
	
	if(!isFile)
	{
		[self release];
		return nil;
	}
	
	self = [super initWithPath:sessionFile];
	
	if (self != nil) {
        [self setName:[[sessionFile stringByDeletingLastPathComponent] lastPathComponent]];
		[self setDataFile:sessionFile];
		[self setPredefinedTimeCode:YES];
		[self setTimeCoded:YES];
		startTime = 0;
		currentSession = nil;
		currentAnnotations = nil;
		currentAnnotationCategory = nil;
		sessionXMLDoc = nil;
		currentSaveTimer = nil;
		
		sessions = [[NSMutableArray alloc] init];
        sessionAnnotations = [[NSMutableDictionary alloc] init];
		pages = [[NSMutableSet alloc] init];
        pageRotations = [[NSMutableDictionary alloc] init];
		anotoPages = [[NSMutableDictionary alloc] init];
		
		xmlDateFormatter = [[NSDateFormatter alloc] init];
		[xmlDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS zzz"];
		
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super initWithCoder:coder])
	{
		[self setPredefinedTimeCode:YES];
		[self setTimeCoded:YES];
		startTime = 0;
		currentSession = nil;
		currentAnnotations = nil;
		currentAnnotationCategory = nil;
		sessionXMLDoc = nil;
		currentNotesElement = nil;
		currentSaveTimer = nil;
		
		sessions = [[NSMutableArray alloc] init];
        sessionAnnotations = [[NSMutableDictionary alloc] init];
		
		for(TimeCodedData *data in [self dataSets])
		{
			if([data isKindOfClass:[AnotoNotesData class]])
			{
				[sessions addObject:data];
                [data addObserver:self
                       forKeyPath:@"color"
                          options:0
                          context:NULL];
				[data setSource:self];
			}
		}
		
		pages = [[NSMutableSet alloc] init];
		anotoPages = [[NSMutableDictionary alloc] init];
        
        NSDictionary *rotations = (NSDictionary*)[coder decodeObjectForKey:@"DPEthnographerPageRotations"];
        if(rotations)
        {
            pageRotations = [rotations mutableCopy];
        }
        else
        {
            pageRotations = [[NSMutableDictionary alloc] init];
        }
		
		xmlDateFormatter = [[NSDateFormatter alloc] init];
		[xmlDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS zzz"];
	}
    return self;
}




- (void)encodeWithCoder:(NSCoder *)coder
{
    NSArray *tempDataSets = [dataSets copy];
    NSArray *currentSets = [sessionAnnotations allValues];
    for(TimeCodedData *data in tempDataSets)
    {
        if([data isKindOfClass:[AnnotationSet class]] && ![currentSets containsObject:data])
        {
            if([[(AnnotationSet*)data annotations] count] == 0)
            {
                [self removeDataSet:data];
            }
        }
    }
    
	[super encodeWithCoder:coder];
	
    [coder encodeObject:pageRotations forKey:@"DPEthnographerPageRotations"];
    
	if(currentSaveTimer)
	{
		[currentSaveTimer fire];
	}
	else
	{
		[self updateSessionFile:nil];
	}
	
}

- (void) dealloc
{
	if(currentSaveTimer)
	{
		[currentSaveTimer fire];
	}
    
    for(AnotoNotesData *data in sessions)
    {
        [data removeObserver:self forKeyPath:@"color"];
    }
    
	[xmlDateFormatter release];
	[currentNotesElement release];
	[sessionXMLDoc release];
	[currentSession release];
	[currentTraces release];
	[currentTraceBuffer release];
	[currentAnnotations release];
	[currentAnnotationCategory release];
	[sessions release];
	[sessionAnnotations release];
	[pages release];
	[anotoPages release];
	[super dealloc];
}

-(BOOL)lockedDataType:(NSString*)variableName
{
	return YES;
}

-(void)load
{
	[self dataArray];
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
			if([type isEqualToString:DataTypeAnotoTraces])
			{
				for(AnotoNotesData *data  in sessions)
				{
					if([variable isEqualToString:[data variableName]])
					{
						[dataSets addObject:data];
						[newDataSets addObject:data];
					}
				}
				
			}
			else if([type isEqualToString:DataTypeAnnotation])
			{
				for(AnotoNotesData *session  in sessions)
				{
					NSString *sessionvariable = [variable substringToIndex:([variable length] - 12)];
					if([sessionvariable isEqualToString:[session variableName]])
					{
						AnnotationSet *data = [[AnnotationSet alloc] init];
						[dataSets addObject:data];
						[data setSource:self];
                        [data setName:sessionvariable];
                        [data setUseNameAsCategory:YES];
						
                        [sessionAnnotations setObject:data forKey:[session uuid]];
                        
						[self createAnnotationsFromSession:session];
						
						[data setVariableName:variable];
						[newDataSets addObject:data];
						[data release];
                        
                        
					}
				}
			}
			else
			{
				[newDataSets addObject:[NSNull null]];
			}
		}
	}
	
	return newDataSets;
}

-(void)createAllAnnotations
{
	for(AnotoNotesData *session in sessions)
	{
		[self createAnnotationsFromSession:session];
	}
}

-(NSArray*)createAnnotationsFromSession:(AnotoNotesData*)session
{
	NSTimeInterval previousTime = 0;
	NSTimeInterval timeInterval = 0;
	NSMutableArray *annotationTraces = [[NSMutableArray alloc] init];
	
	NSMutableArray *newAnnotations = [NSMutableArray array];
	
	for(AnotoTrace *trace in [session traces])
	{
		timeInterval = CMTimeGetSeconds(CMTimeRangeGetEnd([trace range]));
		if(((timeInterval - previousTime) > 5) || ([annotationTraces count] && ![[trace page] isEqualToString:[[annotationTraces lastObject] page]]))
		{
			if([annotationTraces count] > 0)
			{
				Annotation *annotation = [self createAnnotationFromTraces:annotationTraces];
				[self addAnnotation:annotation forSession:session];
				[newAnnotations addObject:annotation];
				[annotationTraces removeAllObjects];
			}
		}
		[annotationTraces addObject:trace];
		previousTime = timeInterval;
	}
	
	// Handle the last annotation
	if([annotationTraces count] > 0)
	{
        Annotation *annotation = [self createAnnotationFromTraces:annotationTraces];
        [self addAnnotation:annotation forSession:session];
        [newAnnotations addObject:annotation];
	}
	
	[annotationTraces release];
	
	return newAnnotations;
}

-(void)addAnnotation:(Annotation*)annotation
{
    //NSLog(@"Adding annotation to Ethnographer Data Set without session");
	if(currentSession)
	{
		[self addAnnotation:annotation forSession:currentSession];
	}
    else
    {
        [self addAnnotation:annotation forSession:nil];
    }
}

- (void)addAnnotation:(Annotation*)annotation forSession:(AnotoNotesData*)session
{
    [annotation setSource:[self uuid]];

    AnnotationSet *annotations = nil;
    if(!session)
    {
        annotations = [sessionAnnotations objectForKey:[NSNull null]];
    }
    else
    {
        annotations = [sessionAnnotations objectForKey:[session uuid]]; 
    }
    
    if(!annotations)
    {
        NSString *annotationsName = [[self name] stringByAppendingString:@" Annotations"];
        
        annotations = [[AnnotationSet alloc] init];
        [annotations setSource:self];
        [annotations setName:annotationsName];
        [dataSets addObject:annotations];
        
        if(!session)
        {
            [sessionAnnotations setObject:annotations forKey:[NSNull null]];
        }
        else
        {
            [sessionAnnotations setObject:annotations forKey:[session uuid]]; 
        }
        
        [annotations release];
    }
        
    [annotations addAnnotation:annotation];

}

-(Annotation*)createAnnotationFromTraces:(NSArray*)annotationTraces
{
	return [self createAnnotationFromTraces:annotationTraces saveImage:YES scale:1.0];
}

-(Annotation*)createAnnotationFromTraces:(NSArray*)annotationTraces saveImage:(BOOL)saveImage
{
    return [self createAnnotationFromTraces:annotationTraces saveImage:saveImage scale:1.0];
}

-(Annotation*)createAnnotationFromTraces:(NSArray*)annotationTraces saveImage:(BOOL)saveImage scale:(CGFloat)scale
{	
	AnotoTrace *firstTrace = [annotationTraces objectAtIndex:0];
	
	Annotation *currentAnnotation = [[Annotation alloc] initWithQTTime:CMTimeAdd(range.time,[firstTrace startTime])];
	[currentAnnotation setIsDuration:YES];
	[currentAnnotation setEndTime:CMTimeAdd(range.time,[(AnotoTrace*)[annotationTraces lastObject] endTime])];
    
    NSUInteger rotation = [backgroundTemplate rotationForPdfPage:[backgroundTemplate pdfPageForLivescribePage:[firstTrace page]]];
    
	NSImage *anImage = [self imageForTraces:annotationTraces withRotation:rotation andScale:scale];
		
	[currentAnnotation setFrameRepresentation:anImage];
	
	if(saveImage)
	{
        
        NSData *imageData = [anImage TIFFRepresentation];
        NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:imageData];
		NSString *dataSetID = [[[[self dataFile] lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
		NSString *imageName = [NSString stringWithFormat:@"anotoNote-%@-%qi.png",dataSetID,[firstTrace startTime].value];
		NSString *imageFile = [[[AnnotationDocument currentDocument] annotationsImageDirectory] stringByAppendingPathComponent:imageName];
		NSDictionary *imageProps = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithFloat:0.7],NSImageCompressionFactor,
									[NSNumber numberWithBool:NO],NSImageProgressive,
									nil];
		imageData = [rep representationUsingType:NSPNGFileType properties:imageProps];
		[imageData writeToFile:imageFile atomically:NO];
		
		[currentAnnotation setImage:[NSURL URLWithString:[NSString stringWithFormat:@"images/%@",imageName]]];	
	}
	[currentAnnotation setKeyframeImage:NO];
	
	return [currentAnnotation autorelease];
}

- (NSImage*)imageForTraces:(NSArray*)imageTraces
{
    return [self imageForTraces:imageTraces withRotation:0 andScale:1.0];
}

- (NSImage*)imageForTraces:(NSArray*)imageTraces withRotation:(NSUInteger)rotation andScale:(CGFloat)scale
{
    CGFloat scaleFactor = 3.0 * scale;
	
    if(rotation == 90)
    {
        rotation = 270;
    }
    else if (rotation == 270)
    {
        rotation = 90;
    }
    
	AnotoTrace *firstTrace = [imageTraces objectAtIndex:0];
	
	CGFloat minX = [firstTrace minX];
	CGFloat minY = [firstTrace minY];
	CGFloat maxX = [firstTrace maxX];
	CGFloat maxY = [firstTrace maxY];
	
	for(AnotoTrace* testTrace in imageTraces)
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
	
    NSImage* anImage = nil;
    if((rotation == 90) || (rotation == 270))
    {
        anImage = [[NSImage alloc] initWithSize:NSMakeSize(height, width)];
    }
    else
    {
        anImage = [[NSImage alloc] initWithSize:NSMakeSize(width, height)];
    }
	
	[anImage lockFocus];
	
    [[NSColor whiteColor] setFill];
    if((rotation == 90) || (rotation == 270))
    {

        NSRectFill(NSMakeRect(0,0,height,width));
    }
    else
    {
        NSRectFill(NSMakeRect(0,0,width,height));
    }

	
	[[NSColor darkGrayColor] setStroke];
	
	NSBezierPath *path = [NSBezierPath bezierPath];
	
	for(AnotoTrace *imageTrace in imageTraces)
	{
		TimeCodedPenPoint* start = [[imageTrace dataPoints] objectAtIndex:0];
		[path moveToPoint:NSMakePoint(([start x] * scaleFactor) - minX, ([start y] * scaleFactor) - minY)];
		for(TimeCodedPenPoint* point in [imageTrace dataPoints])
		{
			[path lineToPoint:NSMakePoint(([point x] * scaleFactor) - minX, ([point y] * scaleFactor) - minY)];
		}
	}
	
	
	NSAffineTransform *t = [NSAffineTransform transform];
    NSAffineTransform *flip = [NSAffineTransform transform];
	NSAffineTransformStruct at;
	at.m11 = 1.0;
	at.m12 = 0.0;
	at.tX = 0;
	at.m21 = 0.0;
	at.m22 = -1.0;
	at.tY = height;
	[flip setTransformStruct:at];
    
    if(rotation == 90)
    {
        [t translateXBy:height yBy:0];
    }
    else if (rotation == 180)
    {
        [t translateXBy:width yBy:height];
    }
    else if (rotation == 270)
    {
        [t translateXBy:0 yBy:width];
    }
    
    [t rotateByDegrees:rotation];
    
	[path transformUsingAffineTransform:flip];
    [path transformUsingAffineTransform:t];
    
	
	[path stroke];
	
	[anImage unlockFocus];
	
	return [anImage autorelease];

}


- (NSImage*)imageForPage:(NSString*)pageNumber
{
    NSMutableArray *pageTraces = [NSMutableArray array];
    
    for(AnotoNotesData *session in sessions)
    {
        for(AnotoTrace *trace in [session traces])
        {
            if([[trace page] isEqualToString:pageNumber])
            {
                [pageTraces addObject:trace];
            }
        }
    }
    
    if([pageTraces count])
    {
        return [self imageForTraces:pageTraces];
    }
    else
    {
        return nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqual:@"color"]) {
        
        if(currentSaveTimer)
        {
            [currentSaveTimer invalidate];
        }
        currentSaveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                            target:self
                                                          selector:@selector(updateSessionFile:)
                                                          userInfo:nil
                                                           repeats:NO];
		
	}

}

#pragma mark Accessors

-(NSArray*)sessions
{
	return [[sessions copy] autorelease];
}

- (NSSet*)pages
{
	return [[pages copy] autorelease];
}

- (NSDictionary*)pageRotations
{
    return pageRotations;
}

- (NSArray*)anotoPages
{
	return [anotoPages allKeys];
}

- (NSString*)livescribePageForAnotoPage:(NSString*)anotoPage
{
	return [anotoPages objectForKey:anotoPage];
}

- (NSUInteger)rotationForPage:(NSString*)pageNumber
{
    NSNumber *rotation = [pageRotations objectForKey:pageNumber];
    if(rotation)
    {
        return [rotation unsignedIntegerValue];
    }
    else if(backgroundTemplate)
    {
        return [backgroundTemplate rotationForPdfPage:[backgroundTemplate pdfPageForLivescribePage:pageNumber]];
    }
    else
    {
        return 0;
    }
}

- (void)setRotation:(NSUInteger)rotation forPage:(NSString*)pageNumber
{
    if((rotation == 0)
       || (rotation == 90)
       || (rotation == 180)
       || (rotation == 270))
    {
        if(backgroundTemplate)
        {
            [backgroundTemplate setRotation:rotation forPdfPage:[backgroundTemplate pdfPageForLivescribePage:pageNumber]];
        }
        else
        {
            [pageRotations setObject:[NSNumber numberWithUnsignedInteger:rotation] forKey:pageNumber];
        }
    }
}

//- (NSArray*)annotations
//{
//	return annotations;
//}

-(AnotoNotesData*)currentSession
{
	if(!currentSession)
	{
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		//[dateFormatter setDateStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateFormat:@"M/dd/yy HH:mm:ss"];
		NSString *sessionName = [NSString stringWithFormat:@"Annotation Session %@",[dateFormatter stringFromDate:[NSDate date]]];
		
		currentSession = [[AnotoNotesData alloc] init];
		[currentSession setSource:self];
		[currentSession setVariableName:sessionName];
		[currentSession setName:sessionName];
		[currentSession setColor:[NSColor basicColorConsideringArrayOfObjects:sessions]];
		[sessions addObject:currentSession];
        [currentSession addObserver:self
                         forKeyPath:@"color"
                            options:0
                            context:NULL];
		[dataSets addObject:currentSession];
		
		currentTraces = [[NSMutableArray alloc] init];
		[currentSession setTraces:currentTraces];
		
		currentTraceBuffer = [[NSMutableArray alloc] init];
		
		currentAnnotations = [[AnnotationSet alloc] init];
		[dataSets addObject:currentAnnotations];
		[currentAnnotations setSource:self];
		[currentAnnotations setVariableName:sessionName];
		[currentAnnotations setName:sessionName];
		[dataSets addObject:currentAnnotations];
		[sessionAnnotations setObject:currentAnnotations forKey:[currentSession uuid]];
		
		currentAnnotationCategory = [[[AnnotationDocument currentDocument] createCategoryWithName:sessionName] retain];
		
	}
	return currentSession;
}

- (AnotoNotesData*)newSession
{
    if(currentSaveTimer)
	{
		[currentSaveTimer fire];
	}
	else
	{
		[self updateSessionFile:nil];
	}
    
    [currentNotesElement release];
	[currentSession release];
	[currentTraces release];
	[currentTraceBuffer release];
	[currentAnnotations release];
	[currentAnnotationCategory release];
    currentSession = nil;
    currentAnnotations = nil;
    currentAnnotationCategory = nil;
    currentNotesElement = nil;
    currentSaveTimer = nil;
    currentTraceBuffer = nil;
    
    return [self currentSession];
    
}

#pragma mark Notes Files

- (NSArray*)addFileToCurrentSession:(NSString*)file atTimeRange:(CMTimeRange)timeRange onPage:(NSString*)setPage;
{	
	[self currentSession];
	
    
	// If this should be combined with the existing annotation
	Annotation *currentAnnotation = [[currentAnnotations annotations] lastObject];
	NSTimeInterval timeRangeStart;
	timeRangeStart = CMTimeGetSeconds(timeRange.time);
	if(currentAnnotation)
	{
        NSTimeInterval annotationTime;
        annotationTime = CMTimeGetSeconds([currentAnnotation startTime]);
		if(fabs(annotationTime - timeRangeStart) < .01)
		{
			[currentAnnotations removeAnnotation:currentAnnotation];
			[[AnnotationDocument currentDocument] removeAnnotation:currentAnnotation];
			//timeRange.time = [[currentTraceBuffer lastObject] endTime];
		}
		else
		{
            // Save final image and record the image file with the annotation
            Annotation *tempAnnotation = [self createAnnotationFromTraces:currentTraceBuffer saveImage:YES];
            [currentAnnotation setImage:[tempAnnotation image]];
            
			[currentTraceBuffer removeAllObjects];
		}
	}
	
	NSArray *newTraces = [self tracesFromFile:file overTimeRange:timeRange onPage:setPage];
	[currentTraceBuffer addObjectsFromArray:newTraces];
	Annotation *ann = [self createAnnotationFromTraces:currentTraceBuffer saveImage:NO];
	[currentAnnotationCategory setColor:[currentSession color]];
	[ann addCategory:currentAnnotationCategory];
	//Annotation *ann = [self createAnnotationFromTraces:newTraces];
	if(CMTimeCompare(kCMTimeZero,timeRange.duration) == NSOrderedSame)
	{
		[ann setIsDuration:NO];
	}
	[self addAnnotation:ann forSession:currentSession];
	[[AnnotationDocument currentDocument] addAnnotation:ann];
	[currentTraces addObjectsFromArray:newTraces];
	
	if(currentSaveTimer)
	{
		[currentSaveTimer invalidate];
	}
	currentSaveTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
														target:self
													  selector:@selector(updateSessionFile:)
													  userInfo:nil
													   repeats:NO];
    return newTraces;
}

- (NSArray*)tracesFromFile:(NSString *)file
{
	return [self tracesFromFile:file overTimeRange:QTMakeTimeRange(QTIndefiniteTime, QTIndefiniteTime) onPage:nil];
}

- (NSArray*)tracesFromFile:(NSString *)file overTimeRange:(CMTimeRange)timeRange onPage:(NSString*)setPage;
{
    
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
	
	NSString* page = nil;
	
	if(setPage)
	{
		page = setPage;
	}
	else
	{
		page = [[(NSXMLElement*)aNode attributeForName:@"page"] stringValue];
		
		if([page rangeOfString:@"."].location != NSNotFound)
		{
			page = [page livescribePageNumberString];
		}
		
		if(!page && ([pages count] > 0))
		{
			page = [pages anyObject];
		}
	}	
	
//	NSXMLNode* copy = [(NSXMLElement*)aNode attributeForName:@"copy"];
//	if(copy && ([[copy stringValue] length] > 0))
//	{
//		page = [page stringByAppendingFormat:@"_%@",[copy stringValue]];
//	}
	
	[pages addObject:page];
	
	NSMutableArray *allTraces = [NSMutableArray array];
	
	NSTimeInterval timeInterval = 0;
	
	NSTimeInterval tracesStartTime = 0;
	NSTimeInterval tracesTimeDiff = 0;
	tracesStartTime = CMTimeGetSeconds(timeRange.time);
	
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
				
				if(QTTimeIsIndefinite(timeRange.time))
				{
					if(startTime == 0)
					{
						startTime = timeInterval;
					}
					
					[penPoint setTime:CMTimeMake(timeInterval - startTime, 1000000)];     // TODO: Check if the timescale is correct.
				}
				else if(CMTimeCompare(kCMTimeZero, timeRange.duration) == NSOrderedSame)
				{
					if(tracesTimeDiff == 0)
					{
						tracesTimeDiff = timeInterval - tracesStartTime;
					}
                    
                    
                    
					//[penPoint setTime:CMTimeMake(timeInterval - tracesTimeDiff, 1000000)]; // TODO: Check if the timescale is correct.
                    
                    // Shift time so that it will be correct with adjusted with the range
					[penPoint setTime:CMTimeSubtract(timeRange.time, self.range.time)];
				}
				else
				{
					// Do some fancy interpolation
				}
				
				[trace addPoint:penPoint];
				
				if([delegate dataSourceCancelLoad])
				{
					[trace release];
					return nil;
				}
				
			}
			
            if([[trace dataPoints] count] == 0) {
                NSLog(@"Zero points");
            }
            
            
			//NSLog(@"Add trace: %@",[trace name]);
			
			//NSLog(@"Trace MinY: %f, MaxY: %f",[trace minY],[trace maxY]);
			
			[allTraces addObject:trace];
            
            if(CMTimeCompare(kCMTimeZero, timeRange.duration) != NSOrderedSame)
            {
                range = QTUnionTimeRange(range, [trace range]);
			}
            
			[trace release];
			
		}
	}
	
	
	return allTraces;
}




-(NSArray*)dataArray
{
	
	if(!dataArray)
	{
		
		CMTimeRange rangeTemp = range;
		
		[delegate dataSourceLoadStart];
		[delegate dataSourceLoadStatus:0];
		 
		if(![dataFile fileExists])
		{
			NSString *newFile = [dataFile stringByAskingForReplacement];
			[dataFile release];
			dataFile = [newFile retain];
			if(![dataFile fileExists])
			{
				[delegate dataSourceCancelLoad];
				return [NSArray array];
			}
		}
		 
			
		[self processSessionXML];
		
		NSMutableArray *headers = [NSMutableArray array];
		for(AnotoNotesData *session in sessions)
		{
			[headers addObject:[session variableName]];
			[headers addObject:[[session variableName] stringByAppendingString:@" Annotations"]];
		}
		
		NSMutableArray *data = [NSMutableArray array];
		for(AnotoNotesData *session in sessions)
		{
			[data addObject:[NSNumber numberWithInt:[[session traces] count]]];
			[data addObject:[NSNumber numberWithInt:0]];
		}
		
		[self setDataArray:[NSArray arrayWithObjects:headers,data,nil]];
		
		[delegate dataSourceLoadFinished];
		
		if(rangeTemp.duration.value != 0)
		{
			range = rangeTemp;
		}
	}
	return dataArray;
}

- (NSXMLDocument*)sessionXMLDoc
{
	if(!sessionXMLDoc)
	{
		NSError *err = nil;
		NSString *sessionFile = [self dataFile];
		sessionXMLDoc = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:sessionFile]
																			options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
																			  error:&err];
		
		if ((sessionXMLDoc == nil) || err)  {
			if (err) {
				NSLog(@"Error: %@",[err localizedDescription]);
			}
			return nil;
		}
	}
	return sessionXMLDoc;
}

- (void)reloadSessionXML
{
    [sessionXMLDoc release];
    sessionXMLDoc = nil;
    [self processSessionXML];
}

// Returns image files, and adds any background mappings;
- (void)processSessionXML
{
	
	NSError *err = nil;
	
	NSString *sessionFile = [self dataFile];
	NSString *sessionDirectory = [sessionFile stringByDeletingLastPathComponent];
	
	NSXMLDocument *currentXmlDoc = [self sessionXMLDoc];

	if(!currentXmlDoc)
	{
		return;
	}
	
	NSXMLElement *session = [currentXmlDoc rootElement];
	if([[session name] caseInsensitiveCompare:@"penSession"] != NSOrderedSame)
	{
		NSLog(@"Expected root element of pen session file to be 'penSession'.");
		return;
	}
	
	NSString *project = [[session attributeForName:@"project"] stringValue];
	
	EthnographerProject *currentProject = nil;
	
	BOOL docProject = [[EthnographerPlugin defaultPlugin] hasCurrentProject];
	
	if(project && ([project length] > 0))
	{
		if(!docProject)
		{
			currentProject = [[EthnographerPlugin defaultPlugin] projectForName:project];
			[[EthnographerPlugin defaultPlugin] setCurrentProject:currentProject];
		}
		else if(![project isEqualToString:[[[EthnographerPlugin defaultPlugin] currentProject] projectName]])
		{
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:[NSString stringWithFormat:@"The note file %@ is associated with a different project and can't be loaded.",[sessionFile lastPathComponent]]];
			[alert runModal];
			[alert release];
			return;
		}
		else
		{
			currentProject = [[EthnographerPlugin defaultPlugin] currentProject];
		}
		
	}
	else
	{
		currentProject = [[EthnographerPlugin defaultPlugin] currentProject];
		if(!currentProject)
		{
			return;
		}
		[session addAttribute:[NSXMLNode attributeWithName:@"project" stringValue:[currentProject projectName]]];
		[self saveSessionXML];
	}
	
	NSArray *totalNoteFiles = [session nodesForXPath:@".//notes/penNote" error:&err];
	
	NSArray *notesets = [session elementsForName:@"notes"];
	
	int count = 0;
	
	for(NSXMLElement *noteset in notesets)
	{
		NSString *notesetName = [[noteset attributeForName:@"name"] stringValue];
		if(!notesetName || ([notesetName length] == 0))
		{
			notesetName = @"Traces";
		}
		
		NSColor *notesetColor = [NSColor colorFromHexRGB:[[noteset attributeForName:@"color"] stringValue]];
		
		NSArray *noteElements = [noteset elementsForName:@"penNote"];
		NSMutableArray *traces = [NSMutableArray array];
		noteElements = [noteElements sortedArrayUsingFunction:ethnographerxmldatecompare context:xmlDateFormatter];
		
		if([noteElements count] > 0)
		{
			rtcAdjustment = [[[(NSXMLElement*)[noteElements objectAtIndex:0] attributeForName:@"rtcAdjustment"] stringValue] longLongValue];	
		}
		else
		{
			rtcAdjustment = 0;
		}
		
		for(NSXMLElement *noteFile in noteElements)
		{	
			NSString *noteFilePath = [sessionDirectory stringByAppendingPathComponent:[noteFile stringValue]];
			//NSLog(@"Note File: %@",[noteFile stringValue]);
			[traces addObjectsFromArray:[self tracesFromFile:noteFilePath]];
			if([delegate dataSourceCancelLoad])
			{
				return;
			}
			count++;
			[delegate dataSourceLoadStatus:(count/[totalNoteFiles count])];
		}
		
		BOOL existing = NO;
		for(AnotoNotesData *session in sessions)
		{
			if([[session variableName] isEqualToString:notesetName])
			{
				[session setTraces:traces];
				if(![session variableName])
				{
					[session setVariableName:notesetName];
					[session setColor:notesetColor];
				}
				existing = YES;
			}
		}
		
		if(!existing)
		{
			AnotoNotesData *data = [[AnotoNotesData alloc] init];
			[sessions addObject:data];
			[data setTraces:traces];
			[data setSource:self];
			[data setVariableName:notesetName];
			[data setColor:notesetColor];
            [data addObserver:self
                   forKeyPath:@"color"
                      options:0
                      context:NULL];
			[data release];
		}

	}
	
	[self updateAnotoMappings];
	
	self.backgroundTemplate = [currentProject templateForPage:[pages anyObject]];
}


- (void)updateAnotoMappings
{
	NSXMLDocument *currentXmlDoc = [self sessionXMLDoc];
	NSError *err = nil;
	
	if(!currentXmlDoc)
	{
		return;
	}
	
	NSXMLElement *session = [currentXmlDoc rootElement];
	if([[session name] caseInsensitiveCompare:@"penSession"] != NSOrderedSame)
	{
		NSLog(@"Expected root element of pen session file to be 'penSession'.");
		return;
	}
	
	NSArray *anotoMappingElements = [session nodesForXPath:@".//anotoMappings/anotoMapping" error:&err];
	
	[anotoPages removeAllObjects];
	for(NSXMLElement *mapping in anotoMappingElements)
	{
		NSString *anotoPage = [[mapping attributeForName:@"anotoPage"] stringValue];
		NSString *livescribePage = [[mapping attributeForName:@"livescribePage"] stringValue];
		if([livescribePage rangeOfString:@"."].location != NSNotFound)
		{
			livescribePage = [livescribePage livescribePageNumberString];
		}
		
		[anotoPages setObject:livescribePage forKey:anotoPage];
		
		[pages addObject:livescribePage];
	}
	
	[[EthnographerPlugin defaultPlugin] registerDataSource:self];
}

- (void)updateSessionFile:(id)timer;
{	
	BOOL timerFired = NO;
	if(timer && (timer == currentSaveTimer))
	{
        timerFired = YES;
		currentSaveTimer = nil;
	}
    
	if(!currentSession && !timerFired)
	{
		return;
	}
	
    if([currentTraceBuffer count] > 0)
    {
        // Save current image to disk
        Annotation *currentAnnotation = [[currentAnnotations annotations] lastObject];
        Annotation *tempAnnotation = [self createAnnotationFromTraces:currentTraceBuffer saveImage:YES];
        [currentAnnotation setImage:[tempAnnotation image]];
    }
    
	NSXMLDocument *sessionXML = [self sessionXMLDoc];
	NSError *err = nil;
	
    NSXMLElement *session = [sessionXML rootElement];
	if([[session name] caseInsensitiveCompare:@"penSession"] != NSOrderedSame)
	{
		NSLog(@"Expected root element of pen session file to be 'penSession'.");
		return;
	}
	
	NSXMLNode *modified = [session attributeForName:@"modified"];
    if(modified)
    {
        [modified setStringValue:@"true"];
    }
    else
    {
        [session addAttribute:[NSXMLNode attributeWithName:@"modified" stringValue:@"true"]];
    }
    
	if(!currentNotesElement && currentSession)
	{
		NSXMLElement *session = [sessionXML rootElement];
		NSArray *notesElements = [session nodesForXPath:@".//notes" error:&err];
		NSUInteger newIndex = [(NSXMLElement*)[notesElements lastObject] index] + 1;
		
		currentNotesElement = [[NSXMLElement alloc] initWithName:@"notes"];
		
		[currentNotesElement addAttribute:[NSXMLNode attributeWithName:@"name" stringValue:[currentSession variableName]]];
		[currentNotesElement addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:@"interactive"]];
		[currentNotesElement addAttribute:[NSXMLNode attributeWithName:@"color" stringValue:[[currentSession color] hexadecimalValueOfAnNSColor]]];
		
		[session insertChild:currentNotesElement atIndex:newIndex];
	}
    
    NSArray *notesets = [session elementsForName:@"notes"];
	for(NSXMLElement *noteset in notesets)
	{
		NSString *notesetName = [[noteset attributeForName:@"name"] stringValue];
        for(AnotoNotesData *session in sessions)
		{
			if([[session variableName] isEqualToString:notesetName])
			{
                [noteset removeAttributeForName:@"color"];
                [noteset addAttribute:[NSXMLNode attributeWithName:@"color" stringValue:[[session color] hexadecimalValueOfAnNSColor]]];
			}
		}
        
    }
    
	
	NSMutableDictionary *tracePages = [NSMutableDictionary dictionary];
	
	for(AnotoTrace *trace in currentTraces)
	{
		NSMutableArray *page = [tracePages objectForKey:[trace page]];
		if(!page)
		{
			page = [NSMutableArray array];
			[tracePages setObject:page forKey:[trace page]];
		}
		[page addObject:trace];
	}
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	[formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
	
	// Delete existing note files for this session
	NSArray *existingNoteFileElements = [currentNotesElement nodesForXPath:@".//penNote/noteFile" error:&err];
	NSString *dataDir = [[self dataFile] stringByDeletingLastPathComponent];
	for(NSXMLElement *noteFile in existingNoteFileElements)
	{	
		[[NSFileManager defaultManager] removeItemAtPath:[dataDir stringByAppendingPathComponent:[noteFile stringValue]]
																						   error:&err];
		if(err)
		{
			NSLog(@"Error: %@",[err localizedDescription]);
		}
	}
	
	int pageNum = 1;
	err = nil;
	NSMutableArray *children = [NSMutableArray array];
	long long currentseconds = floor([NSDate timeIntervalSinceReferenceDate]);
	for(NSString *page in [tracePages allKeys])
	{
		NSString *filename = [NSString stringWithFormat:@"note_%@_%i.xml",[formatter stringFromDate:[NSDate date]],pageNum];
		
		NSXMLElement *penNote = [[NSXMLElement alloc] initWithName:@"penNote"];
		
		[penNote addAttribute:[NSXMLNode attributeWithName:@"noteID" stringValue:[NSString stringWithFormat:@"ChronoVizAnotoPen_%@_%qi",page,currentseconds]]];
		
		[penNote addAttribute:[NSXMLNode attributeWithName:@"penID" stringValue:@"ChronoVizPen"]];

		NSXMLNode *pageAttribute = [NSXMLNode attributeWithName:@"pageID"
													stringValue:[page livescribeAddress]];
		[penNote addAttribute:pageAttribute];

		[penNote addAttribute:[NSXMLNode attributeWithName:@"starttime"
											   stringValue:[xmlDateFormatter stringFromDate:[NSDate date]]]];
		
		[penNote addAttribute:[NSXMLNode attributeWithName:@"endtime"
											   stringValue:[xmlDateFormatter stringFromDate:[NSDate date]]]];
		
		[penNote addAttribute:[NSXMLNode attributeWithName:@"lastModified"
											   stringValue:[xmlDateFormatter stringFromDate:[NSDate date]]]];
		
		NSXMLElement *noteFile = [[NSXMLElement alloc] initWithName:@"noteFile"];
		[noteFile setStringValue:filename];
	
		[penNote addChild:noteFile];
		
		[children addObject:penNote];
		
		[penNote release];
		[noteFile release];
		pageNum++;
		
		[self saveTraces:[tracePages objectForKey:page] toFile:[dataDir stringByAppendingPathComponent:filename]];
	}
	[formatter release];
	
	
	[currentNotesElement setChildren:children];
		
	[self saveSessionXML];

}

- (void)saveSessionXML
{
	NSData *xmlData = [[self sessionXMLDoc] XMLDataWithOptions:NSXMLNodePrettyPrint];
	
    if (![xmlData writeToURL:[NSURL fileURLWithPath:[self dataFile]] atomically:YES]) {
        NSLog(@"Could not save session xml file");
    }
}

- (NSString*)timestampFromPoint:(TimeCodedDataPoint*)point
{
	long long start = (long long)(startTime * 1000.0);
	
	NSTimeInterval pointTimeInterval = 0;
	pointTimeInterval = CMTimeGetSeconds([point time]);
	long long pointTime = (long long)(pointTimeInterval * 1000.0);
	
	NSNumber *timestampTime = [NSNumber numberWithLongLong:(start + pointTime)];
	return [timestampTime stringValue];
}



- (BOOL)saveTraces:(NSArray*)tracesArray toFile:(NSString *)file {
	NSURL *furl = [NSURL fileURLWithPath:file];
	
	
    if (!furl) {
        NSLog(@"Can't create an URL from file %@.", file);
        return NO;
    }
	
	// ipaper element
	
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"ipaper"];
	NSXMLNode *rtcAttribute = [NSXMLNode attributeWithName:@"rtc"
												 stringValue:[[NSNumber numberWithLongLong:rtcAdjustment] stringValue]];
	[root addAttribute:rtcAttribute];
	NSString *startTimeString = [self timestampFromPoint:(TimeCodedDataPoint*)[[[tracesArray objectAtIndex:0] dataPoints] objectAtIndex:0]];
	NSXMLNode *startAttribute = [NSXMLNode attributeWithName:@"startTime"
											   stringValue:startTimeString];
	[root addAttribute:startAttribute];

	NSXMLDocument *xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];							 
		
	// note element
	
	NSXMLElement *note = (NSXMLElement *)[NSXMLNode elementWithName:@"note"];
	
	NSString *pageNumber  = [(AnotoTrace*)[tracesArray objectAtIndex:0] page];
	NSString *copyNumber = nil;
	NSRange copyDelimeter = [pageNumber rangeOfString:@"_"];
	if(copyDelimeter.location != NSNotFound)
	{
		copyNumber = [pageNumber substringFromIndex:(copyDelimeter.location + 1)];
		pageNumber = [copyNumber substringToIndex:copyDelimeter.location];
	}
	
	NSXMLNode *pageAttribute = [NSXMLNode attributeWithName:@"page"
												stringValue:pageNumber];
	[note addAttribute:pageAttribute];
	
	if(copyNumber)
	{
		NSXMLNode *copyAttribute = [NSXMLNode attributeWithName:@"copy"
													stringValue:copyNumber];
		[note addAttribute:copyAttribute];
	}
	
	[root addChild:note];
	
	// trace elements
	
	for(AnotoTrace *trace in tracesArray)
	{
		NSXMLElement *traceElement = (NSXMLElement *)[NSXMLNode elementWithName:@"trace"];
		
		for(TimeCodedPenPoint *point in [trace dataPoints])
		{
			NSXMLElement *pointElement = (NSXMLElement *)[NSXMLNode elementWithName:@"point"];
			
			NSXMLElement *xElement = (NSXMLElement *)[NSXMLNode elementWithName:@"x"];
			[xElement setStringValue:[[NSNumber numberWithFloat:point.x] stringValue]];
			[pointElement addChild:xElement];
			
			NSXMLElement *yElement = (NSXMLElement *)[NSXMLNode elementWithName:@"y"];
			[yElement setStringValue:[[NSNumber numberWithFloat:point.y] stringValue]];
			[pointElement addChild:yElement];
			
			NSXMLElement *timestampElement = (NSXMLElement *)[NSXMLNode elementWithName:@"timestamp"];
			[timestampElement setStringValue:[self timestampFromPoint:point]];
			[pointElement addChild:timestampElement];
			
			NSXMLElement *forceElement = (NSXMLElement *)[NSXMLNode elementWithName:@"force"];
			[forceElement setStringValue:@"0.0"];
			[pointElement addChild:forceElement];
			
			[traceElement addChild:pointElement];
		}
		
		[note addChild:traceElement];
	}
	
	NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
	
    if (![xmlData writeToURL:furl atomically:YES]) {
        NSLog(@"Could not save traces to file:%@",furl);
        return NO;
    }
    return YES;
}


@end
