//
//  AnnotationXMLParser.m
//  Annotation
//
//  Created by Adam Fouse on 6/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "AnnotationXMLParser.h"
#import "VideoProperties.h"
#import "AnnotationCategory.h"
#import "Annotation.h"
#import "AnnotationDocument.h"
#import "NSColorHexadecimalValue.h"

@interface AnnotationXMLParser (Internal)

- (void)createNewXMLDocument;
- (void)createXMLDocumentFromFile:(NSString *)file;
- (void)writeToFileInBackground:(NSString *)fileName;

@end

@implementation AnnotationXMLParser

@synthesize updateAnnotations;

-(id)init
{
	return [self initWithFile:nil forDocument:nil];
}

-(id)initForDocument:(AnnotationDocument*)doc
{
	return [self initWithFile:nil forDocument:doc];
}

-(id)initWithFile:(NSString *)file forDocument:(AnnotationDocument*)doc
{
	self = [super init];
	if (self != nil) {
		annotationDoc = doc;
		[self setup];
		if(file)
		{
			[self createXMLDocumentFromFile:file];
		}
		else
		{
			[self createNewXMLDocument];
		}
        xmlOperationsQueue = [[NSOperationQueue alloc] init];
        [xmlOperationsQueue setMaxConcurrentOperationCount:1];
		
	}
	return self;	
}

- (void) dealloc
{
    [xmlOperationsQueue waitUntilAllOperationsAreFinished];
    [xmlOperationsQueue release];
	[dateFormatter release];
	[altDateFormatter release];
	[xmlDoc release];
	[annotations release];
	[super dealloc];
}


- (void)setup
{
	[NSDateFormatter setDefaultFormatterBehavior:NSDateFormatterBehavior10_4];
	
	dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"MMMM d yyyy HH:mm:ss 'GMT'Z"];
	// [dateFormatter setDateFormat:@"MMMM d yyyy HH:mm:ss 'GMT'ZZZZ"];
	//	[dateFormatter setDateFormat:@"MMMM d yyyy HH:mm:ss.S 'GMT'ZZZZ"];
	[dateFormatter setLenient:YES];
	
	altDateFormatter = [[NSDateFormatter alloc] init];
	[altDateFormatter setDateFormat:@"EEE MMM d yyyy HH:mm:ss ZZZZ"];
	[altDateFormatter setLenient:YES];
	
	annotations = [[NSMutableArray alloc] init];
	
	[self setUpdateAnnotations:YES];
}

- (NSArray*)annotations
{
    return annotations; 
}

- (NSDateFormatter*)dateFormatter
{
	return dateFormatter;
}

