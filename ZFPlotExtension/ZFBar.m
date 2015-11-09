//
//  ZFBar.m
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import "ZFBar.h"

@implementation ZFBar

- (void) drawPoints {
    /*** Draw points ***/
    [self.dictDispPoint enumerateObjectsUsingBlock:^(id obj, NSUInteger ind, BOOL *stop){
        if(ind > 0)
        {
            self.prevPoint = [[[self.dictDispPoint objectAtIndex:ind-1] valueForKey:fzPoint] CGPointValue];
            self.curPoint = [[[self.dictDispPoint objectAtIndex:ind] valueForKey:fzPoint] CGPointValue];
        }
        else
        {
            // First point in ordered data
            self.prevPoint = [[[self.dictDispPoint objectAtIndex:ind] valueForKey:fzPoint] CGPointValue];
            self.curPoint = self.prevPoint;
        }
        
        NSLog(@"for a char of width: %f we have unit width %f with a count of %d", self.chartWidth, self.xUnitWidth, self.dictDispPoint.count);

        
        // Draw the rectangle for this data point
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGRect boxChartFrame = CGRectMake(self.curPoint.x - (.5 - percentDistBetweenBars)*self.xUnitWidth + .5*self.xUnitWidth, self.curPoint.y, (1-2*percentDistBetweenBars)*self.xUnitWidth, self.chartHeight+topMarginInterior - self.curPoint.y );
        
        
        
        if(ind < self.countDown) [self drawRoundedRect:context rect: boxChartFrame radius:.05 color:self.baseColorProperty];
        
        [self endContext];

            long linesRatio;
            if((signed)[self.dictDispPoint count] < intervalLinesVertical + 1  ) linesRatio = [self.dictDispPoint count]/MAX((signed)([self.dictDispPoint count]-1), 1);
            else    linesRatio  = [self.dictDispPoint count]/intervalLinesVertical ;
        
            
            
            if(ind%linesRatio == 0) {
                // draw x-axis values
                CGPoint datePoint = CGPointMake(boxChartFrame.origin.x + boxChartFrame.size.width/2 - self.stringOffsetHorizontal, topMarginInterior + self.chartHeight + 2);
                
                NSString *stringToUse = [self stringToUse: ind];
                
                [self drawString: stringToUse at:datePoint withFont:systemFont andColor:linesColor];
                [self endContext];
            }
    }];
    }
     
     

- (CGPoint) getPointForPointSlot:(int)pointSlot{
    NSDictionary *dict = [self.dictDispPoint objectAtIndex:pointSlot];
    
    return CGPointMake([[dict valueForKey:fzPoint] CGPointValue].x + self.xUnitWidth/2,[[dict valueForKey:fzPoint] CGPointValue].y);
}


- (float) gapBetweenPoints: (NSMutableOrderedSet *)orderSet{
    return self.chartWidth/MAX((signed)([orderSet count] + 1), 1);
}


- (float) returnX : (float) toAdd {
    return self.leftMargin + toAdd/2;
}



@end