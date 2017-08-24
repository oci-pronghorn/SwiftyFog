/*
 * WMGaugeView.h
 *
 * Copyright (C) 2014 William Markezana <william.markezana@me.com>
 *
 */

#import <UIKit/UIKit.h>

/**
 * Styling enumerations
 */
typedef NS_ENUM(NSInteger, WMGaugeViewSubdivisionsAlignment)
{
    WMGaugeViewSubdivisionsAlignmentTop,
    WMGaugeViewSubdivisionsAlignmentCenter,
    WMGaugeViewSubdivisionsAlignmentBottom
};

typedef NS_ENUM(NSInteger, WMGaugeViewNeedleStyle)
{
    WMGaugeViewNeedleStyle3D,
    WMGaugeViewNeedleStyleFlatThin
};

typedef NS_ENUM(NSInteger, WMGaugeViewNeedleScrewStyle)
{
    WMGaugeViewNeedleScrewStyleGradient,
    WMGaugeViewNeedleScrewStylePlain
};

typedef NS_ENUM(NSInteger, WMGaugeViewInnerBackgroundStyle)
{
    WMGaugeViewInnerBackgroundStyleGradient,
    WMGaugeViewInnerBackgroundStyleFlat
};

/**
 * WMGaugeView class
 */
IB_DESIGNABLE
@interface WMGaugeView : UIView

/**
 * WMGaugeView properties
 */
@property (nonatomic) IBInspectable BOOL showInnerBackground;
@property (nonatomic) IBInspectable BOOL showInnerRim;
@property (nonatomic) IBInspectable CGFloat innerRimWidth;
@property (nonatomic) IBInspectable CGFloat innerRimBorderWidth;
@property (nonatomic) WMGaugeViewInnerBackgroundStyle innerBackgroundStyle;

@property (nonatomic) IBInspectable CGFloat needleWidth;
@property (nonatomic) IBInspectable CGFloat needleHeight;
@property (nonatomic) IBInspectable CGFloat needleScrewRadius;
@property (nonatomic) WMGaugeViewNeedleStyle needleStyle;
@property (nonatomic) WMGaugeViewNeedleScrewStyle needleScrewStyle;

@property (nonatomic) IBInspectable CGFloat scalePosition;
@property (nonatomic) IBInspectable CGFloat scaleStartAngle;
@property (nonatomic) IBInspectable CGFloat scaleEndAngle;
@property (nonatomic) IBInspectable CGFloat scaleDivisions;
@property (nonatomic) IBInspectable CGFloat scaleSubdivisions;
@property (nonatomic) IBInspectable BOOL showScaleShadow;
@property (nonatomic) IBInspectable BOOL scaleIgnoreRangeColors;
@property (nonatomic) WMGaugeViewSubdivisionsAlignment scalesubdivisionsaligment;
@property (nonatomic) IBInspectable CGFloat scaleDivisionsLength;
@property (nonatomic) IBInspectable CGFloat scaleDivisionsWidth;
@property (nonatomic) IBInspectable CGFloat scaleSubdivisionsLength;
@property (nonatomic) IBInspectable CGFloat scaleSubdivisionsWidth;

@property (nonatomic) IBInspectable UIColor *scaleDivisionColor;
@property (nonatomic) IBInspectable UIColor *scaleSubDivisionColor;

@property (nonatomic) IBInspectable UIFont *scaleFont;


@property (nonatomic) IBInspectable float value;
@property (nonatomic) IBInspectable float minValue;
@property (nonatomic) IBInspectable float maxValue;

@property (nonatomic) IBInspectable BOOL showRangeLabels;
@property (nonatomic) IBInspectable CGFloat rangeLabelsWidth;
@property (nonatomic) IBInspectable UIFont *rangeLabelsFont;
@property (nonatomic) IBInspectable UIColor *rangeLabelsFontColor;
@property (nonatomic) IBInspectable CGFloat rangeLabelsFontKerning;

@property (nonatomic) NSArray<NSNumber*> *rangeValues;
@property (nonatomic) NSArray<UIColor*> *rangeColors;
@property (nonatomic) NSArray<NSString*> *rangeLabels;

@property (nonatomic) IBInspectable UIColor *unitOfMeasurementColor;
@property (nonatomic) IBInspectable CGFloat unitOfMeasurementVerticalOffset;
@property (nonatomic) IBInspectable UIFont *unitOfMeasurementFont;
@property (nonatomic) IBInspectable NSString *unitOfMeasurement;
@property (nonatomic) IBInspectable BOOL showUnitOfMeasurement;

@property (nonatomic) IBInspectable NSInteger innerBackgroundStyleNum;
@property (nonatomic) IBInspectable NSInteger needleStyleNum;
@property (nonatomic) IBInspectable NSInteger needleScrewStyleNum;
@property (nonatomic) IBInspectable NSInteger scalesubdivisionsaligmentNum;

/**
 * WMGaugeView public functions
 */
- (void)setValue:(float)value animated:(BOOL)animated;
- (void)setValue:(float)value animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;
- (void)setValue:(float)value animated:(BOOL)animated duration:(NSTimeInterval)duration;
- (void)setValue:(float)value animated:(BOOL)animated duration:(NSTimeInterval)duration completion:(void (^)(BOOL finished))completion;

@end
