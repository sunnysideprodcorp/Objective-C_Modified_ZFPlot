//
//  ZFScatter.m
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import "ZFScatter.h"



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
    self.xMax = [[[orderSet valueForKey:fzXValue] valueForKeyPath:@"@max.floatValue"] floatValue]*(1+maxMinOffsetBuffer);
    self.xMin = [[[orderSet valueForKey:fzXValue] valueForKeyPath:@"@min.floatValue"] floatValue] - maxMinOffsetBuffer*self.xMax;
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
        [self setContextWidth:1.5f andColor:self.baseColorProperty];
        
        // draw the curve
        CGPoint circlePoint = CGPointMake(self.curPoint.x, self.curPoint.y);
        CGFloat randNumber = arc4random_uniform((int)self.dictDispPoint.count);
        
        if(![self.alreadyIncluded[ind] boolValue]){
            if(randNumber < self.countDown){
                [self.alreadyIncluded setObject:[NSNumber numberWithBool:YES] atIndexedSubscript:ind];
            }
        }
        
        if([self.alreadyIncluded[ind] boolValue])[self drawCircleAt:circlePoint ofRadius:self.scatterRadiusProperty];
        [self endContext];
        
    }];

    [self drawVertical];
}

- (int) getPointSlot{
    return (int)[self.xClickIndices
                            indexOfObject:[NSNumber numberWithFloat: self.currentLoc.x + self.leftMargin ]
                            inSortedRange:NSMakeRange(0, [self.xIndices count])
                            options:NSBinarySearchingInsertionIndex
                            usingComparator:^(id lhs, id rhs) {
                                return [lhs compare:rhs];
                            }
                            ];
}


- (void)drawVertical{
    
    for(NSUInteger i = 0; i < self.xBinsLabels.count; i++){
        // Labels
        CGFloat xPoint = [self.xBinsCoords[i] floatValue];
        CGPoint datePoint = CGPointMake(xPoint - self.stringOffsetHorizontal, topMarginInterior + self.chartHeight + 2);
        [self drawString: self.xBinsLabels[i] at:datePoint withFont:systemFont andColor:linesColor];
        [self endContext];
        [self setContextWidth:0.5f andColor:linesColor];
        
        // Vertical Lines
        CGPoint lower = CGPointMake(xPoint, topMarginInterior+self.chartHeight);
        CGPoint higher = CGPointMake(xPoint, topMarginInterior);
        if(self.gridLinesOn) [self drawLineFrom:lower to: higher];
    }
    
    [self endContext];
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

@end
