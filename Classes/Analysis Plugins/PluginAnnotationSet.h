//
//  PluginAnnotationSet.h
//  ChronoViz
//
//  Created by Adam Fouse on 6/27/20.
//

#import <Foundation/Foundation.h>
@class AnnotationFilter;

NS_ASSUME_NONNULL_BEGIN

@interface PluginAnnotationSet : NSObject <NSCoding> {
    NSString *annotationSetName;
    AnnotationFilter *annotationFilter;
    NSArray *annotations;
}

@property(retain) NSString* annotationSetName;
@property(retain) AnnotationFilter* annotationFilter;
@property(copy) NSArray* annotations;

@end

NS_ASSUME_NONNULL_END