- (NSXMLElement*)createAnnotationElement:(Annotation *)annotation
{
	NSXMLElement *eventElement = [NSXMLElement elementWithName:@"event"];
	
	[eventElement setStringValue:[annotation annotation]];
	
	for(AnnotationCategory* category in [annotation categories])
	{
		NSXMLElement *categoryElement = [NSXMLElement elementWithName:@"category"];
		if([category category])
		{
			NSXMLNode *nameAttribute = [NSXMLNode attributeWithName:@"name"
														stringValue:[[category category] name]];
			NSXMLNode *valueAttribute = [NSXMLNode attributeWithName:@"value"
														stringValue:[category name]];
			[categoryElement addAttribute:nameAttribute];
			[categoryElement addAttribute:valueAttribute];
		}
		else
		{
			NSXMLNode *nameAttribute = [NSXMLNode attributeWithName:@"name"
														stringValue:[category name]];
			[categoryElement addAttribute:nameAttribute];
		}
		[eventElement addChild:categoryElement];
	}
	
	NSNumber *startInterval = [NSNumber numberWithDouble:[annotation startTimeSeconds]];
	NSXMLNode *startIntervalAttribute = [NSXMLNode attributeWithName:@"startTimeInterval"
												 stringValue:[startInterval stringValue]];
	[eventElement addAttribute:startIntervalAttribute];
	
    
    NSDate *startDate = [[NSDate alloc] initWithTimeInterval:[annotation startTimeSeconds] sinceDate:[annotationDoc startDate]];
	NSXMLNode *startAttribute = [NSXMLNode attributeWithName:@"start"
												 stringValue:[dateFormatter stringFromDate:startDate]];
	[eventElement addAttribute:startAttribute];
    [startDate release];
	
	if([annotation isDuration])
	{
		NSNumber *endInterval = [NSNumber numberWithDouble:[annotation endTimeSeconds]];
		NSXMLNode *endIntervalAttribute = [NSXMLNode attributeWithName:@"endTimeInterval"
															 stringValue:[endInterval stringValue]];
		[eventElement addAttribute:endIntervalAttribute];
        
        NSDate *endDate = [[NSDate alloc] initWithTimeInterval:[annotation endTimeSeconds] sinceDate:[annotationDoc startDate]];
		NSXMLNode *endAttribute = [NSXMLNode attributeWithName:@"end"
												   stringValue:[dateFormatter stringFromDate:endDate]];
		[eventElement addAttribute:endAttribute];
        [endDate release];
        
		NSXMLNode *durationAttribute = [NSXMLNode attributeWithName:@"isDuration"
														stringValue:@"true"];
		[eventElement addAttribute:durationAttribute];
	}
	
	NSXMLNode *titleAttribute = [NSXMLNode attributeWithName:@"title"
												 stringValue:[annotation title]];
	[eventElement addAttribute:titleAttribute];
	
	// Creation and Modification Tracking
	if([annotation creationDate])
	{
		NSXMLNode *creationDateAttribute = [NSXMLNode attributeWithName:@"annotation-creationDate"
													 stringValue:[dateFormatter stringFromDate:[annotation creationDate]]];
		[eventElement addAttribute:creationDateAttribute];
	}
	if([annotation modificationDate])
	{
		NSXMLNode *modificationDateAttribute = [NSXMLNode attributeWithName:@"annotation-modificationDate"
															stringValue:[dateFormatter stringFromDate:[annotation modificationDate]]];
		[eventElement addAttribute:modificationDateAttribute];
	}
	if([annotation creationUser])
	{
		NSXMLNode *creationUserAttribute = [NSXMLNode attributeWithName:@"annotation-creationUser"
													 stringValue:[annotation creationUser]];
		[eventElement addAttribute:creationUserAttribute];
	}
	if([annotation modificationUser])
	{
		NSXMLNode *modificationUserAttribute = [NSXMLNode attributeWithName:@"annotation-modificationUser"
															stringValue:[annotation modificationUser]];
		[eventElement addAttribute:modificationUserAttribute];
	}
	
	if([annotation autoCreated])
	{
		NSXMLNode *autoCreatedAttribute = [NSXMLNode attributeWithName:@"annotation-autoCreated"
														  stringValue:@"true"];
		[eventElement addAttribute:autoCreatedAttribute];
		
	}	
	if([annotation isCategory])
	{
		NSXMLNode *isCategoryAttribute = [NSXMLNode attributeWithName:@"annotation-is-category"
														stringValue:@"true"];
		[eventElement addAttribute:isCategoryAttribute];
	}
	if([annotation category])
	{
		NSXMLNode *categoryAttribute = [NSXMLNode attributeWithName:@"annotation-category"
													 stringValue:[[annotation category] name]];
		[eventElement addAttribute:categoryAttribute];
	}
	if([[annotation keywords] count] > 0)
	{
		NSString *keywordString = [[annotation keywords] componentsJoinedByString:@","];
		
		NSXMLNode *categoryAttribute = [NSXMLNode attributeWithName:@"annotation-keywords"
														stringValue:keywordString];
		[eventElement addAttribute:categoryAttribute];
	}
	if([annotation color])
	{
		NSXMLNode *colorAttribute;
		if([annotation category])
		{
			colorAttribute = [NSXMLNode attributeWithName:@"color"
											  stringValue:[[[annotation category] color] hexadecimalValueOfAnNSColor]];
		}
		else
		{
			colorAttribute = [NSXMLNode attributeWithName:@"color"
											  stringValue:[annotation color]];
		}
		[eventElement addAttribute:colorAttribute];
	}
	if([annotation textColor])
	{
		NSXMLNode *textColorAttribute;
		if([annotation category])
		{
			textColorAttribute = [NSXMLNode attributeWithName:@"textColor"
											  stringValue:[[[annotation category] color] hexadecimalValueOfAnNSColor]];
		}
		else
		{
			textColorAttribute = [NSXMLNode attributeWithName:@"textColor"
											  stringValue:[annotation textColor]];
		}
		[eventElement addAttribute:textColorAttribute];
	}
	if([annotation image])
	{
		NSXMLNode *imageAttribute = [NSXMLNode attributeWithName:@"image"
													 stringValue:[[annotation image] relativeString]];
		[eventElement addAttribute:imageAttribute];
	}
	if([annotation caption])
	{
		NSXMLNode *captionAttribute = [NSXMLNode attributeWithName:@"caption"
													   stringValue:[annotation caption]];
		[eventElement addAttribute:captionAttribute];
	}
	if([annotation source])
	{
		NSXMLNode *sourceAttribute = [NSXMLNode attributeWithName:@"annotation-source"
													   stringValue:[annotation source]];
		[eventElement addAttribute:sourceAttribute];
	}
	if(![annotation keyframeImage])
	{
		NSXMLNode *customImageAttribute = [NSXMLNode attributeWithName:@"annotation-keyframeImage"
													  stringValue:@"false"];
		[eventElement addAttribute:customImageAttribute];
	}
	
	return eventElement;
}

