//
//  DPRemoteServer.m
//  ChronoViz
//
//  Created by Adam Fouse on 5/28/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPRemoteServer.h"
#import "AsyncSocket.h"
#import "AnnotationDocument.h"
#import "AppController.h"
#import "DPConstants.h"
#import "TimeCodedData.h"
#import "TimeSeriesData.h"
#import "NSString+DropboxPath.h"

#define CHRONOVIZ_PORT 8580

#define READ_TIMEOUT 15.0
#define READ_TIMEOUT_EXTENSION 10.0

@interface DPRemoteServer (Private)

- (void)writeString:(NSString*)string toSocket:(AsyncSocket*)socket;
- (NSString*)availableDataString;
- (NSString*)documentString;
- (NSString*)documentFullPathString;
- (NSString*)documentDropboxPathString;
- (void)sendDataSet:(TimeCodedData*)data toSocket:(AsyncSocket*)socket;

- (void)executeTimeUpdate:(NSNumber*)time;

@end

@implementation DPRemoteServer

@synthesize serverMenuItem;

static DPRemoteServer* defaultServer = nil;

+(DPRemoteServer*) defaultServer
{
	if(!defaultServer)
	{
		defaultServer = [[DPRemoteServer alloc] init];
	}
	return defaultServer;
}


- (id)init
{
	if((self = [super init]))
	{
		listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
		connectedSockets = [[NSMutableArray alloc] initWithCapacity:1];
		
		isRunning = NO;
		
		ipWindow = nil;
		
		updateOperation = nil;
		
		lastTimeUpdate = 0;
		
        dropboxDirectory = nil;
        
		if(!defaultServer)
		{
			defaultServer = self;
		}
		
	}
	return self;
}


- (void) dealloc
{
	if(isRunning)
	{
		[self startStop:self];
	}
	
	[updateOperation release];
	[updateQueue cancelAllOperations];
	[updateQueue release];
	
	[ipWindow release];
	[ipTextField release];
	
	[listenSocket release];
	[connectedSockets release];
    
    [dropboxDirectory release];
	
	[super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
	NSLog(@"observe value");
    if ([keyPath isEqual:@"document"]) {
		NSLog(@"observer document change");
		for(AsyncSocket *sock in connectedSockets)
		{
			[self writeString:[self documentString] toSocket:sock];		
		}

    }
}

- (IBAction)startStop:(id)sender
{
	if(!isRunning)
	{
		updateQueue = [[NSOperationQueue alloc] init];
		[updateQueue setMaxConcurrentOperationCount:1];
		
		int port = CHRONOVIZ_PORT;
		
		NSError *error = nil;
		if(![listenSocket acceptOnPort:port error:&error])
		{
			NSLog(@"Error starting server: %@", error);
			return;
		}
		
		NSLog(@"ChronoViz server started on port %hu", [listenSocket localPort]);
		isRunning = YES;
		
		NSWindow *ipWin = [self ipWindow];
		[ipTextField setStringValue:[NSString stringWithFormat:@"Current IP address: %@",[[[NSHost currentHost] addresses] objectAtIndex:1]]];
		[ipWin makeKeyAndOrderFront:self];
		
		[[AppController currentApp] addAnnotationView:self];
		
		[[AppController currentApp] addObserver:self
									 forKeyPath:@"document"
										options:0
										context:NULL];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(startStop:)
													 name:NSApplicationWillTerminateNotification
												   object:nil];
		
		
		
		[serverMenuItem setTitle:@"Stop Remote Client Connection"];
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self];
		
		[[AppController currentApp] removeObserver:self forKeyPath:@"document"];
		[[AppController currentApp] removeAnnotationView:self];
		
		[updateQueue cancelAllOperations];
		[updateQueue release];
		updateQueue = nil;
		
		// Stop accepting connections
		[listenSocket disconnect];
		
		// Stop any client connections
		NSUInteger i;
		for(i = 0; i < [connectedSockets count]; i++)
		{
			// Call disconnect on the socket,
			// which will invoke the onSocketDidDisconnect: method,
			// which will remove the socket from the list.
			[[connectedSockets objectAtIndex:i] disconnect];
		}
		
		NSLog(@"Stopped ChronoViz server");
		isRunning = false;
		
		if(ipWindow && [ipWindow isVisible])
		{
			[ipWindow close];
		}
		
		[serverMenuItem setTitle:@"Start Remote Client Connection"];
	}
	
}

- (NSWindow*)ipWindow
{
	if(!ipWindow)
	{
		ipWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(200,400,480,120)
													 styleMask:NSTitledWindowMask
													   backing:NSBackingStoreBuffered
														 defer:NO];
		[ipWindow setLevel:NSStatusWindowLevel];
		[ipWindow setReleasedWhenClosed:NO];
				
		NSButton *cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(370,12,96,32)];
		[cancelButton setBezelStyle:NSRoundedBezelStyle];
		[cancelButton setTitle:@"Cancel"];
		[cancelButton setAction:@selector(startStop:)];
		[cancelButton setTarget:self];
		
		ipTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(17, 84, 444, 17)];
		[ipTextField setStringValue:@"Current IP Address: 0"];
		[ipTextField setEditable:NO];
		[ipTextField setDrawsBackground:NO];
		[ipTextField setBordered:NO];
		[ipTextField setAlignment:NSLeftTextAlignment];
		
		[[ipWindow contentView] addSubview:cancelButton];
		[[ipWindow contentView] addSubview:ipTextField];
		
		[cancelButton release];
	}
	return ipWindow;
	
}

