//
//  ZFLine.h
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZFPlotChart.h"

@interface ZFLine : ZFPlotChart

@property (nonatomic, strong) UIColor *lowerGradientColorProperty;  // second color to use for drawing a gradient
@property BOOL useGradient;  // whether to draw a gradient under line/curve

@end
