//
//  AudioExtractor.h
//  DataPrism
//
//  Created by Adam Fouse on 3/29/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <QuickTime/QuickTime.h>
#import "DataSource.h"
#import "DPConstants.h"

@interface AudioExtractor : NSObject {

	id <DataSourceDelegate> delegate;
	QTMovie *movie;
	Movie mCloneMovie;
	
	NSMutableArray *subsetArray;
	int subsetSize;
    NSTimeInterval sampleSize;
	QTTimeRange subsetTime;
	
	NSWindow *progressWindow;
	NSProgressIndicator *progressIndicator;
	NSButton *cancelButton;
	NSTextField *progressTextField;
	
	BOOL keepExtracting;
    
    DPSubsetMethod subsetMethod;
}

@property NSTimeInterval sampleSize;
@property DPSubsetMethod subsetMethod;

- (id)initWithQTMovie:(QTMovie*)theMovie;
- (void)setDelegate:(id <DataSourceDelegate>)theDelegate;

- (BOOL)exportAudioSubset:(int)subsetSize;
- (BOOL)exportAudioSubset:(int)theSubsetSize forRange:(QTTimeRange)timeRange;
- (NSArray*)subsetArray;

- (NSArray*) getAudioSubset:(NSInteger)subsetSize;
- (NSArray*) getAudioSubsetWithSampleLength:(float)sampleLength;
- (void)cancelExtraction:(id)sender;

@end