#pragma mark Sending Messages

- (void)writeString:(NSString*)string toSocket:(AsyncSocket*)socket
{
	NSLog(@"Write string: %@ to Socket: %@",string,[socket connectedHost]);
	
	NSData *commandData = [string dataUsingEncoding:NSUTF8StringEncoding];
	
	[socket writeData:commandData withTimeout:-1 tag:0];
}

- (NSString*)documentString
{
	AnnotationDocument *doc = [AnnotationDocument currentDocument];
	
    NSTimeInterval duration;
    duration = CMTimeGetSeconds([doc duration]);
    
	return [NSString stringWithFormat:@"Document:%@:%f\r\n",[[doc annotationsDirectory] lastPathComponent],duration];
}

- (NSString*)documentFullPathString
{
	AnnotationDocument *doc = [AnnotationDocument currentDocument];
	
	return [NSString stringWithFormat:@"DocumentFullPath:%@\r\n",[doc annotationsDirectory]];
}

- (NSString*)documentDropboxPathString
{
	AnnotationDocument *doc = [AnnotationDocument currentDocument];
	
    if(!dropboxDirectory)
    {
        dropboxDirectory = [[NSString dropboxPath] copy];
    }
    
    if(dropboxDirectory)
    {
        NSRange substring = [[doc annotationsDirectory] rangeOfString:dropboxDirectory];
        if(substring.location != NSNotFound)
        {
           return [NSString stringWithFormat:@"DocumentDropboxPath:%@\r\n",[[doc annotationsDirectory] substringFromIndex:substring.location]]; 
        }
    }
    	
    return [NSString stringWithFormat:@"DocumentDropboxPath:\r\n"];
}

- (NSString*)availableDataString
{
	AnnotationDocument *doc = [AnnotationDocument currentDocument];
	
	NSMutableString *string = [NSMutableString stringWithString:@"AvailableData"];
	
	for(TimeCodedData* data in [doc dataSets])
	{
		[string appendFormat:@":Type=%@;UUID=%@",[data className],[data uuid]];
	}
	
	[string appendString:@"\r\n"];
	
	return string;
}

- (void)sendDataSet:(TimeCodedData*)data toSocket:(AsyncSocket*)socket
{
	if([data isKindOfClass:[TimeSeriesData class]])
	{
		NSString *csvData = [[(TimeSeriesData*)data csvData] stringByAppendingString:@"\r\n"];
		//NSLog(@"CSV Data: %@",csvData);
		NSData *dataSetData = [csvData dataUsingEncoding:NSUTF8StringEncoding];
		NSString *command = [NSString stringWithFormat:@"DataSet:Type=%@,UUID=%@,Size=%i,Name=%@\r\n",[data className],[data uuid],[dataSetData length],[data name]];
		NSData *commandData = [command dataUsingEncoding:NSUTF8StringEncoding];
		
		[socket writeData:commandData withTimeout:-1 tag:0];
		[socket writeData:dataSetData withTimeout:-1 tag:0];
	}
}

- (void)executeTimeUpdate:(NSNumber*)timeNumber
{
	NSTimeInterval time;
	time = CMTimeGetSeconds([[AppController currentApp] currentTime]);
	
    //NSLog(@"Time: %f timeUpdate: %f",time,lastTimeUpdate);
    
	if(fabs(time - lastTimeUpdate) > .01)
	{
        //CMTime moveTime = CMTimeMake(lastTimeUpdate, 1000000); // TODO: Check if the timescale is correct.
        //NSLog(@"Current Time: %qi / %ld",moveTime.value,moveTime.timescale);
        
		[[AppController currentApp] moveToTime:CMTimeMake(lastTimeUpdate, 1000000) fromSender:self]; // TODO: Check if the timescale is correct.
	}
	//[[AppController currentApp] moveToTime:CMTimeMake([time floatValue], 1000000) fromSender:self]; // TODO: Check if the timescale is correct.
}

