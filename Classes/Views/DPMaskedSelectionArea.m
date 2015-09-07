//
//  DPMaskedSelectionArea.m
//  ChronoViz
//
//  Created by Adam Fouse on 10/8/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPMaskedSelectionArea.h"
#import "NSStringUUID.h"

@implementation DPMaskedSelectionArea

@synthesize area,guid,name,color;

- (id)init
{
    self = [super init];
    if (self) {
        guid = [[NSString stringWithUUID] retain];
        area = CGRectNull;
        self.name = @"";
        self.color = [NSColor yellowColor];
    }
    
    return self;
}

- (void)dealloc {
    [guid release];
    self.name = nil;
    self.color = nil;
    [super dealloc];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:guid forKey:@"DPMaskedSelectionAreaID"];
	[coder encodeObject:name forKey:@"DPMaskedSelectionAreaName"];
	[coder encodeObject:color forKey:@"DPMaskedSelectionAreaColor"];
    [coder encodeRect:NSRectFromCGRect(area) forKey:@"DPMaskedSelectionAreaRect"];
}

- (id)initWithCoder:(NSCoder *)coder {
    if(self = [super init])
	{
		guid = [[coder decodeObjectForKey:@"DPMaskedSelectionAreaID"] retain];
        area = NSRectToCGRect([coder decodeRectForKey:@"DPMaskedSelectionAreaRect"]);
		self.name = [coder decodeObjectForKey:@"DPMaskedSelectionAreaName"];
		self.color = [coder decodeObjectForKey:@"DPMaskedSelectionAreaColor"];
		
	}
    return self;
}
@end