- (void)addAnnotation:(Annotation *)annotation
{
	[annotations addObject:annotation];
	
	NSXMLElement *eventElement = [self createAnnotationElement:annotation];
	
	if(self.updateAnnotations)
	{
		[annotation setXmlRepresentation:eventElement];
	}
	
    NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:annotationsRoot selector:@selector(addChild:) object:eventElement];
    [xmlOperationsQueue addOperation:op];
    [op release];
    
	//[[xmlDoc rootElement] addChild:eventElement];
}

- (void)removeAnnotation:(Annotation *)annotation
{	
	[annotation retain];
	[annotations removeObject:annotation];
	
	if(self.updateAnnotations)
	{
        NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:[annotation xmlRepresentation] selector:@selector(detach) object:nil];
        [xmlOperationsQueue addOperation:op];
        [op release];
		//[[annotation xmlRepresentation] detach];
		[annotation setXmlRepresentation:nil];
	}
	
	[annotation release];
}

- (void)updateAnnotation:(Annotation *)annotation
{	
	NSXMLElement *eventElement = [self createAnnotationElement:annotation];
	
	if(self.updateAnnotations)
	{
        NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:[annotation xmlRepresentation] selector:@selector(detach) object:nil];
        [xmlOperationsQueue addOperation:op];
        [op release];
		//[[annotation xmlRepresentation] detach];
		[annotation setXmlRepresentation:eventElement];	
	}

    NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:annotationsRoot selector:@selector(addChild:) object:eventElement];
    [xmlOperationsQueue addOperation:op];
    [op release];
	//[[xmlDoc rootElement] addChild:eventElement];
}

