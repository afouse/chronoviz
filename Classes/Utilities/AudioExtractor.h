//
//  AudioExtractor.h
//  DataPrism
//
//  Created by Adam Fouse on 3/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>
#import "DataSource.h"
#import "DPConstants.h"

@interface AudioExtractor : NSObject {

	id <DataSourceDelegate> delegate;
	QTMovie *movie;
	//Movie mCloneMovie;
	
	NSMutableArray *subsetArray;
	NSInteger subsetSize;
    NSTimeInterval sampleSize;
	CMTimeRange subsetTime;
	
	NSWindow *progressWindow;
	NSProgressIndicator *progressIndicator;
	NSButton *cancelButton;
	NSTextField *progressTextField;
	
	BOOL keepExtracting;
    
    DPSubsetMethod subsetMethod;
}

@property NSTimeInterval sampleSize;
@property (nonatomic,assign) DPSubsetMethod subsetMethod;

- (id)initWithQTMovie:(QTMovie*)theMovie;
- (void)setDelegate:(id <DataSourceDelegate>)theDelegate;

- (BOOL)exportAudioSubset:(int)subsetSize;
- (BOOL)exportAudioSubset:(int)theSubsetSize forRange:(CMTimeRange)timeRange;
- (NSArray*)subsetArray;

- (NSArray*) getAudioSubset:(NSInteger)subsetSize;
- (NSArray*) getAudioSubsetWithSampleLength:(float)sampleLength;
- (void)cancelExtraction:(id)sender;

@end
