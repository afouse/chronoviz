//
//  BGHUDTableCornerView.h
//  BGHUDAppKit
//
//  Created by BinaryGod on 6/29/08.
//  Copyright 2008 none. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BGThemeManager.h"

IB_DESIGNABLE
@interface BGHUDTableCornerView : NSView {

	NSString *themeKey;
}

@property (copy) IBInspectable NSString *themeKey;

- (instancetype)initWithThemeKey:(NSString *)key;

@end
