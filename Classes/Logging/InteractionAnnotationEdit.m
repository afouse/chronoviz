//
//  InteractionAnnotaitonEdit.m
//  Annotation
//
//  Created by Adam Fouse on 1/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "InteractionAnnotationEdit.h"
#import "InteractionLog.h"
#import "Annotation.h"
#import "AnnotationCategory.h"

@implementation InteractionAnnotationEdit

- (id)initWithAnnotation:(Annotation*)theAnnotation 
			forAttribute:(NSString*)theAttribute 
			   withValue:(NSObject*)theValue
		  andSessionTime:(double)theSessionTime
{
    return [self initWithAnnotationTitle:[theAnnotation title]
                               startTime:[theAnnotation startTime]
                            forAttribute:theAttribute
                               withValue:theValue
                          andSessionTime:theSessionTime];
}

- (id)initWithAnnotationTitle:(NSString*)theAnnotationTitle
                    startTime:(CMTime)startTime
                 forAttribute:(NSString*)theAttribute 
                    withValue:(NSObject*)theValue
               andSessionTime:(double)theSessionTime
{
    [super init];
	sessionTime = theSessionTime;
	annotationTitle = [theAnnotationTitle copy];
	annotationTime = startTime;
	
	attribute = [theAttribute retain];
	value = [theValue retain];
	return self;	
}

- (void) dealloc
{
	[annotationTitle release];
	[attribute release];
	[value release];
	[super dealloc];
}


- (NSString *)description
{
	NSString *valueString;
	if([value isKindOfClass:[NSValue class]] && [value respondsToSelector:@selector(QTTimeValue)])
	{
		CMTime qttimeValue = [(NSValue*)value QTTimeValue];
		valueString = [NSString stringWithFormat:@"%1.3f",(double)qttimeValue.value/(double)qttimeValue.timescale];
	}
	else if([value isKindOfClass:[NSString class]])
	{
		valueString = (NSString*)value;
	}
	else if([value isKindOfClass:[AnnotationCategory class]])
	{
		valueString = [NSString stringWithFormat:@"category:%@",[(AnnotationCategory*)value name]];
	}
	
	return [NSString stringWithFormat:@"Time: %1.2f, Annotation Title: %@, Annotation Start: %1.3f, Attribute: %@, Value: %@", sessionTime,annotationTitle,(double)annotationTime.value/(double)annotationTime.timescale,attribute,valueString];
}

- (NSString *)logOutput
{
	NSString *valueString;
	if([value isKindOfClass:[NSValue class]] && [value respondsToSelector:@selector(QTTimeValue)])
	{
		CMTime qttimeValue = [(NSValue*)value QTTimeValue];
		valueString = [NSString stringWithFormat:@"%1.3f",(double)qttimeValue.value/(double)qttimeValue.timescale];
	}
	else if([value isKindOfClass:[NSString class]])
	{
		valueString = (NSString*)value;
	}
	else if([value isKindOfClass:[AnnotationCategory class]])
	{
		valueString = [NSString stringWithFormat:@"category:%@",[(AnnotationCategory*)value name]];
	}
	
	return [NSString stringWithFormat:@"annotationEdit, %1.2f, %@, %1.3f, %@, %@", sessionTime,annotationTitle,(double)annotationTime.value/(double)annotationTime.timescale,attribute,valueString];
}

- (NSXMLElement *)xmlElement
{
	NSXMLElement *element = [super xmlElement];
	
	[element setName:@"annotationEdit"];
	
	NSString *valueString;
	if([value isKindOfClass:[NSValue class]] && [value respondsToSelector:@selector(QTTimeValue)])
	{
		NSTimeInterval time;
		time = CMTimeGetSeconds([(NSValue*)value QTTimeValue]);
		valueString = [NSString stringWithFormat:@"%1.3f",time];
	}
	else if([value isKindOfClass:[NSString class]])
	{
		valueString = (NSString*)value;
	}
	else if([value isKindOfClass:[AnnotationCategory class]])
	{
		valueString = [NSString stringWithFormat:@"category:%@",[(AnnotationCategory*)value name]];
	}
	
	NSXMLNode *annotationTitleAttribute = [NSXMLNode attributeWithName:@"annotationTitle"
													   stringValue:annotationTitle];
	[element addAttribute:annotationTitleAttribute];
	
	NSTimeInterval annotationStartTime;
	annotationStartTime = CMTimeGetSeconds(annotationTime);
	NSXMLNode *annotationTimeAttribute = [NSXMLNode attributeWithName:@"annotationTime"
														   stringValue:[NSString stringWithFormat:@"%1.3f",annotationStartTime]];
	[element addAttribute:annotationTimeAttribute];
	
	NSXMLNode *changedAttribute = [NSXMLNode attributeWithName:@"changedAttribute"
														   stringValue:attribute];
	[element addAttribute:changedAttribute];
	
	NSXMLNode *changedValue = [NSXMLNode attributeWithName:@"changedAttributeValue"
												   stringValue:valueString];
	[element addAttribute:changedValue];
	
	return element;
}

+ (NSString *)typeString
{
	return @"annotationEdit";
}

- (int)type
{
	return AFInteractionTypeAnnotationEdit;
}

-(CMTime)annotationTime
{
    return annotationTime;
}

@end
