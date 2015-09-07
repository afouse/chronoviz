//
//  ColorTaggedTextCell.h
//  Annotation
//
//  Created by Adam Fouse on 11/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ColorTaggedTextCell : NSTextFieldCell {
	
	CGFloat colorTagWidth;
	CGFloat colorTagHeight;
	
}

@property CGFloat colorTagWidth;
@property CGFloat colorTagHeight;

@end
