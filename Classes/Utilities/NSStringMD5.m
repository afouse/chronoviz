//
//  NSStringMD5.m
//  DataPrism
//
//  Created by Adam Fouse on 9/30/10.
//  Copyright 2010 University of California, San Diego. All rights reserved.
//

#import "NSStringMD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (MD5)

-(NSString*)md5hash
{
	const char *concat_str = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(concat_str, strlen(concat_str), result);
	NSMutableString *hash = [NSMutableString string];
	int i;
	for (i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[hash appendFormat:@"%02X", result[i]];
	return [hash lowercaseString];
}

@end
