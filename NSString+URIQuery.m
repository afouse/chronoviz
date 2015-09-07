//
//  NSString+URIQuery.m
//  DataPrism
//
//  Created by Adam Fouse on 6/11/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "NSString+URIQuery.h"


@implementation NSString (URIQuery)

- (NSString*)encodePercentEscapesPerRFC2396 {
	return (NSString*) [(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, NULL, kCFStringEncodingUTF8) autorelease] ;
}


- (NSString*)encodePercentEscapesPerRFC2396ButNot:(NSString*)butNot butAlso:(NSString*)butAlso { return (NSString*) [(NSString*)CFURLCreateStringByAddingPercentEscapes( NULL , (CFStringRef )self, (CFStringRef )butNot, (CFStringRef )butAlso,
																																										
																																										kCFStringEncodingUTF8
																																										) autorelease] ;
}

+ stringWithQueryDictionary:(NSDictionary*)dictionary {
    NSMutableString* string = [NSMutableString string] ;
    NSUInteger countdown = [dictionary count] ;
    NSString* additionsToRFC2396 = @"+=;" ;
    for (NSString* key in dictionary) {
        [string appendFormat:@"%...@=%@",
         [key encodePercentEscapesPerRFC2396ButNot:nil
                                           butAlso:additionsToRFC2396],
		 [[dictionary valueForKey:key] encodePercentEscapesPerRFC2396ButNot:nil butAlso:additionsToRFC2396]
		 ] ;
        countdown-- ;
        if (countdown > 0) {
            [string appendString:@"&"] ;
        }
    }
    return [NSString stringWithString:string] ;
}



- (NSString*)decodeAllPercentEscapes {
	// Unfortunately, CFURLCreateStringByReplacingPercentEscapes() seems to only replace %[NUMBER] escapes 
	NSString* cfWay = (NSString*) [(NSString *)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, CFSTR("")) autorelease] ;
	NSString* cocoaWay = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
    if (![cfWay isEqualToString:cocoaWay]) {
        //NSBeep() ;
		//NSLog(@"[%@ %s]: CF and Cocoa different for %@", [self class], _cmd, self) ;
    }
	
    return cfWay ;
}

- (NSDictionary*)queryDictionaryUsingEncoding: (NSStringEncoding)encoding { 
	NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"] ;
    NSMutableDictionary* pairs = [NSMutableDictionary dictionary] ;
    NSScanner* scanner = [[NSScanner alloc] initWithString:self] ;
    while (![scanner isAtEnd]) {
        NSString* pairString ;
        [scanner scanUpToCharactersFromSet:delimiterSet
                                intoString:&pairString] ;
        [scanner scanCharactersFromSet:delimiterSet intoString:NULL] ;
		NSArray* kvPair = [pairString componentsSeparatedByString:@"="] ;
        if ([kvPair count] == 2) {
			NSString* key = [[kvPair objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:encoding] ;
			NSString* value = [[kvPair objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:encoding] ;
            [pairs setObject:value forKey:key] ;
        }
    }
	
    return [NSDictionary dictionaryWithDictionary:pairs] ;
}

@end