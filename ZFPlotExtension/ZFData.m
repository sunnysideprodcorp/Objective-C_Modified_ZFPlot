//
//  ZFData.m
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import "ZFData.h"
#import "ZFPlotChart.h"
#import "ZFString.h"

@implementation ZFData

# pragma mark Initialization

- (id) init {
    self = [super init];
    if(self){
        self.dictDispPoint = [[NSMutableOrderedSet alloc] initWithCapacity:0];
        self.xBinsLabels = [[NSMutableArray alloc] init];
        self.xBinsCoords = [[NSMutableArray alloc] init];
        self.xIndices = [[NSMutableArray alloc] init];
        self.xClickIndices = [[NSMutableArray alloc] init];

    }
    return self;
}

# pragma mark Wrapper functions for ordered set property dictDispPoint

-(int)count{
    return (int)self.dictDispPoint.count;
}

-(void) removeAllObjects{
    [self.dictDispPoint removeAllObjects];
}

- (void) addObject :(NSDictionary *)dictPoint {
    [self.dictDispPoint addObject:dictPoint];
}

- (void) enumerateObjectsUsingBlock:(void(^)(id obj, NSUInteger ind, BOOL *stop))enumBlock{
    [self.dictDispPoint enumerateObjectsUsingBlock:enumBlock];
}

- (NSDictionary *)objectAtIndex: (int) ind {
    return [self.dictDispPoint objectAtIndex:ind];
}

#pragma mark Data converstion for proper display on chart

- (float) convertXToGraphNumber: (float)xVal{
    CGFloat xDiff = self.xMax - xVal;
    CGFloat xRange = self.xMax - self.xMin;
    return (self.chart.chartWidth)*(1-xDiff/xRange) + self.chart.leftMargin;
}

- (float) convertYToGraphNumber: (float)yVal{
    float diff = self.max-yVal;
    float range = self.max - self.min;
    return ((self.chart.chartHeight*diff)/range + topMarginInterior);
}

- (void) convertXMakeBins {
    self.xBinsCoords = [[NSMutableArray alloc] init];
    
    CGFloat linesRatio;
    if([self.dictDispPoint count] < intervalLinesVertical + 1){
        linesRatio = [self.dictDispPoint count]/MAX((signed)([self.dictDispPoint count]-1), 1);
    }
    else    linesRatio  = [self.dictDispPoint count]/intervalLinesVertical ;
    
    self.xBinsLabels = [[NSMutableArray alloc] init];
    int i = 1;
    float x;
    while(i <= intervalLinesVertical ){
        x =  [self convertXToGraphNumber:self.xMin +  i*(self.xMax - self.xMin)/intervalLinesVertical];
        [self.xBinsCoords addObject: [NSNumber numberWithFloat:x]];
        [self.xBinsLabels addObject:[NSString stringWithFormat:@"%.01f", (self.xMin + i*(self.xMax - self.xMin)/intervalLinesVertical)]];
        i++;
    }
    
    if(self.xIndices.count > 2){
        self.xClickIndices = [[NSMutableArray alloc] init];
        CGFloat calcMean;
        for(int i = 0; i < (signed)self.xIndices.count - 1; i++){
            calcMean = ([self.xIndices[i] floatValue] + [self.xIndices[i+1] floatValue])/2;
            [self.xClickIndices addObject:[NSNumber numberWithFloat:calcMean]];
        }
        [self.xClickIndices addObject:[NSNumber numberWithFloat:self.chart.chartWidth + self.chart.leftMargin + leftMarginInterior*2]];
    }
    else self.xClickIndices = self.xIndices;
    
    // Scatter plot movement option requires ordered list of x coordinates
    NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
    [self.xIndices sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
    [self.xBinsCoords sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
}

-(NSString *) stringToUse:(NSInteger)ind withDates: (int)xAxisLabelType withXUnits: (NSString *)xUnits{
    if(xAxisLabelType == 0){
        return [NSString stringWithFormat:@"%ld", ind + 1];
    }
    else if(xAxisLabelType == 1){
        return [NSString stringMonthDayMonthDay: [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue]];
        
    }
    else{
        if(xUnits) return [NSString stringWithFormat:@"%@ %@", [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue], xUnits];
        else return [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue];
    }
    
}
    
    

@end
