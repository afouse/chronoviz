//
//  DPConstants.h
//  ChronoViz
//
//  Created by Adam Fouse on 1/3/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	DPSubsetMethodSample	 = 0,
	DPSubsetMethodMax  = 10,
	DPSubsetMethodAverage	 = 20,
    DPSubsetMethodRMS = 30
} DPSubsetMethod;

extern int const DataPrismSelectTool;
extern int const DataPrismZoomTool;

extern int const DPRotation0;
extern int const DPRotation90;
extern int const DPRotation180;
extern int const DPRotation270;

extern CGFloat const MIN_TIMELINE_HEIGHT;

extern NSString * const DataPrismLogState;

extern NSString * const DataSetsChangedNotification;
extern NSString * const DPDataSetRangeChangeNotification;
extern NSString * const DPDataSetUpdatedNotification;

extern NSString * const AFSpeedsKey;
extern NSString * const AFClickToMovePlayheadKey;
extern NSString * const AFRecordClickPosition;
extern NSString * const AFClickSegments;
extern NSString * const AFLogFilesDirectory;
extern NSString * const AFRandomSeedKey;
extern NSString * const AFPauseWhileAnnotatingKey;
extern NSString * const AFAnnotationShortcutActionKey;
extern NSString * const AFTableEditActionKey;
extern NSString * const AFShowPopUpAnnotationsKey;
extern NSString * const AFShowPlayheadKey;
extern NSString * const AFStepValueKey;
extern NSString * const AFSaveInteractionsKey;
extern NSString * const AFSaveTimePositionKey;
extern NSString * const AFSaveAnnotationEditsKey;
extern NSString * const AFSaveVizConfigKey;
extern NSString * const AFUploadInteractionsKey;
extern NSString * const AFLastUploadKey;
extern NSString * const AFUserIdentifierKey;
extern NSString * const AFHierarchicalTimelinesKey;
extern NSString * const AFFilterTimelinesKey;
extern NSString * const AFPlaybackRateKey;
extern NSString * const AFOpenVideosHalfSizeKey;
extern NSString * const AFAutomaticAnnotationFileKey;
extern NSString * const AFUserIDKey;
extern NSString * const AFUserNameKey;
extern NSString * const AFMaxPlaybackRateKey;
extern NSString * const AFCreateFileBackupKey;
extern NSString * const AFDeleteFileBackupKey;
extern NSString * const AFOverwriteFileBackupKey;
extern NSString * const AFUseQuickTimeXKey;
extern NSString * const AFUseStaticMapKey;
extern NSString * const AFEnableChronoVizRemoteKey;
extern NSString * const AFTrackActivityKey;
extern NSString * const AFCacheFrameImagesKey;
extern NSString * const AFMapDelayKey;

extern NSInteger const AFCategoryShortcutInsert;
extern NSInteger const AFCategoryShortcutEditor;
extern NSInteger const AFTableEditInline;
extern NSInteger const AFTableEditExternal;