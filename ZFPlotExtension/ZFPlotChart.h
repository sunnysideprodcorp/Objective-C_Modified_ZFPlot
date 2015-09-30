//
//  ZFPlotChart.h
//
//  Created by Zerbinati Francesco
//  Copyright (c) 2014-2015
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#define COLOR_WITH_RGB(r,g,b)   [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1.0f] // Macro for colors

// Dimension constants
#define topMarginInterior       10.0f   // top margin for all plots, creating space between data and top of graph
#define leftMarginInterior      10.0f   // left margin for scatter plot, creating margin between points and y-axis
#define vMargin                 40.0f   // vertical margin
#define hMargin                 10.0f   // horizontal margin
#define leftSpace               10.0f   // left space, spacing to left outside of graph
#define intervalLinesHorizontal  5.0f   // number of intervals to plot
#define intervalLinesVertical    5.0f   // number of intervals to plot

// Formatting constants
#define valueDivider             1.0f   // division renormalization/unitization factor, can be set to 100 if prices are given in cents, for example
#define maxMinOffsetBuffer        .1f   // buffer around max and min value of y range
#define unitsOnRight             1.0f   // if 1, puts units to right of numbers, if 0 on left
#define minY                     0.0f   // min value to show on axes
#define maxY               1000000.0f   // max value to show on axes
#define stringOffset            15.0f   // offset strings left compared to points so strings are centered around point they label


// Bar plot additional parameters
#define percentDistBetweenBars   0.03f   // each bar will leave this percentage of its width empty on either side, set to 0 for bar plot with no spacing

// Line plot additional parameters
// none so far

// Scatter plot additional parameters
#define scatterCircleRadius      7.0f    // set radius for each point in scatter plot

// Graph grid color
#define linesColor              [UIColor lightGrayColor]

// Colors for lines and background
#define baseColor               [UIColor blueColor]
#define lowerGradientColor      COLOR_WITH_RGB(255, 255, 255)
#define whiteColor              [UIColor whiteColor]


// Fonts
#define systemFont              [UIFont systemFontOfSize:10]
#define boldFont                [UIFont boldSystemFontOfSize:10]

// definitions (as JSON)
#define fzPoint                  @"Point"
#define fzValue                  @"value"
#define fzXValue                  @"xValue"

@interface ZFPlotChart : UIView

// Overall plot properties
@property CGFloat chartType; // 0 = bar graph, 1 = line graph, 2 = scatter plot
@property CGFloat useDates; // are x-axis labels are 0 = data array indices, 1 = NSDates, 2 = actual numerical values
@property CGFloat stringOffsetHorizontal; // move x-axis strings to the left to recenter
@property BOOL gridLinesOn; // draw gridlines?

// Data to display and units to apply to the plotted y-axis values
@property (nonatomic, retain) NSString *units; // y value units
@property (nonatomic, retain) NSString *xUnits; // x value units, only used if useDates == 2
@property (nonatomic, retain) NSMutableOrderedSet *dictDispPoint; // an ordered set of key-value pairs with fields corresponding to constants fzValue and fzXValue

// Aesthetics
@property (nonatomic, strong) UIColor *baseColorProperty;
@property (nonatomic, strong) UIColor *lowerGradientColorProperty;
@property CGFloat scatterRadiusProperty;

// Animation
@property float timeBetweenPoints;
@property BOOL animatePlotDraw;

//Functions
- (void)createChartWith:(NSOrderedSet *)data; //set up plot with data after initialization

@end
