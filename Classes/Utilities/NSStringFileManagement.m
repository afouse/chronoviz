//
//  NSStringFileManagement.m
//  DataPrism
//
//  Created by Adam Fouse on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NSStringFileManagement.h"


@implementation NSString (FileManagement)

- (BOOL)fileExists
{
	return [[NSFileManager defaultManager] fileExistsAtPath:self];
}

- (BOOL)isDirectory
{
	BOOL isDirectory = NO;
	
	[[NSFileManager defaultManager] fileExistsAtPath:self isDirectory:&isDirectory];
	
	return isDirectory;
}

- (BOOL)deleteFile
{
	NSError *error;
	if([self fileExists])
	{
		return [[NSFileManager defaultManager] removeItemAtPath:self error:&error];
	}
	else
	{
		return NO;
	}
}

- (BOOL)verifyOrCreateDirectory
{
	NSError *error;
	
	BOOL isDirectory = NO;
	BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self isDirectory:&isDirectory];
	
	if (exists && isDirectory)
	{
		return YES;
	}
	else if(exists)
	{
		return NO;
	}
	else
	{
		return [[NSFileManager defaultManager] createDirectoryAtPath:self withIntermediateDirectories:YES attributes:nil error:&error];
	}
}

- (NSString*)verifyOrReplace
{
	if([self fileExists])
	{
		return self;
	}
	else
	{
		return [self stringByAskingForReplacement];
	}
}

- (NSString*)stringByAskingForReplacement
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	NSLog(@"%@",self);
	[alert setMessageText:[NSString stringWithFormat:
						   @"The file \"%@\" could not be found. Do you want to select a new file or remove the link to the file?",
						   [self lastPathComponent]]];
	[alert addButtonWithTitle:@"Select New File"];
	[alert addButtonWithTitle:@"Remove Link"];
	NSInteger result = [alert runModal];
	if(result == NSAlertFirstButtonReturn)
	{
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setTitle:@"Select File"];
		[openPanel setMessage:[NSString stringWithFormat:@"Please select the file %@.",[self lastPathComponent]]];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setDirectory:[self stringByDeletingLastPathComponent]];
		
		if ([openPanel runModalForTypes:nil] == NSOKButton) {
			return [openPanel filename];
		}
	}
	return nil;
	
}

- (NSString*)stringByAskingForReplacementDirectory
{
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	NSLog(@"%@",self);
	[alert setMessageText:[NSString stringWithFormat:
						   @"The folder \"%@\" could not be found. Do you want to select a new folder or ignore the folder?",
						   [self lastPathComponent]]];
	[alert addButtonWithTitle:@"Select New Folder"];
	[alert addButtonWithTitle:@"Remove Link"];
	NSInteger result = [alert runModal];
	if(result == NSAlertFirstButtonReturn)
	{
		NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		[openPanel setTitle:@"Select File"];
		[openPanel setMessage:[NSString stringWithFormat:@"Please select the folder %@.",[self lastPathComponent]]];
		[openPanel setAllowsMultipleSelection:NO];
		[openPanel setCanChooseFiles:NO];
		[openPanel setCanChooseDirectories:YES];
		[openPanel setDirectory:[self stringByDeletingLastPathComponent]];
		
		if ([openPanel runModalForTypes:nil] == NSOKButton) {
			return [openPanel filename];
		}
	}
	return nil;
}


- (NSString *)absolutePathFromBaseDirPath:(NSString *)baseDirPath
{
    if ([self hasPrefix:@"~"]) {
        return [self stringByExpandingTildeInPath];
    }
    
    NSString *theBasePath = [baseDirPath stringByExpandingTildeInPath];
	
    if (![self hasPrefix:@"."]) {
        return [theBasePath stringByAppendingPathComponent:self];
    }
    
    NSMutableArray *pathComponents1 = [NSMutableArray arrayWithArray:[self pathComponents]];
    NSMutableArray *pathComponents2 = [NSMutableArray arrayWithArray:[theBasePath pathComponents]];
	
    while ([pathComponents1 count] > 0) {        
        NSString *topComponent1 = [pathComponents1 objectAtIndex:0];
        [pathComponents1 removeObjectAtIndex:0];
		
        if ([topComponent1 isEqualToString:@".."]) {
            if ([pathComponents2 count] == 1) {
                // Error
                return nil;
            }
            [pathComponents2 removeLastObject];
        } else if ([topComponent1 isEqualToString:@"."]) {
            // Do nothing
        } else {
            [pathComponents2 addObject:topComponent1];
        }
    }
    
    return [NSString pathWithComponents:pathComponents2];
}

- (NSString *)relativePathFromBaseDirPath:(NSString *)baseDirPath
{
    NSString *thePath = [self stringByExpandingTildeInPath];
    NSString *theBasePath = [baseDirPath stringByExpandingTildeInPath];
    
//    NSLog(@"The Path: %@",thePath);
//    NSLog(@"The Base Path: %@",theBasePath);
    
    NSMutableArray *pathComponents1 = [NSMutableArray arrayWithArray:[thePath pathComponents]];
    NSMutableArray *pathComponents2 = [NSMutableArray arrayWithArray:[theBasePath pathComponents]];
	
    // Remove same path components
    while ([pathComponents1 count] > 0 && [pathComponents2 count] > 0) {
        NSString *topComponent1 = [pathComponents1 objectAtIndex:0];
        NSString *topComponent2 = [pathComponents2 objectAtIndex:0];
//        NSLog(@"Compare: %@ %@",topComponent1,topComponent2);
        if (![topComponent1 isEqualToString:topComponent2]) {
            break;
        }
        [pathComponents1 removeObjectAtIndex:0];
        [pathComponents2 removeObjectAtIndex:0];
    }
    
    // Create result path
	int i;
    for (i = 0; i < [pathComponents2 count]; i++) {
        [pathComponents1 insertObject:@".." atIndex:0];
    }
    if ([pathComponents1 count] == 0) {
        return @".";
    }
    return [NSString pathWithComponents:pathComponents1];
}

@end
