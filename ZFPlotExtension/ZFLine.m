//
//  ZFLine.m
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import "ZFLine.h"
#import "ZFString.h"
@implementation ZFLine

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.lowerGradientColorProperty = lowerGradientColor;
        self.useGradient = TRUE;
    }
    return self;
}

- (void) drawPoints {
    /*** Draw points and vertical labels and lines as desired according to intervalLinesVertical constant ***/
    [self.dictDispPoint enumerateObjectsUsingBlock:^(id obj, NSUInteger ind, BOOL *stop){
        if(ind > 0)     // all points but first in series
        {
            self.prevPoint = [[[self.dictDispPoint objectAtIndex:(int)ind-1] valueForKey:fzPoint] CGPointValue];
            self.curPoint = [[[self.dictDispPoint objectAtIndex:(int)ind] valueForKey:fzPoint] CGPointValue];
        }
        else             // first point in series
        {
            self.prevPoint = [[[self.dictDispPoint objectAtIndex:(int)ind] valueForKey:fzPoint] CGPointValue];
            self.curPoint = self.prevPoint;
        }
        // line style
        [self.draw setContextWidth:1.5f andColor:self.baseColorProperty];
        // draw the curve
        if(ind < self.countDown) [self.draw drawCurveFrom:self.prevPoint to:self.curPoint];
        [self.draw endContext];
        
        long linesRatio;
        if([self.dictDispPoint count] < intervalLinesVertical + 1){
            linesRatio = [self.dictDispPoint count]/MAX(([self.dictDispPoint count]-1), 1);
        }
        else    linesRatio  = [self.dictDispPoint count]/intervalLinesVertical ;
        
        if(ind%linesRatio == 0) {
            [self.draw setContextWidth:0.5f andColor:linesColor];
            // Vertical Lines
            if(ind!=0) {
                CGPoint lower = CGPointMake(self.curPoint.x, topMarginInterior+self.chartHeight);
                CGPoint higher = CGPointMake(self.curPoint.x, topMarginInterior);
                if(self.gridLinesOn) [self.draw drawLineFrom:lower to: higher];
            }
            [self.draw endContext];
            
            // x-axis labels
            CGPoint datePoint = CGPointMake(self.curPoint.x-15, topMarginInterior + self.chartHeight + 2);
            if(self.xAxisLabelType == 0){
                [self.draw drawString:[NSString stringWithFormat:@"%d", (int)ind] at:datePoint withFont:systemFont andColor:linesColor];
            }
            else if(self.xAxisLabelType == 1){
                NSString* date = [NSString stringMonthDayMonthDay: [[self.dictDispPoint objectAtIndex:(int)ind] valueForKey:fzXValue]];
                [self.draw drawString:date at:datePoint withFont:systemFont andColor:linesColor];
            }
            else{
                NSString *xUse;
                if(self.xUnits) xUse = [NSString stringWithFormat:@"%@ %@", [[self.dictDispPoint objectAtIndex:(int)ind] valueForKey:fzXValue], self.xUnits];
                else xUse = [[self.dictDispPoint objectAtIndex:(int)ind] valueForKey:fzXValue];
                [self.draw drawString: xUse at:datePoint withFont:systemFont andColor:linesColor];
            }
            [self.draw endContext];
        }
        
    }];
}

- (void) drawSpecial{
    // draws the gradient under the line if desired
    
    if(!self.useGradient) return;
    
    // gradient's path
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPoint origin = CGPointMake((signed)self.leftMargin, (signed)(topMarginInterior+self.chartHeight));
    if (self.dictDispPoint && self.dictDispPoint.count > 0) {
        
        //origin
        CGPathMoveToPoint(path, nil, origin.x, origin.y);
        CGPoint p;
        for (int i = 0; i < self.dictDispPoint.count; i++) {
            p = [[[self.dictDispPoint objectAtIndex:i] valueForKey:fzPoint] CGPointValue];
            CGPathAddLineToPoint(path, nil, p.x, p.y);
        }
    }
    CGPathAddLineToPoint(path, nil, self.curPoint.x, topMarginInterior+self.chartHeight);
    CGPathAddLineToPoint(path, nil, origin.x,origin.y);
    
    // gradient
    if(self.countDown >= self.dictDispPoint.count)[self.draw gradientizefromPoint:CGPointMake(0, self.dictDispPoint.yMax) toPoint:CGPointMake(0, topMarginInterior+self.chartWidth) forPath:path forBaseColor:self.baseColorProperty forLowerGradientColorProperty:self.lowerGradientColorProperty ];
    
    CGPathRelease(path);
}

@end