- (void)createXMLDocumentFromFile:(NSString *)file {
    NSError *err=nil;
    NSURL *furl = [NSURL fileURLWithPath:file];
    if (!furl) {
        NSLog(@"Can't create an URL from file %@.", file);
        return;
    }
    xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
												  options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
													error:&err];
    if (xmlDoc == nil) {
        xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:furl
													  options:NSXMLDocumentTidyXML
														error:&err];
    }
    if (xmlDoc == nil)  {
        if (err) {
//            [self handleError:err];
			NSLog(@"Error: %@",[err localizedDescription]);
        }
        annotationsRoot = nil;
        return;
    }
	
    if (err) {
		NSLog(@"Error: %@",[err localizedDescription]);
//        [self handleError:err];
		return;
    }
	
    annotationsRoot = [xmlDoc rootElement];
	NSXMLNode *aNode = [xmlDoc rootElement];
	while ((aNode = [aNode nextNode])) {
		if (([aNode kind] == NSXMLElementKind) && ([[aNode name] caseInsensitiveCompare:@"event"] == NSOrderedSame)) {
			NSXMLElement *element = (NSXMLElement*)aNode;
			
			Annotation* annotation;
			
			NSXMLNode* msNode = [element attributeForName:@"startTimeInterval"];
			if(msNode)
			{
				NSTimeInterval startInterval = [[msNode stringValue] doubleValue];
				annotation = [[Annotation alloc] initWithTimeInterval:startInterval];
				[annotation setDocument:annotationDoc];
			}
			else
			{
				NSString *startString = [[element attributeForName:@"start"] stringValue];
				NSDate *start = [dateFormatter dateFromString:startString];
				if(!start)
					start = [altDateFormatter dateFromString:startString];
				annotation = [[Annotation alloc] initWithStart:start sinceDate:[annotationDoc startDate]];
				[annotation setDocument:annotationDoc];
			}
			
			if(annotation == nil)
				continue;
			
			NSString *title = [[element attributeForName:@"title"] stringValue];
			[annotation setTitle:title];
			
			NSString *value = [[element stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];		
			[annotation setAnnotation:value];
			
			if([element attributeForName:@"isDuration"])
			{
				BOOL isDuration = [[[element attributeForName:@"isDuration"] stringValue] boolValue];
				if(isDuration)
				{
					NSDate* end = nil;
					msNode = [element attributeForName:@"endTimeInterval"];
					if(msNode)
					{
						NSTimeInterval endInterval = [[msNode stringValue] doubleValue];
						[annotation setEndTime:CMTimeMake(endInterval, 1000000)]; // TODO: Check if the timescale is correct.
						//end = [[[NSDate alloc] initWithTimeInterval:endInterval sinceDate:[annotation referenceDate]] autorelease];
					}
					else
					{
						NSString *endString = [[element attributeForName:@"end"] stringValue];
						end = [dateFormatter dateFromString:endString];
						if(!end)
							end = [altDateFormatter dateFromString:endString];
                        NSTimeInterval endTimeInterval = [end timeIntervalSinceDate:[annotationDoc startDate]];
                        [annotation setEndTime:CMTimeMake(endTimeInterval, 1000000)]; // TODO: Check if the timescale is correct.
					}
					[annotation setIsDuration:YES];
				}
			}
			
			// Creation and Modification Tracking
			
			if([element attributeForName:@"annotation-creationDate"])
			{
				NSString *creationDateString = [[element attributeForName:@"annotation-creationDate"] stringValue];
				NSDate *creationDate = [dateFormatter dateFromString:creationDateString];
				[annotation setCreationDate:creationDate];
			}
			else
			{
				[annotation setCreationDate:nil];
			}
			if([element attributeForName:@"annotation-modificationDate"])
			{
				NSString *modificationDateString = [[element attributeForName:@"annotation-modificationDate"] stringValue];
				NSDate *modificationDate = [dateFormatter dateFromString:modificationDateString];
				[annotation setModificationDate:modificationDate];
			}
			else
			{
				[annotation setModificationDate:nil];
			}
			if([element attributeForName:@"annotation-creationUser"])
			{
				NSString *creationUser = [[element attributeForName:@"annotation-creationUser"] stringValue];
				[annotation setCreationUser:creationUser];
			}
			else
			{
				[annotation setCreationUser:nil];
			}
			if([element attributeForName:@"annotation-modificationUser"])
			{
				NSString *modificationUser = [[element attributeForName:@"annotation-modificationUser"] stringValue];
				[annotation setModificationUser:modificationUser];
			}
			else
			{
				[annotation setModificationUser:nil];
			}
			
			
			
			if([element attributeForName:@"annotation-source"])
			{
				NSString *source = [[element attributeForName:@"annotation-source"] stringValue];
				
				[annotation setSource:source];
			}
			if([element attributeForName:@"annotation-autoCreated"])
			{
				BOOL autoCreated = [[[element attributeForName:@"annotation-autoCreated"] stringValue] boolValue];
				
				[annotation setAutoCreated:autoCreated];
			}
			
			
			// Newer way of saving categories
			for(NSXMLElement* child in [element elementsForName:@"category"])
			{
				NSString *name = [[child attributeForName:@"name"] stringValue];
				AnnotationCategory *category = [annotationDoc categoryForName:name];
				
				if(!category)
				{
					category = [annotationDoc createCategoryWithName:name];
				}
				
				if([child attributeForName:@"value"])
				{
					NSString *valueName = [[child attributeForName:@"value"] stringValue];
					AnnotationCategory *value = [category valueForName:valueName];
					[annotation addCategory:value];
				}
				else
				{
					[annotation addCategory:category];
				}
			}
			
			// Older way of saving categories
			if([[annotation categories] count] == 0)
			{
				// Only look for these if there weren't any <category> elements
				if([element attributeForName:@"annotation-category"])
				{
					NSString *categoryName = [[element attributeForName:@"annotation-category"] stringValue];
					
					[annotation setCategory:[annotationDoc categoryForName:categoryName]];
				}
				if([element attributeForName:@"annotation-is-category"])
				{
					BOOL isCategory = [[[element attributeForName:@"annotation-is-category"] stringValue] boolValue];
					
					[annotation setIsCategory:isCategory];
					
					if(isCategory)
					{
						AnnotationCategory *category = [annotationDoc categoryForName:title];
						if(category)
						{
							[category setAnnotation:annotation];
						}
						else
						{
							category = [[AnnotationCategory alloc] init];
							[category setAnnotation:annotation];
							[annotationDoc addCategory:category];
							[category release];
						}
						[annotation setCategory:category];
					}
				}	
			}
			
			if([element attributeForName:@"annotation-keywords"])
			{
				NSString *keywordString = [[element attributeForName:@"annotation-keywords"] stringValue];
				[annotation setKeywords:[keywordString componentsSeparatedByString:@","]];
			}
			if([element attributeForName:@"color"])
			{
				[annotation setColor:[[element attributeForName:@"color"] stringValue]];
			}
			if([element attributeForName:@"textColor"])
			{
				[annotation setTextColor:[[element attributeForName:@"textColor"] stringValue]];
			}
			if([element attributeForName:@"image"])
			{
				[annotation setImage:[NSURL URLWithString:[[element attributeForName:@"image"] stringValue]]];
			}
			if([element attributeForName:@"caption"])
			{
				[annotation setColor:[[element attributeForName:@"caption"] stringValue]];
			}
			if([element attributeForName:@"annotation-keyframeImage"])
			{
				[annotation setKeyframeImage:[[[element attributeForName:@"annotation-keyframeImage"] stringValue] boolValue]];
			}
			
			[annotation setXmlRepresentation:element];
			
			[annotations addObject:annotation];
			
			[annotation release];
		}
	}
}

