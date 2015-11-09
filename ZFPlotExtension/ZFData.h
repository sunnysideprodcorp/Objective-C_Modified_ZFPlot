//
//  ZFData.h
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ZFPlotChart;

@interface ZFData : NSObject

/* Properties */

// keep a weak linker to chart parent to get physical dimensions for scaing
@property (weak) ZFPlotChart *chart;

// keep the data in a mutable ordered set
@property (nonatomic, retain) NSMutableOrderedSet *dictDispPoint;

// need max and min values for scaling
@property (nonatomic, readwrite) float min, max;
@property (nonatomic, readwrite) float yMax,yMin;
@property (nonatomic, readwrite) float xMax,xMin;

// these additional mutable arrays are used when x is scaled for a scatter plot
@property NSMutableArray *xBinsCoords;
@property NSMutableArray *xBinsLabels;
@property (nonatomic, retain) NSMutableArray *xIndices;
@property (nonatomic, retain) NSMutableArray *xClickIndices;

/* Functions */

// initialization
- (id) init;

// wrapper functions for ordered set property dictDispPoint
- (int)count;
- (void) removeAllObjects;
- (void) addObject :(NSDictionary *)dictPoint;
- (void) enumerateObjectsUsingBlock:(void(^)(id obj, NSUInteger ind, BOOL *stop))enumBlock;
- (NSDictionary *)objectAtIndex: (int) ind;

// data converstion for proper display on chart
// these functions use values read from self.chart
- (float) convertXToGraphNumber: (float)xVal;
- (float) convertYToGraphNumber: (float)yVal;
- (void) convertXMakeBins;
-(NSString *) stringToUse:(NSInteger)ind withDates: (int)xAxisLabelType withXUnits: (NSString *)xUnits;

@end
