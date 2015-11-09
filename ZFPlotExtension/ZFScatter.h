//
//  ZFScatter.h
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZFPlotChart.h"

@interface ZFScatter : ZFPlotChart

-(void)drawScatter: (CGRect) rect;
- (NSMutableOrderedSet *) orderIndicesSetLimits: (NSMutableOrderedSet *) orderSet;
@end
