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
@property (weak) ZFPlotChart *chart;
@property (nonatomic, retain) NSMutableOrderedSet *dictDispPoint;
@property (nonatomic, readwrite) float min, max;
@property (nonatomic, readwrite) float yMax,yMin;
@property (nonatomic, readwrite) float xMax,xMin;
@property NSMutableArray *xBinsCoords;
@property NSMutableArray *xBinsLabels;
@property (nonatomic, retain) NSMutableArray *xIndices;
@property (nonatomic, retain) NSMutableArray *xClickIndices;

- (id) init;
-(int)count;
-(void) removeAllObjects;
- (void) addObject :(NSDictionary *)dictPoint;

- (float) convertXToGraphNumber: (float)xVal;
- (float) convertYToGraphNumber: (float)yVal;
- (NSDictionary *)objectAtIndex: (int) ind;
- (void) convertXMakeBins;
- (void) enumerateObjectsUsingBlock:(void(^)(id obj, NSUInteger ind, BOOL *stop))enumBlock;
@end
