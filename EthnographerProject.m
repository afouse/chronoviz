//
//  EthnographerProject.m
//  ChronoViz
//
//  Created by Adam Fouse on 8/10/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "EthnographerProject.h"
#import "EthnographerTemplate.h"
#import "NSStringEthnographer.h"
#import "NSStringFileManagement.h"

@implementation EthnographerProject

@synthesize projectName;
@synthesize mappingsFile;

- (id) init
{
	return [self initWithMappingsFile:nil];
}


- (id)initWithMappingsFile:(NSString*)theMappingsFile
{
	self = [super init];
	if (self != nil) {
		templates = [[NSMutableArray alloc] init];
        sessions = [[NSMutableArray alloc] init];
		self.mappingsFile = theMappingsFile;
		self.projectName = nil;
        visibleTemplates = nil;
		
		[self reload];
	}
	return self;
}

- (void) dealloc
{
	self.mappingsFile = nil;
	self.projectName = nil;
    [visibleTemplates release];
	[templates release];
    [sessions release];
	[super dealloc];
}


- (NSArray*)templates
{
    if(!visibleTemplates)
    {
        NSMutableArray *visible = [NSMutableArray array];
        for(EthnographerTemplate *template in templates)
        {
            if(!template.hidden)
            {
                [visible addObject:template];
            }
        }
        visibleTemplates = [[NSArray alloc] initWithArray:visible];
    }
	return visibleTemplates;
}

- (NSArray*)sessions
{
    return sessions;
}

- (EthnographerTemplate*)templateForPage:(NSString*)page
{
	for(EthnographerTemplate *template in templates)
	{
		if([template containsPage:page])
		{
			return template;
		}
	}
	return nil;
}

- (void)reload
{
	NSError *err = nil;
	
    [visibleTemplates release];
    visibleTemplates = nil;
    
	if(!mappingsFile)
	{
		return;
	}
	
	if(!projectName)
	{
		self.projectName = [[mappingsFile stringByDeletingLastPathComponent] lastPathComponent];
	}
	
    // Load sessions
    
    [sessions removeAllObjects];
    
    NSString *directory = [mappingsFile stringByDeletingLastPathComponent];
    
    NSArray *subpaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:directory error:&err];
    
    for(NSString *path in subpaths)
    {
        //NSLog(@"Path: %@",path);
        if(([[path pathExtension] caseInsensitiveCompare:@"xml"] == NSOrderedSame)
           && ([path rangeOfString:@"session" options:NSCaseInsensitiveSearch].location != NSNotFound))
        {
            NSString *filePath = [directory stringByAppendingPathComponent:path];
            NSStringEncoding enc = NSUTF8StringEncoding;
            NSError *err = nil;
            NSString *contents = [[NSString alloc] initWithContentsOfFile:filePath
                                                             usedEncoding:&enc
                                                                    error:&err];
            if([contents rangeOfString:@"<penSession"].location != NSNotFound)
            {
                [sessions addObject:filePath];
            }
            [contents release];
        }
    }
    

    
    // Load templates
    
	NSXMLDocument *mappingsXML = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.mappingsFile]
														 options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
														   error:&err];
	
	if ((mappingsXML == nil) || err)  {
		if (err) {
			NSLog(@"Error: %@",[err localizedDescription]);
		}
		return;
	}
	
	
	NSXMLElement *session = [mappingsXML rootElement];
	if([[session name] caseInsensitiveCompare:@"NoteMappings"] != NSOrderedSame)
	{
		NSLog(@"Expected root element of mappings file to be 'NoteMappings'.");
		return;
	}
	
	NSArray *templateElements = [session nodesForXPath:@".//templates/template" error:&err];
	
    NSMutableArray *currentTemplateNames = [NSMutableArray array];
    
	for(NSXMLElement *element in templateElements)
	{	
		EthnographerTemplate *template = nil;
        
        NSString *templateName = [[element attributeForName:@"name"] stringValue];
        for(EthnographerTemplate *existing in templates)
        {
            if([existing.name isEqualToString:templateName])
            {
                template = existing;
                [template resetRanges];
            }
        }
        if(!template)
        {
            template = [[EthnographerTemplate alloc] init];
            [templates addObject:template];
            [template release];
            template.name = templateName;
        }
        [currentTemplateNames addObject:templateName];
        
        NSString *templateType = [[element attributeForName:@"type"] stringValue];
        if([templateType caseInsensitiveCompare:@"hidden"] == NSOrderedSame)
        {
            template.hidden = YES;
        }
        else
        {
            template.hidden = NO;
        }
        
        template.numPages = [[[element attributeForName:@"nofPages"] stringValue] intValue];
        
        NSString *projectRoot = [mappingsFile stringByDeletingLastPathComponent];
        
        template.background = [projectRoot stringByAppendingPathComponent:[[element attributeForName:@"bgfile"] stringValue]];
        
        NSXMLNode* rotationAttribute = [element attributeForName:@"rotation"];           
        if(rotationAttribute)
        {
            NSArray *rotationArray = [[rotationAttribute stringValue] componentsSeparatedByString:@","];
            
            if([rotationArray count] == template.numPages)
            {
                NSUInteger pdfPage = 1;
                for(NSString* rotation in rotationArray)
                {
                    NSUInteger rotationValue = [rotation integerValue];
                    [template setRotation:rotationValue  forPdfPage:pdfPage];
                    pdfPage++;
                }
            }
            else
            {
                [template setRotation:[[rotationArray objectAtIndex:0] integerValue]];
            }
            
        }
	}
    
    // Remove templates that no longer exist
    NSArray *tempTemplates = [[templates copy] autorelease];
    for(EthnographerTemplate *template in tempTemplates)
    {
        if(![currentTemplateNames containsObject:[template name]])
        {
            [templates removeObject:template];
        }
    }
	
	NSArray *livescribePages = [session nodesForXPath:@".//patternPages/livescribe/pages" error:&err];
	
	for(NSXMLElement *pages in livescribePages)
	{
		EthnographerTemplate *template = nil;
		NSString *templateName = [[pages attributeForName:@"template"] stringValue];
		for(EthnographerTemplate *testTemplate in templates)
		{
			if([templateName isEqualToString:[testTemplate name]])
			{
				template = testTemplate;
				break;
			}
		}
		
		if(!template)
		{
			NSLog(@"Couldn't find matching template for %@",templateName);
			continue;
		}
		
		long long rangestart = [[[pages attributeForName:@"from"] stringValue] livescribePageNumber];
		long long rangeend = [[[pages attributeForName:@"to"] stringValue] livescribePageNumber];
		
		if((rangestart == 0) || (rangeend == 0))
		{
			NSLog(@"Invalid page range");
		}
	
		[template addRangeFrom:rangestart to:rangeend];
		
	}
	
}