#pragma mark AsyncSocket Delegate

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
    NSLog(@"Accepted new socked");
    
	[connectedSockets addObject:newSocket];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"Accepted client %@:%hu", host, port);
	
	[sock readDataToData:[AsyncSocket CRLFData] withTimeout:READ_TIMEOUT tag:0];
	
	if(ipWindow && [ipWindow isVisible])
	{
		[ipWindow close];
	}
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSData *strData = [data subdataWithRange:NSMakeRange(0, [data length] - 2)];
	NSString *msg = [[[NSString alloc] initWithData:strData encoding:NSUTF8StringEncoding] autorelease];
	
	NSLog(@"Received Message: %@",msg);
	
	NSArray *components = [msg componentsSeparatedByString:@":"];
	
	NSString *command = [components objectAtIndex:0];
	
	if([command isEqualToString:@"ChronoVizConnectionProtocol"])
	{
		[self writeString:[self documentString] toSocket:sock];	
	}
	else if ([command isEqualToString:@"Time"])
	{
		lastTimeUpdate = [[components objectAtIndex:1] floatValue];
		
		//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(executeTimeUpdate:) object:nil];
		[self performSelector:@selector(executeTimeUpdate:) withObject:nil afterDelay:0.1];
		
//		[updateOperation cancel];
//		[updateOperation release];
//		updateOperation = [[NSInvocationOperation alloc] initWithTarget:self
//																		 selector:@selector(executeTimeUpdate:) 
//																		   object:[NSNumber numberWithFloat:[[components objectAtIndex:1] floatValue]]];
//		[updateQueue addOperation:updateOperation];
		
//		NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self
//																		 selector:@selector(executeTimeUpdate:) 
//																		   object:[NSNumber numberWithFloat:[[components objectAtIndex:1] floatValue]]];
//		[updateQueue cancelAllOperations];
//		[updateQueue addOperation:op];
//		[op release];
		
	}
    else if ([command isEqualToString:@"RequestDocumentFullPath"])
	{
		[self writeString:[self documentFullPathString] toSocket:sock];
	}
    else if ([command isEqualToString:@"RequestDocumentDropboxPath"])
	{
		[self writeString:[self documentDropboxPathString] toSocket:sock];
	}
	else if ([command isEqualToString:@"RequestAvailableData"])
	{
		[self writeString:[self availableDataString] toSocket:sock];
	}
	else if ([command isEqualToString:@"RequestDataSet"])
	{
		NSString *uuid = [components objectAtIndex:1];
		for(TimeCodedData *data in [[AnnotationDocument currentDocument] dataSets])
		{
			if([[data uuid] isEqualToString:uuid])
			{
				[self sendDataSet:data toSocket:sock];
			}
		}
	}
	
	// Even if we were unable to write the incoming data to the log,
	// we're still going to echo it back to the client.
	//[sock writeData:data withTimeout:-1 tag:0];
	[sock readDataToData:[AsyncSocket CRLFData] withTimeout:-1 tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
	//NSLog(@"Wrote data");
}

- (void)onSocket:(AsyncSocket *)sock didWritePartialDataOfLength:(NSUInteger)partialLength tag:(long)tag
{
	//NSLog(@"Wrote partial data");
}

/**
 * This method is called if a read has timed out.
 * It allows us to optionally extend the timeout.
 * We use this method to issue a warning to the user prior to disconnecting them.
 **/
- (NSTimeInterval)onSocket:(AsyncSocket *)sock
  shouldTimeoutReadWithTag:(long)tag
				   elapsed:(NSTimeInterval)elapsed
				 bytesDone:(NSUInteger)length
{
	
	NSLog(@"Should timeout?");
	
	if(elapsed <= READ_TIMEOUT)
	{
		NSString *warningMsg = @"Are you still there?\r\n";
		NSData *warningData = [warningMsg dataUsingEncoding:NSUTF8StringEncoding];
		
		[sock writeData:warningData withTimeout:-1 tag:0];
		
		return READ_TIMEOUT_EXTENSION;
	}
	
	return 0.0;
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	NSLog(@"Client Disconnected: %@:%hu", [sock connectedHost], [sock connectedPort]);
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"Socket disconnect");
	[connectedSockets removeObject:sock];
}

#pragma mark AnnotationView Methods

-(void)addAnnotation:(Annotation*)annotation
{
	//[annotations addObject:annotation];
	//[tableView reloadData];
}

-(void)addAnnotations:(NSArray*)array
{
	//[annotations addObjectsFromArray:array];
	//[tableView reloadData];
}

-(void)removeAnnotation:(Annotation*)annotation
{
	//[annotations removeObject:annotation];
	//[tableView reloadData];
}

-(void)updateAnnotation:(Annotation*)annotation
{
	//[tableView reloadData];
}

-(void)setAnnotationFilter:(AnnotationFilter*)filter
{
	//	annotationFilter = [filter retain];
	//	filterAnnotations = YES;
	//	[self redrawAllSegments];
}

-(AnnotationFilter*)annotationFilter
{
	return nil;
}

-(NSArray*)dataSets
{
	return [NSArray array];
}


-(void)update
{
	NSTimeInterval time;
	time = CMTimeGetSeconds([[AppController currentApp] currentTime]);

	if(abs(time - lastTimeUpdate) > .01)
	{
		NSString *initMsg = [NSString stringWithFormat:@"Time:%f\r\n",time];
		NSData *timeData = [initMsg dataUsingEncoding:NSUTF8StringEncoding];
		
		for(AsyncSocket *socket in connectedSockets)
		{
			//NSLog(@"Send command: %@ toSocket: %@",initMsg,[socket connectedHost]);
			[socket writeData:timeData withTimeout:-1 tag:0];
			

		}
	}
}

@end
