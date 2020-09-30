//
//  DPConstants.m
//  ChronoViz
//
//  Created by Adam Fouse on 1/3/11.
//  Copyright 2011 University of California, San Diego. All rights reserved.
//

#import "DPConstants.h"

int const DataPrismSelectTool = 0;
int const DataPrismZoomTool = 1;

int const DPRotation0 = 0;
int const DPRotation90 = 1;
int const DPRotation180 = 2;
int const DPRotation270 = 3;

CGFloat const MIN_TIMELINE_HEIGHT = 30;

NSString * const DataSetsChangedNotification = @"DataSetsChangedNotification";
NSString * const DPDataSetRangeChangeNotification = @"DataSetRangeChangeNotification";
NSString * const DPDataSetUpdatedNotification = @"DataSetUpdatedNotification";

NSString * const AFSpeedsKey = @"Speeds";
NSString * const AFClickToMovePlayheadKey = @"ClickToMovePlayhead";
NSString * const AFRecordClickPosition = @"RecordClickPosition";
NSString * const AFClickSegments = @"ClickSegments";
NSString * const AFLogFilesDirectory = @"LogFilesDirectory";
NSString * const AFRandomSeedKey = @"RandomSeed";
NSString * const AFPauseWhileAnnotatingKey = @"PauseWhileAnnotating";
NSString * const AFShowPlayheadKey = @"ShowPlayhead";
NSString * const AFStepValueKey = @"StepValue";
NSString * const AFShowPopUpAnnotationsKey = @"ShowPopUpAnnotations";
NSString * const AFSaveInteractionsKey = @"SaveInteractions";
NSString * const AFSaveTimePositionKey = @"SaveInteractionsTimePosition";
NSString * const AFSaveAnnotationEditsKey = @"SaveInteractionsAnnotationEdits";
NSString * const AFSaveVizConfigKey = @"SaveInteractionsState";
NSString * const AFUploadInteractionsKey = @"UploadInteractions";
NSString * const AFLastUploadKey = @"LastUpload";
NSString * const AFUserIdentifierKey = @"UserIdentifier";
NSString * const AFHierarchicalTimelinesKey = @"HierarchicalTimelines";
NSString * const AFFilterTimelinesKey = @"FilterTimelines";
NSString * const AFPlaybackRateKey = @"PlaybackRate";
NSString * const AFOpenVideosHalfSizeKey = @"OpenVideosHalfSize";
NSString * const AFAutomaticAnnotationFileKey = @"AutomaticAnnotationFile";
NSString * const AFUserIDKey = @"UserID";
NSString * const AFUserNameKey = @"UserName";
NSString * const AFAnnotationShortcutActionKey = @"AnnotationShortcutAction";
NSString * const AFTableEditActionKey = @"TableEditAction";
NSString * const AFMaxPlaybackRateKey = @"MaxPlaybackRate";
NSString * const AFCreateFileBackupKey = @"CreateFileBackup";
NSString * const AFDeleteFileBackupKey = @"DeleteFileBackup";
NSString * const AFOverwriteFileBackupKey = @"OverwriteFileBackup";
NSString * const AFUseQuickTimeXKey = @"UseQuickTimeX";
NSString * const AFUseStaticMapKey = @"UseStaticMap";
NSString * const AFEnableChronoVizRemoteKey = @"EnableChronoVizRemote";
NSString * const AFTrackActivityKey = @"TrackActivity";
NSString * const AFTimebaseKey = @"Timebase";

NSInteger const AFCategoryShortcutInsert = 0;
NSInteger const AFCategoryShortcutEditor = 1;
NSInteger const AFTableEditInline = 0;
NSInteger const AFTableEditExternal = 1;
