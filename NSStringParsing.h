//
//  NSStringParsing.h
//  Annotation
//
//  Created by Adam Fouse on 8/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (ParsingExtensions)

-(NSArray *)csvRowsWithDelegate:(NSObject*)delegate;
-(NSArray *)csvRows;
-(NSArray *)barRows;

-(NSString *)csvEscapedString;

// Quick and dirty (doesn't support quoted commas)
-(NSArray *)csvQuickRows;

-(NSString*)quotedString;

@end