- (void)createNewXMLDocument
{
	NSXMLElement *root = (NSXMLElement *)[NSXMLNode elementWithName:@"data"];
	xmlDoc = [[NSXMLDocument alloc] initWithRootElement:root];
	[xmlDoc setVersion:@"1.0"];
	[xmlDoc setCharacterEncoding:@"UTF-8"];
    annotationsRoot = [xmlDoc rootElement];
	//[root addChild:[NSXMLNode commentWithStringValue:@"Hello world!"]];
}

- (void)writeToFile:(NSString *)fileName {
    [self writeToFile:fileName waitUntilDone:NO];
}
    
- (void)writeToFile:(NSString *)fileName waitUntilDone:(BOOL)wait
{
    NSOperation *op = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(writeToFileInBackground:) object:fileName];
    [xmlOperationsQueue addOperation:op];
    [op release];
    
    if(wait)
    {
        [xmlOperationsQueue waitUntilAllOperationsAreFinished];
    }
    
}



- (void)writeToFileInBackground:(NSString *)fileName {
    NSData *xmlData = [xmlDoc XMLDataWithOptions:NSXMLNodePrettyPrint];
    if (![xmlData writeToFile:fileName atomically:YES]) {
        NSLog(@"Could not save annotations to file:%@",fileName);
    }
}

@end
