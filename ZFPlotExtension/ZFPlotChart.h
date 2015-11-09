//
//  ZFPlotChart.h
//
//  Created by Zerbinati Francesco
//  Copyright (c) 2014-2015
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ZFDrawingUtility.h"
#import "ZFData.h"
#import "ZFConstants.h"

@interface ZFPlotChart : UIView

// Overall plot properties
@property CGFloat xAxisLabelType; // are x-axis labels are 0 = data array indices, 1 = NSDates, 2 = actual numerical values
@property BOOL convertX;    // when true, x values are scaled rather than equally spaced, set TRUE for scatter plot only
@property BOOL gridLinesOn; // draw gridlines?
@property (nonatomic, strong) UIColor *baseColorProperty;
@property CGFloat xUnitWidth;

// Data to display and units to apply to the plotted y-axis values
@property CGFloat stringOffsetHorizontal; // move x-axis strings to the left to recenter
@property (nonatomic, retain) NSString *units; // y value units
@property (nonatomic, retain) NSString *xUnits; // x value units, only used if xAxisLabelType == 2

// Data controller
@property ZFData* dictDispPoint; // an ordered set of key-value pairs with fields corresponding to constants fzValue and fzXValue

// Drawing controller
@property ZFDrawingUtility *draw;

// Animation
@property float timeBetweenPoints;
@property BOOL animatePlotDraw;
@property int countDown;
@property NSMutableArray *alreadyIncluded;

// Layout properties for plotting the view
@property (nonatomic, readwrite) float chartWidth, chartHeight;
@property (nonatomic, readwrite) float leftMargin;

// Tracking all points in data as they are iterated over
@property (nonatomic, readwrite) CGPoint prevPoint, curPoint, currentLoc;
@property BOOL isMovement;

// Show when data is loading or missing
@property (strong) UIActivityIndicatorView *loadingSpinner;

//Functions
- (void)createChartWith:(NSOrderedSet *)data; //set up plot with data after initialization
- (void)drawSpecial;
- (int)getPointSlot;
- (BOOL) goodPointSlot : (int) pointSlot;

@end
