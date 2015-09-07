//
//  NSStringParsing.m
//  Annotation
//
//  Created by Adam Fouse on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSStringParsing.h"
#import "DataSource.h"

@implementation NSString (ParsingExtensions)

-(NSArray *)barRows
{	
	
	NSArray *lines = [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
					   componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:[lines count]];
	
	int columns = 0;
	
	for(NSString *line in lines)
	{
		// Assuming here that the data is numerical unless it's the row headers
		if([line length] > 0)
		{
			NSArray *entriesInLine = [line componentsSeparatedByString:@"|"];
			if(line != [lines objectAtIndex:0])
			{
				NSMutableArray *row = [NSMutableArray arrayWithCapacity:[entriesInLine count]];
				for(NSString *entry in entriesInLine)
				{
					[row addObject:[NSNumber numberWithDouble:[entry doubleValue]]];
				}
				while([row count] < columns)
				{
					[row addObject:[NSNull null]];
				}
				[rows addObject:row];
			}
			else
			{
				columns = [entriesInLine count];
				
				NSMutableArray *columnHeaders = [NSMutableArray arrayWithCapacity:columns];
				for(NSString *entry in entriesInLine)
				{
					NSString *headerTitle = [entry stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					NSString *heading = headerTitle;
					int duplicate = 2;
					while([columnHeaders containsObject:heading])
					{
						heading = [headerTitle stringByAppendingFormat:@"(%i)",duplicate];
						duplicate++;
					}
					[columnHeaders addObject:heading];
				}
				
				[rows addObject:columnHeaders];
			}
		}
	}
	return rows;
}

-(NSArray *)csvQuickRows
{	
	
	NSArray *lines = [[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
					  componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	NSMutableArray *rows = [NSMutableArray arrayWithCapacity:[lines count]];
	
//	int columns = 0;
	
	for(NSString *line in lines)
	{
		if([line length] > 0)
		{
			NSArray *entriesInLine = [line componentsSeparatedByString:@","];
			[rows addObject:entriesInLine];
			
//			if(line != [lines objectAtIndex:0])
//			{
//				NSMutableArray *row = [NSMutableArray arrayWithCapacity:[entriesInLine count]];
//				for(NSString *entry in entriesInLine)
//				{
//					[row addObject:[NSNumber numberWithDouble:[entry doubleValue]]];
//				}
//				while([row count] < columns)
//				{
//					[row addObject:[NSNull null]];
//				}
//				[rows addObject:row];
//			}
//			else
//			{
//				columns = [entriesInLine count];
//				[rows addObject:entriesInLine];
//			}
		}
	}
	return rows;
}

-(NSArray *)csvRows
{
	return [self csvRowsWithDelegate:nil];
}

-(NSArray *)csvRowsWithDelegate:(NSObject*)del {
    
	NSObject<DataSourceDelegate>* delegate = nil;
	
	//Protocol *delegateProtocol = @protocol(DataSourceDelegate);
	if([del conformsToProtocol:@protocol(DataSourceDelegate)])
	{
		delegate = (NSObject<DataSourceDelegate>*)del;
	}
	   
	
	NSMutableArray *rows = [NSMutableArray array];
	
    // Get newline character set
    NSMutableCharacterSet *newlineCharacterSetM = (id)[NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [newlineCharacterSetM formIntersectionWithCharacterSet:[[NSCharacterSet whitespaceCharacterSet] invertedSet]];
	NSCharacterSet *newlineCharacterSet = [newlineCharacterSetM copy];
	
    // Characters that are important to the parser
    NSMutableCharacterSet *importantCharactersSetM = (id)[NSMutableCharacterSet characterSetWithCharactersInString:@",\""];
    [importantCharactersSetM formUnionWithCharacterSet:newlineCharacterSet];
	NSCharacterSet *importantCharactersSet = [importantCharactersSetM copy];
	
	NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceCharacterSet];
	
    // Create scanner, and scan string
    NSScanner *scanner = [[NSScanner alloc] initWithString:self];
    [scanner setCharactersToBeSkipped:nil];
	
	NSMutableString *currentColumn = [NSMutableString string];
	NSMutableArray *columns = [NSMutableArray arrayWithCapacity:10];
	
    while ( ![scanner isAtEnd] ) {    
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
        BOOL insideQuotes = NO;
        BOOL finishedRow = NO;
        //NSMutableArray *columns = [[NSMutableArray alloc] initWithCapacity:10];
        //NSMutableString *currentColumn = [NSMutableString string];
        while ( !finishedRow ) {
			
			[delegate dataSourceLoadStatus:((CGFloat)[scanner scanLocation]/(CGFloat)[self length])];
			
            NSString *tempString;
            if ( [scanner scanUpToCharactersFromSet:importantCharactersSet intoString:&tempString] ) {
                [currentColumn appendString:tempString];
            }
			
            if ( [scanner isAtEnd] ) {
                if ( ![currentColumn isEqualToString:@""] ) [columns addObject:currentColumn];
                finishedRow = YES;
            }
            else if ( [scanner scanCharactersFromSet:newlineCharacterSet intoString:&tempString] ) {
                if ( insideQuotes ) {
                    // Add line break to column text
                    [currentColumn appendString:tempString];
                }
                else {
                    // End of row
                    if ( ![currentColumn isEqualToString:@""] )
					{
						NSString* columnVal = [currentColumn copy];
						[columns addObject:columnVal];
						[columnVal release];
						[currentColumn setString:@""];
					}
                    finishedRow = YES;
                }
            }
            else if ( [scanner scanString:@"\"" intoString:NULL] ) {
                if ( insideQuotes && [scanner scanString:@"\"" intoString:NULL] ) {
                    // Replace double quotes with a single quote in the column string.
                    [currentColumn appendString:@"\""]; 
                }
                else {
                    // Start or end of a quoted string.
                    insideQuotes = !insideQuotes;
                }
            }
            else if ( [scanner scanString:@"," intoString:NULL] ) {  
                if ( insideQuotes ) {
                    [currentColumn appendString:@","];
                }
                else {
                    // This is a column separating comma
					NSString* columnVal = [currentColumn copy];
                    [columns addObject:columnVal];
					[columnVal release];
					[currentColumn setString:@""];
                    //currentColumn = [NSMutableString string];
                    [scanner scanCharactersFromSet:whitespaceCharacterSet intoString:NULL];
                }
            }
        }
        if ( [columns count] > 0 ) {
			NSArray *row = [columns copy];
			[rows addObject:row];
			[row release];
		}
		[columns removeAllObjects];
		[currentColumn setString:@""];
		[pool drain];
    }
	
	[scanner release];
	[newlineCharacterSet release];
	[importantCharactersSet release];
	
    return rows;
}

-(NSString *)csvEscapedString
{
	NSString *escapedString = [[self copy] autorelease];
    
    BOOL containsSeperator = !NSEqualRanges([self rangeOfString:@","], NSMakeRange(NSNotFound, 0));
    BOOL containsQuotes = !NSEqualRanges([self rangeOfString:@"\""], NSMakeRange(NSNotFound, 0));
    BOOL containsLineBreak = !NSEqualRanges([self rangeOfString:@"\n"], NSMakeRange(NSNotFound, 0));
    
    if (containsQuotes) {
        escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""];
    }
    
    if (containsSeperator || containsLineBreak || containsQuotes) {
        escapedString = [NSString stringWithFormat:@"\"%@\"", escapedString];
    }
    
    return escapedString;
}

-(NSString*)quotedString
{
	NSString *escapedString = [self csvEscapedString];
	if([escapedString characterAtIndex:0] != '"')
	{
		escapedString = [NSString stringWithFormat:@"\"%@\"", escapedString];
	}
	return escapedString;
}

@end