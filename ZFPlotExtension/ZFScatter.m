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

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.convertX = TRUE;
    }
    return self;
}


- (float) gapBetweenPoints: (NSMutableOrderedSet *)orderSet{
    return 0.0;
}

- (float) returnX : (float) toAdd  {
    return leftMarginInterior;
}


- (NSMutableOrderedSet *) orderIndicesSetLimits: (NSMutableOrderedSet *) orderSet{
    self.xIndices = [[NSMutableArray alloc] init];
    
    // Reorder points from left to right for scatter plot
    NSMutableArray *reorderSet = [[orderSet array] mutableCopy];
    NSSortDescriptor *xDescriptor = [[NSSortDescriptor alloc] initWithKey:fzXValue ascending:YES];
    [reorderSet sortUsingDescriptors:@[xDescriptor]];
    orderSet = [[NSOrderedSet orderedSetWithArray:reorderSet] mutableCopy];
    
    // Get min and max x values for scaling to fit all points on scatter plot
    self.dictDispPoint.xMax = [[[orderSet valueForKey:fzXValue] valueForKeyPath:@"@max.floatValue"] floatValue]*(1+maxMinOffsetBuffer);
    self.dictDispPoint.xMin = [[[orderSet valueForKey:fzXValue] valueForKeyPath:@"@min.floatValue"] floatValue] - maxMinOffsetBuffer*self.dictDispPoint.xMax;
    return orderSet;
}

- (void) drawPoints {
    //Draw points
    [self.dictDispPoint enumerateObjectsUsingBlock:^(id obj, NSUInteger ind, BOOL *stop){
        if(ind > 0)
        {
            self.prevPoint = [[[self.dictDispPoint objectAtIndex:ind-1] valueForKey:fzPoint] CGPointValue];
            self.curPoint = [[[self.dictDispPoint objectAtIndex:ind] valueForKey:fzPoint] CGPointValue];
        }
        else
        {
            // first point
            self.prevPoint = [[[self.dictDispPoint objectAtIndex:ind] valueForKey:fzPoint] CGPointValue];
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


- (void)drawVertical{
    
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


- (BOOL) goodPointSlot : (int) pointSlot{
    return (pointSlot < [self.dictDispPoint count] && [self.alreadyIncluded[pointSlot] boolValue]);
}


# pragma mark - inclusion array for animation

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


- (NSString *) getStringForLabel : (NSDictionary *)dict {
    float value = [[dict objectForKey:fzValue] floatValue]/valueDivider;
    float xValue = [[dict objectForKey:fzXValue] floatValue];
    return  [NSString formatPairNumberX:xValue andNumberY:value withFractionDigits:1 withUnits:self.units withXUnits:self.xUnits];
}


- (void) convertXMakeBins {
    self.dictDispPoint.xBinsCoords = [[NSMutableArray alloc] init];
    
    CGFloat linesRatio;
    if([self.dictDispPoint count] < intervalLinesVertical + 1){
        linesRatio = [self.dictDispPoint count]/MAX((signed)([self.dictDispPoint count]-1), 1);
    }
    else    linesRatio  = [self.dictDispPoint count]/intervalLinesVertical ;
    
    self.dictDispPoint.xBinsLabels = [[NSMutableArray alloc] init];
    int i = 1;
    float x;
    while(i <= intervalLinesVertical ){
        x =  [self convertXToGraphNumber:self.dictDispPoint.xMin +  i*(self.dictDispPoint.xMax - self.dictDispPoint.xMin)/intervalLinesVertical];
        
        //xScaledDiff = xScaledMin + i*xWidthBins;
        [self.dictDispPoint.xBinsCoords addObject: [NSNumber numberWithFloat:x]];
        [self.dictDispPoint.xBinsLabels addObject:[NSString stringWithFormat:@"%.01f", (self.dictDispPoint.xMin + i*(self.dictDispPoint.xMax - self.dictDispPoint.xMin)/intervalLinesVertical)]];
        i++;
    }
    
    if(self.xIndices.count > 2){
        self.xClickIndices = [[NSMutableArray alloc] init];
        CGFloat calcMean;
        for(int i = 0; i < (signed)self.xIndices.count - 1; i++){
            calcMean = ([self.xIndices[i] floatValue] + [self.xIndices[i+1] floatValue])/2;
            [self.xClickIndices addObject:[NSNumber numberWithFloat:calcMean]];
        }
        [self.xClickIndices addObject:[NSNumber numberWithFloat:self.chartWidth + self.leftMargin + leftMarginInterior*2]];
    }
    else self.xClickIndices = self.xIndices;
    
    // Scatter plot movement option requires ordered list of x coordinates
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [self.xIndices sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
    [self.dictDispPoint.xBinsCoords sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
}

@end
