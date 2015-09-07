//
//  EthnographerTemplate.h
//  ChronoViz
//
//  Created by Adam Fouse on 8/11/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface EthnographerTemplate : NSObject {

	NSString *name;
	NSString *background;
	BOOL printed;
    BOOL hidden;
	
    NSMutableArray *rotations;
    
	NSUInteger numPages;
	NSMutableArray *pageRanges;
	
}

@property(copy) NSString *name;
@property(copy) NSString *background;
@property BOOL printed;
@property BOOL hidden;
@property NSUInteger numPages;

- (void)addRangeFrom:(long long)begin to:(long long)end;
- (void)resetRanges;
- (NSInteger)pdfPageForLivescribePage:(NSString*)lsPage;

- (NSUInteger)rotationForPdfPage:(NSUInteger)pdfPage;
- (NSArray*)rotations;
- (void)setRotation:(NSUInteger)rotation forPdfPage:(NSUInteger)pdfPage;
- (void)setRotation:(NSUInteger)rotation;

- (BOOL)containsPage:(NSString*)lsPage;
@end
