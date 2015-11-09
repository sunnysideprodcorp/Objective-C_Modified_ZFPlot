//
//  ZFScatter.m
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import "ZFScatter.h"
#import "ZFString.h"

@implementation ZFScatter

#pragma mark Initialize

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.convertX = TRUE;
        self.scatterRadiusProperty = scatterCircleRadius;
    }
    return self;
}

#pragma mark Calculate values to draw plot

- (float) gapBetweenPoints: (NSMutableOrderedSet *)orderSet{
    return 0.0;
}

- (float) returnX : (float) toAdd  {
    return leftMarginInterior;
}

- (NSString *) getStringForLabel : (NSDictionary *)dict {
    float value = [[dict objectForKey:fzValue] floatValue]/valueDivider;
    float xValue = [[dict objectForKey:fzXValue] floatValue];
    return  [NSString pairNumber:xValue andNumberY:value withFractionDigits:1 withUnits:self.units withXUnits:self.xUnits];
}

# pragma mark Draw plot

- (void) drawPoints {
    // Draw points and then call separate class method to draw the vertical grid lines and x-axis labels
    [self.dictDispPoint enumerateObjectsUsingBlock:^(id obj, NSUInteger ind, BOOL *stop){
        if(ind > 0)
        {
            self.prevPoint = [[[self.dictDispPoint objectAtIndex:(int)ind-1] valueForKey:fzPoint] CGPointValue];
            self.curPoint = [[[self.dictDispPoint objectAtIndex:(int)ind] valueForKey:fzPoint] CGPointValue];
        }
        else
        {
            // first point
            self.prevPoint = [[[self.dictDispPoint objectAtIndex:(int)ind] valueForKey:fzPoint] CGPointValue];
            self.curPoint = self.prevPoint;
        }
        
        // line style
        [self.draw setContextWidth:1.5f andColor:self.baseColorProperty];
        
        // draw the curve
        CGPoint circlePoint = CGPointMake(self.curPoint.x, self.curPoint.y);
        CGFloat randNumber = arc4random_uniform((int)self.dictDispPoint.count);
        
        if(![self.alreadyIncluded[ind] boolValue]){
            if(randNumber < self.countDown){
                [self.alreadyIncluded setObject:[NSNumber numberWithBool:YES] atIndexedSubscript:ind];
            }
        }
        if([self.alreadyIncluded[ind] boolValue])[self.draw drawCircleAt:circlePoint ofRadius:self.scatterRadiusProperty];
        [self.draw endContext];
    }];
    [self drawVertical];
}

- (void)drawVertical{
    // draw vertical lines and labels. since these are not related to (scaled) x values for this data, they're drawn separately from the data
    for(NSUInteger i = 0; i < self.dictDispPoint.xBinsLabels.count; i++){
        // Labels
        CGFloat xPoint = [self.dictDispPoint.xBinsCoords[i] floatValue];
        CGPoint datePoint = CGPointMake(xPoint - self.stringOffsetHorizontal, topMarginInterior + self.chartHeight + 2);
        [self.draw drawString: self.dictDispPoint.xBinsLabels[i] at:datePoint withFont:systemFont andColor:linesColor];
        [self.draw endContext];
        [self.draw setContextWidth:0.5f andColor:linesColor];
        
        // Vertical Lines
        CGPoint lower = CGPointMake(xPoint, topMarginInterior+self.chartHeight);
        CGPoint higher = CGPointMake(xPoint, topMarginInterior);
        if(self.gridLinesOn) [self.draw drawLineFrom:lower to: higher];
    }
    [self.draw endContext];
}

#pragma mark - Reorder x data

- (NSMutableOrderedSet *) orderIndicesSetLimits: (NSMutableOrderedSet *) orderSet{
    // reorder orderSet and return it so values are in order according to x-axis value
    NSMutableArray *reorderSet = [[orderSet array] mutableCopy];
    NSSortDescriptor *xDescriptor = [[NSSortDescriptor alloc] initWithKey:fzXValue ascending:YES];
    [reorderSet sortUsingDescriptors:@[xDescriptor]];
    orderSet = [[NSOrderedSet orderedSetWithArray:reorderSet] mutableCopy];

    // Get min and max x values for scaling to fit all points on scatter plot
    self.dictDispPoint.xMax = [[[orderSet valueForKey:fzXValue] valueForKeyPath:@"@max.floatValue"] floatValue]*(1+maxMinOffsetBuffer);
    self.dictDispPoint.xMin = [[[orderSet valueForKey:fzXValue] valueForKeyPath:@"@min.floatValue"] floatValue] - maxMinOffsetBuffer*self.dictDispPoint.xMax;
    return orderSet;
}

#pragma mark Touch-related utilities

- (int) getPointSlot{
    return (int)[self.dictDispPoint.xClickIndices
                            indexOfObject:[NSNumber numberWithFloat: self.currentLoc.x + self.leftMargin ]
                            inSortedRange:NSMakeRange(0, [self.dictDispPoint.xIndices count])
                            options:NSBinarySearchingInsertionIndex
                            usingComparator:^(id lhs, id rhs) {
                                return [lhs compare:rhs];
                            }
                ];
}

- (BOOL) goodPointSlot : (int) pointSlot{
    return (pointSlot < [self.dictDispPoint count] && [self.alreadyIncluded[pointSlot] boolValue]);
}

# pragma mark - Inclusion array for animation to determine which points are already shown

- (void)resetInclusionArray {
    self.alreadyIncluded = [[NSMutableArray alloc] init];
    for(int i = 0; i < (signed)self.dictDispPoint.count; i++){
        [self.alreadyIncluded addObject:[NSNumber numberWithBool:NO]];
    }
}

- (void) allTrueInclusionArray {
    self.alreadyIncluded = [[NSMutableArray alloc] init];
    for(int i = 0; i < (signed)self.dictDispPoint.count; i++){
        [self.alreadyIncluded addObject:[NSNumber numberWithBool:YES]];
    }
}




@end
