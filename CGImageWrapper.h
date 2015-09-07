//
//  CIImageWrapper.h
//  Annotation
//
//  Created by Adam Fouse on 7/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CGImageWrapper : NSObject <NSCoding> {

	CGImageRef image;
	
}

-(id)initWithImage:(CGImageRef)img;
-(CGImageRef)image;
-(NSData*)imageData;

@end