- (void)saveTemplates
{
    NSError *err = nil;
	
	if(!mappingsFile)
	{
		return;
	}
	
	if(!projectName)
	{
		self.projectName = [[mappingsFile stringByDeletingLastPathComponent] lastPathComponent];
	}
	
	NSXMLDocument *mappingsXML = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.mappingsFile]
                                                                      options:(NSXMLNodePreserveWhitespace|NSXMLNodePreserveCDATA)
                                                                        error:&err];
	
	if ((mappingsXML == nil) || err)  {
		if (err) {
			NSLog(@"Error: %@",[err localizedDescription]);
		}
		return;
	}
	
	
	NSXMLElement *session = [mappingsXML rootElement];
	if([[session name] caseInsensitiveCompare:@"NoteMappings"] != NSOrderedSame)
	{
		NSLog(@"Expected root element of mappings file to be 'NoteMappings'.");
		return;
	}
	
	NSArray *templateElements = [session nodesForXPath:@".//templates/template" error:&err];
	
	//[templates removeAllObjects];
	for(NSXMLElement *element in templateElements)
	{	
		EthnographerTemplate *template = nil;
		NSString *templateName = [[element attributeForName:@"name"] stringValue];
		for(EthnographerTemplate *existing in templates)
		{
			if([existing.name isEqualToString:templateName])
			{
				template = existing;
				[template resetRanges];
			}
		}
		if(template)
		{
            NSArray *rotations = [template rotations];
            if(rotations)
            {
                NSString *rotationString = [rotations componentsJoinedByString:@","];
                NSXMLNode* rotationAttribute = [element attributeForName:@"rotation"];           
                if(!rotationAttribute)
                {
                    [element addAttribute:[NSXMLNode attributeWithName:@"rotation" stringValue:rotationString]];
                }
                else
                {
                    [rotationAttribute setStringValue:rotationString];
                }
            }
		}
		

	}
    
    NSData *xmlData = [mappingsXML XMLDataWithOptions:NSXMLNodePrettyPrint];
	
    if (![xmlData writeToURL:[NSURL fileURLWithPath:self.mappingsFile] atomically:YES]) {
        NSLog(@"Could not save mappings xml file");
    }
}

@end
