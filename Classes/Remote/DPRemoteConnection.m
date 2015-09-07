//
//  DPRemoteConnection.m
//  ChonoVizTouch
//
//  Created by Adam Fouse on 5/27/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPRemoteConnection.h"
#import "AppController.h"
#import "AsyncSocket.h"
#import "GeographicTimeSeriesData.h"
#import "NSStringFileManagement.h"
#import "NSString+DropboxPath.h"

#define CHRONOVIZ_PORT 8580

#define DATA_READ_TAG 2

NSString *const DPRemoteConnectionStateChangeNotification = @"DPRemoteConnectionStateChange";
NSString *const DPRemoteConnectionTimeUpdate = @"DPRemoteConnectionTimeUpdate";

@interface DPRemoteConnection (Private)

- (void)requestData;
- (void)requestDataSet:(NSString*)uuid;
- (void)processReceivedData:(NSString*)dataString;

@end

@implementation DPRemoteConnection


- (id) init
{
	self = [super init];
	if (self != nil) {
		socket = [[AsyncSocket alloc] initWithDelegate:self];
		self.state = DPRemoteConnectionNotConnected;
		messageTag = 3;
	}
	return self;
}

- (void) dealloc
{
	[super dealloc];
}


- (BOOL)dataLoaded
{
	return (state == DPRemoteConnectionConnected);
}

- (void)connectToAddress:(NSString*)hostname
{
	if(![socket isConnected])
	{
		NSLog(@"Attempting to connect to %@",hostname);
		NSString *newAddress = [hostname copy];
		[remoteAddress release];
		remoteAddress = newAddress;
		NSError *err = nil;
		[socket connectToHost:hostname onPort:CHRONOVIZ_PORT error:&err];
		//[socket readDataToData:[AsyncSocket CRLFData] withTimeout:TIMEOUT_NONE tag:TAG_HEADER];	
	}	
}

- (NSString*)remoteAddress
{
	return remoteAddress;
}


- (BOOL)isConnected
{
	return [socket isConnected];
}

- (void)disconnect
{
	[socket disconnect];
	self.state = DPRemoteConnectionNotConnected;
}

- (DPRemoteConnectionState)state
{
	return state;
}

-(void)setState:(DPRemoteConnectionState)theState
{
    state = theState;
}

