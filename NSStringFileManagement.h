//
//  NSStringFileManagement.h
//  DataPrism
//
//  Created by Adam Fouse on 2/24/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (FileManagement) 

- (BOOL)fileExists;
- (BOOL)isDirectory;
- (BOOL)deleteFile;
- (BOOL)verifyOrCreateDirectory;

- (NSString*)stringByAskingForReplacement;
- (NSString*)stringByAskingForReplacementDirectory;
- (NSString*)verifyOrReplace;

- (NSString *)absolutePathFromBaseDirPath:(NSString *)baseDirPath;
- (NSString *)relativePathFromBaseDirPath:(NSString *)baseDirPath;

@end
