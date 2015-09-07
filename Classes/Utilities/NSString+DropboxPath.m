//
//  NSString+DropboxPath.m
//  ChronoViz
//
//  Created by Adam Fouse on 5/2/12.
//  Copyright (c) 2012 University of California, San Diego. All rights reserved.
//

#import "NSString+DropboxPath.h"
#import "NSStringFileManagement.h"
#import "NSData+Base64.h"
#import <sqlite3.h>

@implementation NSString (DropboxPath)

+ (NSString*)dropboxPath
{
    // sqlite3 config.db "select value from config where key='dropbox_path';"
    
    NSString *result = nil;
    NSString *searchResult = nil;
    
    NSString *dropboxConfigDir = [@"~/.dropbox" stringByExpandingTildeInPath];
    if([dropboxConfigDir fileExists])
    {
        NSString *dbFile = [dropboxConfigDir stringByAppendingPathComponent:@"config.db"];
        
        if([dbFile fileExists])
        {
            
            sqlite3 *_db = NULL;
            sqlite3_stmt *_stmt = NULL;
            NSString *sql = @"select value from config where key='dropbox_path';";
            if(sqlite3_open([dbFile UTF8String], &_db) == SQLITE_OK)
            {
                int rc;
                rc = sqlite3_prepare_v2(_db, [sql UTF8String], -1, &_stmt, NULL);
                
                if(rc != SQLITE_OK)
                {
                    searchResult = @"Could not prepare SQL statement to find dropbox location";
                }
                
                rc = sqlite3_step(_stmt);
                
                if(rc == SQLITE_DONE)
                {
                    // Using dropbox > 1.2
                    
                    NSString *hostdbfile = [dropboxConfigDir stringByAppendingPathComponent:@"host.db"];
                    
                    if([hostdbfile fileExists])
                    {                    
                        NSStringEncoding encoding;
                        NSError *err = nil;
                        NSString *hostdb = [NSString stringWithContentsOfFile:hostdbfile usedEncoding:&encoding error:&err];
                        
                        NSString *b64 = [[hostdb componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] lastObject];
                        
                        NSString *hostsDir = [NSData base64Decode:b64];
                        
                        if([hostsDir fileExists])
                        {
                            result = hostsDir;
                            searchResult = @"Found directory from base 64 decode of host.db";
                        }
                        else
                        {
                            searchResult = @"Tried to find directory from host.db but failed";
                        }
                    }
                    else
                    {
                        searchResult = @"host.db file couldn't be found";
                    }
                }
                else if(rc == SQLITE_ROW)
                {
                    const char* columnValue = (const char*)sqlite3_column_text(_stmt, 0);
                    if(columnValue != NULL)
                        result = [NSString stringWithUTF8String:columnValue];
                    searchResult = @"Successful database query";
                }
                else
                {
                    searchResult = @"Database query failed";
                }
                
                sqlite3_finalize(_stmt);
                sqlite3_close(_db);
                
                
            }
            else
            {
                searchResult = @"Can't open dropbox db";
            }
        }
        else
        {
            searchResult = @"Dropbox Config File doesn't exist";
        }
    }
    else
    {
        searchResult = @"Dropbox Config Dir doesn't exist";
    }
    
    if(!result)
    {
        NSString* defaultDropbox = [@"~/Dropbox" stringByExpandingTildeInPath];
        if([defaultDropbox fileExists])
        {
            searchResult = @"Using default dropbox directory location";
            result = defaultDropbox;
        }
    }
    
    if(searchResult)
    {
        NSLog(@"%@",searchResult);
    }
    
    return result;

}

@end