- (void)sendTimeMessage:(NSTimeInterval)time
{
	NSString *initMsg = [NSString stringWithFormat:@"Time:%f\r\n",time];
	NSData *timeData = [initMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	[socket writeData:timeData withTimeout:-1 tag:0];
}

- (void)requestDataSet:(NSString*)uuid
{
	NSString *initMsg = [NSString stringWithFormat:@"RequestDataSet:%@\r\n",uuid];
	NSData *timeData = [initMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	[socket writeData:timeData withTimeout:-1 tag:0];
}

- (void)processReceivedData:(NSString*)dataString
{
	
}

#pragma mark AsyncSocket Delegate

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{	
	NSString *initMsg = @"ChronoVizConnectionProtocol:Version=1.0:Request Connection Type=iPad\r\n";
	NSData *welcomeData = [initMsg dataUsingEncoding:NSUTF8StringEncoding];
	
	self.state = DPRemoteConnectionConnectedNoData;
	
	[sock writeData:welcomeData withTimeout:-1 tag:0];
	
	[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	
	if(tag == DATA_READ_TAG)
	{
		NSLog(@"Received Data: %i",[data length]);
        
        // Desktop client doesn't yet support transfering data
        
//		GeographicTimeSeriesData *geoData = [[GeographicTimeSeriesData alloc] initWithCSVData:msg];
//		geoData.name = @"Geographic Data";
//		[[document mutableArrayValueForKey:@"dataSets"] addObject:geoData];
//		[geoData release];
		self.state = DPRemoteConnectionConnected;
	}
	else
	{
		//NSLog(@"Received Message: %@",msg);
		
		NSArray *components = [msg componentsSeparatedByString:@":"];
		
		NSString *command = [components objectAtIndex:0];
		
		if([command isEqualToString:@"ChronoVizConnectionProtocol"])
		{
			
		}
		else if ([command isEqualToString:@"Time"])
		{
			NSNumber *time = [NSNumber numberWithFloat:[[components objectAtIndex:1] floatValue]];
			
			[[NSNotificationCenter defaultCenter] postNotificationName:DPRemoteConnectionTimeUpdate
																object:self
															  userInfo:[NSDictionary dictionaryWithObject:time forKey:@"time"]];
		}
		else if ([command isEqualToString:@"Document"])
		{
            NSLog(@"Received Document Message: %@",[components objectAtIndex:1]);
			self.state = DPRemoteConnectionConnectedNoHandshake;
			
            NSString *initMsg = @"RequestDocumentDropboxPath\r\n";
            NSData *fullPathData = [initMsg dataUsingEncoding:NSUTF8StringEncoding];
            [socket writeData:fullPathData withTimeout:-1 tag:0];
            
//			DPRemoteDocument *doc = [[DPRemoteDocument alloc] init];
//			doc.name = [components objectAtIndex:1];
//			
//			self.document = doc;
//			
//			[doc release];
//			
//			NSString *initMsg = @"RequestAvailableData\r\n";
//			NSData *timeData = [initMsg dataUsingEncoding:NSUTF8StringEncoding];
//			
//			[socket writeData:timeData withTimeout:-1 tag:0];
		}
        else if ([command isEqualToString:@"DocumentFullPath"])
		{
            NSLog(@"Received Document Path Message: %@",[components objectAtIndex:1]);
            NSString *fullPath = [components objectAtIndex:1];
            NSString *resolvedFile = nil;
            if([fullPath fileExists])
            {
                resolvedFile = fullPath;
            }
            else
            {
                NSRange dropboxString = [fullPath rangeOfString:@"/Dropbox/" options:NSCaseInsensitiveSearch];
                if(dropboxString.location != NSNotFound)
                {
                    NSString *relativePath = [@"~" stringByAppendingString:[fullPath substringFromIndex:dropboxString.location]];
                    NSString *newFile = [relativePath stringByStandardizingPath];
                    if([newFile fileExists])
                    {
                        resolvedFile = newFile;
                    }
                }
                
            }

            
            if(resolvedFile)
            {
                [[AppController currentApp] application:NSApp openFile:resolvedFile];
            }

            self.state = DPRemoteConnectionConnected;
		}
        else if ([command isEqualToString:@"DocumentDropboxPath"])
		{
            NSLog(@"Received Document Path Message: %@",[components objectAtIndex:1]);
            NSString *subPath = [components objectAtIndex:1];
            
            if(!dropboxDirectory)
            {
                dropboxDirectory = [[NSString dropboxPath] copy];
            }
            
            NSString *fullPath = [dropboxDirectory stringByAppendingPathComponent:subPath];
            NSString *resolvedFile = nil;
            if([fullPath fileExists])
            {
                resolvedFile = fullPath;
            }
            
            
            if(resolvedFile)
            {
                [[AppController currentApp] application:NSApp openFile:resolvedFile];
            }
            
            self.state = DPRemoteConnectionConnected;
		}
		else if ([command isEqualToString:@"AvailableData"])
		{
//			if(!document)
//			{
//				DPRemoteDocument *doc = [[DPRemoteDocument alloc] init];
//				doc.name = @"ChronoViz Document";
//				self.document = doc;
//				[doc release];
//			}
//			BOOL loadingData = NO;
//			for(NSString *component in components)
//			{
//				if([component rangeOfString:@"Geographic"].location != NSNotFound)
//				{
//					loadingData = YES;
//					NSRange start = [component rangeOfString:@"UUID="];
//					NSString *uuid = [component substringFromIndex:(start.location + start.length)];
//					[self requestDataSet:uuid];
//					//[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
//				}
//			}
//			if(!loadingData)
//			{
//				self.state = DPRemoteConnectionConnected;
//			}
		}
		else if ([command isEqualToString:@"DataSet"])
		{
			for(NSString* component in components)
			{
				NSRange sizeRange = [component rangeOfString:@"Size="];
				if(sizeRange.location != NSNotFound)
				{
					int size = [[component substringFromIndex:(sizeRange.location + sizeRange.length)] intValue];
					[sock readDataToLength:size withTimeout:-1 tag:DATA_READ_TAG];
					return;
					
				}
			}
		}	
	}
	
	[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:messageTag];
	
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	//NSLog(@"Wrote data");
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
    //NSLog(@"Socket");
}

/**
 * Called when a socket disconnects with or without error.  If you want to release a socket after it disconnects,
 * do so here. It is not safe to do that during "onSocket:willDisconnectWithError:".
 * 
 * If you call the disconnect method, and the socket wasn't already disconnected,
 * this delegate method will be called before the disconnect method returns.
 **/
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    //NSLog(@"Socket"); 
}

/**
 * Called when a socket accepts a connection.  Another socket is spawned to handle it. The new socket will have
 * the same delegate and will call "onSocket:didConnectToHost:port:".
 **/
- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
     //NSLog(@"Socket");
}


/**
 * Called when a socket is about to connect. This method should return YES to continue, or NO to abort.
 * If aborted, will result in AsyncSocketCanceledError.
 * 
 * If the connectToHost:onPort:error: method was called, the delegate will be able to access and configure the
 * CFReadStream and CFWriteStream as desired prior to connection.
 *
 * If the connectToAddress:error: method was called, the delegate will be able to access and configure the
 * CFSocket and CFSocketNativeHandle (BSD socket) as desired prior to connection. You will be able to access and
 * configure the CFReadStream and CFWriteStream in the onSocket:didConnectToHost:port: method.
 **/
- (BOOL)onSocketWillConnect:(AsyncSocket *)sock
{
    //NSLog(@"Socket");
    return YES;
}



/**
 * Called when a socket has read in data, but has not yet completed the read.
 * This would occur if using readToData: or readToLength: methods.
 * It may be used to for things such as updating progress bars.
 **/
- (void)onSocket:(AsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
     //NSLog(@"Socket");
}



/**
 * Called when a socket has written some data, but has not yet completed the entire write.
 * It may be used to for things such as updating progress bars.
 **/
- (void)onSocket:(AsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
     //NSLog(@"Socket");
}


@end
