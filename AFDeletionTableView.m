//
//  AFDeletionTableView.m
//  ChronoViz
//
//  Created by Adam Fouse on 10/6/12.
//
//

#import "AFDeletionTableView.h"

@implementation AFDeletionTableView

- (void)deleteSelection
{
    if([self delegate] && [[self delegate] respondsToSelector:@selector(deleteSelection)])
    {
        [(id)[self delegate] deleteSelection];
    }
}

- (void)deleteBackward:(id)inSender
{
	[self deleteSelection];
}

- (void)deleteForward:(id)inSender
{
	[self deleteSelection];
}

- (void)keyDown:(NSEvent*)event
{
	BOOL deleteKeyEvent = NO;
	
	if ([event type] == NSKeyDown)
	{
		NSString* pressedChars = [event characters];
		if ([pressedChars length] == 1)
		{
			unichar pressedUnichar = [pressedChars characterAtIndex:0];
            
			if ( (pressedUnichar == NSDeleteCharacter) || (pressedUnichar == NSDeleteFunctionKey) )
			{
				deleteKeyEvent = YES;
			}
		}
	}
	
	if (deleteKeyEvent)
	{
		// This will end up calling deleteBackward: or deleteForward:.
		[self interpretKeyEvents:[NSArray arrayWithObject:event]];
	}
	else
	{
		[super keyDown:event];
	}
}


@end
