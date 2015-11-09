//
//  ViewController.h
//  ZFPlotChart
//
//  Created by Francesco Zerbinati on 21/06/15.
//  Copyright (c) 2015 Francesco Zerbinati. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZFPlotChart.h"
#import "ZFScatter.h"
#import "ZFBar.h"
#import "ZFLine.h"

@interface ViewController : UIViewController

@property (strong, nonatomic) ZFPlotChart *distancePlot;
@property (strong, nonatomic) ZFPlotChart *timePlot;
@property (strong, nonatomic) ZFPlotChart *ratePlot;

@property (strong, nonatomic) NSString *distanceUnits;
@property (strong, nonatomic) NSString *timeUnits;
@property (strong, nonatomic) NSString *rateUnits;

@property (strong, nonatomic) NSOrderedSet *distancePoints;
@property (strong, nonatomic) NSOrderedSet *timePoints;
@property (strong, nonatomic) NSOrderedSet *ratePoints;

@end

