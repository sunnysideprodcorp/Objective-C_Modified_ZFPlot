//
//  ZFPlotChart.m
//
//  Created by Zerbinati Francesco
//  Copyright (c) 2014-2015
//
//  Modified by Sunnyside Productions September 2015

#import "ZFPlotChart.h"

@interface ZFPlotChart ()
@property CGFloat xUnitWidth;
@property NSMutableArray *xBinsCoords;
@property NSMutableArray *xBinsLabels;

// Tracking range of y-axis data
@property (nonatomic, readwrite) float min, max;
@property (nonatomic, readwrite) float yMax,yMin;

// Layout properties for plotting the view
@property (nonatomic, readwrite) float chartWidth, chartHeight;
@property (nonatomic, readwrite) float leftMargin;

// Tracking all points in data as they are iterated over
@property (nonatomic, readwrite) CGPoint prevPoint, curPoint, currentLoc;

// Use for scatter plot option to label x-axis and do appropriate x-axis spacing
@property (nonatomic, retain) NSMutableArray *xIndices;
@property (nonatomic, retain) NSMutableArray *xClickIndices;
@property (nonatomic, readwrite) float xMin, xMax;

// Show when data is loading or missing
@property (strong) UIActivityIndicatorView *loadingSpinner;

// Track when user is touching plot
@property BOOL isMovement;

// Animation countdown
@property int countDown;
@property NSMutableSet *includedIndices;
@end


@implementation ZFPlotChart

#pragma mark - Initialization/LifeCycle Method
- (id)initWithFrame:(CGRect)frame
{
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        @try {
            
            self.baseColorProperty = baseColor;
            self.lowerGradientColorProperty = lowerGradientColor;
            self.scatterRadiusProperty = scatterCircleRadius;
            self.stringOffsetHorizontal = stringOffset;
            self.gridLinesOn = YES;
            self.animatePlotDraw = YES;
            self.timeBetweenPoints = .3;
        
            
            [self setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
            [self setAutoresizesSubviews:YES];
            
            self.backgroundColor = whiteColor;

            
            self.chartHeight = frame.size.height - vMargin;
            self.chartWidth = frame.size.width - hMargin;
            
            self.isMovement = NO;
            
            self.dictDispPoint = [[NSMutableOrderedSet alloc] initWithCapacity:0];
        }
        @catch (NSException *exception) {
            NSLog(@"%@",[exception debugDescription]);
        }
        @finally {
            
        }
    }
    return self;
}

#pragma mark - Chart Creation Method
- (void)createChartWith:(NSOrderedSet *)data
{
    
    [self.dictDispPoint removeAllObjects];
    
    NSMutableOrderedSet *orderSet = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    
    // Add data to the orderSet
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger ind, BOOL *stop){
        [orderSet addObject:obj];
    }];
    
    // Scatter plot additional settings
    if(self.chartType == 2.0){
        
        self.xIndices = [[NSMutableArray alloc] init];
        
        // Reorder points from left to right for scatter plot
        NSMutableArray *reorderSet = [[orderSet array] mutableCopy];
        NSSortDescriptor *xDescriptor = [[NSSortDescriptor alloc] initWithKey:fzXValue ascending:YES];
        [reorderSet sortUsingDescriptors:@[xDescriptor]];
        orderSet = [[NSOrderedSet orderedSetWithArray:reorderSet] mutableCopy];
        
        // Get min and max x values for scaling to fit all points on scatter plot
        self.xMax = [[[orderSet valueForKey:fzXValue] valueForKeyPath:@"@max.floatValue"] floatValue]*(1+maxMinOffsetBuffer);
        self.xMin = [[[orderSet valueForKey:fzXValue] valueForKeyPath:@"@min.floatValue"] floatValue] - maxMinOffsetBuffer*self.xMax;
    }
    
    // Find Min & Max of Chart
    self.max = [[[orderSet valueForKey:fzValue] valueForKeyPath:@"@max.floatValue"] floatValue];
    self.min = [[[orderSet valueForKey:fzValue] valueForKeyPath:@"@min.floatValue"] floatValue];
    
    // Enhance Upper & Lower Limit for Flexible Display, based on average of min and max
    self.max = ceilf((self.max+maxMinOffsetBuffer*self.max )/ 1)*1;
    self.min = floor((self.min-maxMinOffsetBuffer*self.max)/1)*1;
    self.max = MIN(maxY, self.max);
    self.min = MAX(minY, self.min);
    
    // Calculate left space given by the lenght of the string on the axis
    self.leftMargin = [self sizeOfString:[self formatNumberWithUnits:self.max/valueDivider withFractionDigits:1] withFont:systemFont].width + leftSpace;
    
    self.chartWidth-= self.leftMargin;
    float range = self.max-self.min;
    
    // Calculate x-axis point locations accordig to line chart type
    float xGapBetweenTwoPoints,  x , y;
    
    // Bar chart
    if(self.chartType == 0.0) {
        xGapBetweenTwoPoints = self.chartWidth/MAX((signed)([orderSet count] + 1), 1);
        x = self.leftMargin + xGapBetweenTwoPoints/2;
    }
    // Line chart
    else if(self.chartType == 1.0){
        xGapBetweenTwoPoints = self.chartWidth/MAX((signed)([orderSet count] - 1), 1);
        x = self.leftMargin;
    }
    // Scatter plot
    else {
        xGapBetweenTwoPoints = 0;
        x = leftMarginInterior;//self.leftMargin;
    }
    self.xUnitWidth = xGapBetweenTwoPoints;

    // Parameters to calculate y-axis positions
    y = topMarginInterior;
    self.yMax = self.yMin;
    
    float xDiff, xRange, xVal;
    xRange = self.xMax - self.xMin;
    
    // Adding points to values
    for(NSDictionary *dictionary in orderSet)
    {
        if(self.chartType == 2.0) {
            x =  [self convertXToGraphNumber:[[dictionary valueForKey:fzXValue] floatValue]];
            [self.xIndices addObject:[NSNumber numberWithFloat:x]];
        }

        y = [self convertYToGraphNumber:[[dictionary valueForKey:fzValue] floatValue]];
        
        // Get max y value
        if(y > self.yMax) self.yMax = y;
        
        CGPoint point = CGPointMake(x,y);
        
        NSDictionary *dictPoint = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGPoint:point], fzPoint,
                                   [dictionary valueForKey:fzValue], fzValue,
                                   [dictionary valueForKey:fzXValue], fzXValue, nil];
        
        [self.dictDispPoint addObject:dictPoint];
        
        // For bar and line charts, x displacements are evenly spacedo on x-axis without regard to relative positions of "time" information in data object
        x+= xGapBetweenTwoPoints;
    }
    
    // More scatter plot book-keeping
    if(self.chartType == 2.0){
        
        self.xBinsCoords = [[NSMutableArray alloc] init];
        
        CGFloat linesRatio;
        if([self.dictDispPoint count] < intervalLinesVertical + 1){
            linesRatio = [self.dictDispPoint count]/MAX((signed)([self.dictDispPoint count]-1), 1);
        }
        else    linesRatio  = [self.dictDispPoint count]/intervalLinesVertical ;
        
        self.xBinsLabels = [[NSMutableArray alloc] init];
        int i = 1;
        while(i <= intervalLinesVertical ){
            x =  [self convertXToGraphNumber:self.xMin +  i*(self.xMax - self.xMin)/intervalLinesVertical];
            
            //xScaledDiff = xScaledMin + i*xWidthBins;
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
            [self.xClickIndices addObject:[NSNumber numberWithFloat:self.chartWidth + self.leftMargin + leftMarginInterior*2]];
        }
        else self.xClickIndices = self.xIndices;

        // Scatter plot movement option requires ordered list of x coordinates
        NSSortDescriptor *lowestToHighest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES];
        [self.xIndices sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];
        [self.xBinsCoords sortUsingDescriptors:[NSArray arrayWithObject:lowestToHighest]];

    }

    if(self.animatePlotDraw) [self startDrawingPaths];
    else{
        self.countDown = self.dictDispPoint.count + 1;
        [self setNeedsDisplay];
    }
}

#pragma mark - Drawing


- (void)startDrawingPaths
{
    self.includedIndices = [[NSMutableSet alloc] init];
    //draw the first path
    self.countDown = 0;
    [self setNeedsDisplay];
    
    //schedule redraws once per second
    [NSTimer scheduledTimerWithTimeInterval:self.timeBetweenPoints target:self selector:@selector(updateView:) userInfo:nil repeats:YES];
}

- (void)updateView:(NSTimer*)timer
{
    //increment the path counter
    self.countDown++;
    
    //tell the view to update
    [self setNeedsDisplay];
    
    //if we've drawn all our paths, stop the timer
    if(self.countDown >= self.dictDispPoint.count)
    {
        [timer invalidate];
    }
}



- (void)drawRect:(CGRect)rect
{

    // Bar chart
    if(self.chartType == 0.0){

        [self drawBarGraph:rect];
    }
    // Line chart
    else if(self.chartType == 1.0){

       // while(self.countDown > 0){
          //  [self performSelector:@selector(drawLineChart:) withObject:rect afterDelay:2.0];
            [self drawLineChart:rect];
         //   sleep(2);
        //}
    }
    // Scatter chart
    else if(self.chartType == 2.0){
        [self drawScatter:rect];
    
    }

}

#pragma mark - Specific graph type drawing

- (void)drawBarGraph:(CGRect) rect {
    @try
    {
        if([self.dictDispPoint count] > 0)
        {
            // remove loading animation
            [self stopLoading];
            
            float range = self.max-self.min;
            
            float intervalHlines = (self.chartHeight)/MIN(intervalLinesHorizontal, self.dictDispPoint.count - 1);    //5.0f;
            float intervalValues = range/MIN(intervalLinesHorizontal, self.dictDispPoint.count - 1);     //5.0f;
            
            // horizontal lines
            for(int i=intervalLinesHorizontal;i>0;i--)
            {
                [self setContextWidth:0.5f andColor:linesColor];
                
                CGPoint start = CGPointMake(self.leftMargin, self.chartHeight+topMarginInterior-i*intervalHlines);
                CGPoint end = CGPointMake(self.chartWidth+self.leftMargin, self.chartHeight+topMarginInterior-i*intervalHlines);
                
                // draw the line
                if(self.gridLinesOn) [self drawLineFrom:start to:end];
                
                // draw yVals on the axis
                NSString *yVal = [self formatNumberWithUnits:(self.min+i*intervalValues)/valueDivider withFractionDigits:1];
                
                CGPoint yValPoint = CGPointMake(self.leftMargin - [self sizeOfString:yVal withFont:systemFont].width - 5,(self.chartHeight+topMarginInterior-i*intervalHlines-6));
                [self drawString:yVal at:yValPoint withFont:systemFont andColor:linesColor];
                [self endContext];
                
            }
            
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
                
                // Draw the rectangle for this data point
                CGContextRef context = UIGraphicsGetCurrentContext();
                CGFloat deltaX = self.xUnitWidth * (ind + 1.5);
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
            
            //  X and Y axys
            
            [self setContextWidth:1.0f andColor:linesColor];
            
            //  y
            [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior) to:CGPointMake(self.leftMargin, self.chartHeight+topMarginInterior)];
            //  x
            [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior+self.chartHeight) to:CGPointMake(self.leftMargin+self.chartWidth, self.chartHeight+topMarginInterior)];
            
            // vertical closure
            CGPoint startLine = CGPointMake(self.leftMargin+self.chartWidth, topMarginInterior);
            CGPoint endLine = CGPointMake(self.leftMargin+self.chartWidth, topMarginInterior+self.chartHeight);
            [self drawLineFrom:startLine to:endLine];
            
            // horizontal closure
            [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior) to:CGPointMake(self.chartWidth+self.leftMargin, topMarginInterior)];
            
            [self endContext];
            
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            // popup when moving
            if(self.isMovement)
            {
                float xGapBetweenTwoPoints = self.chartWidth/[self.dictDispPoint count];
                NSUInteger pointSlot = self.currentLoc.x/xGapBetweenTwoPoints;
                
                if( pointSlot < [self.dictDispPoint count] && pointSlot < self.countDown)
                {

                    
                    NSDictionary *dict = [self.dictDispPoint objectAtIndex:pointSlot];
                    
                    // Calculate Point to draw Circle
                    CGPoint point = CGPointMake([[dict valueForKey:fzPoint] CGPointValue].x + self.xUnitWidth/2,[[dict valueForKey:fzPoint] CGPointValue].y);
                    
                    
                    [self setContextWidth:1.0f andColor:self.baseColorProperty];
                    
                    // Line at current Point
                    [self drawLineFrom:CGPointMake(point.x, topMarginInterior-10) to:CGPointMake(point.x, self.chartHeight+topMarginInterior)];
                    [self endContext];
                    
                    // Circle at point
                    [self setContextWidth:1.0f andColor:self.baseColorProperty];
                    [self drawCircleAt:point ofRadius:8];
                    
                    [self endContext];
                    
                    
                    // draw the dynamic value
                    
                    float value = [[dict objectForKey:fzValue] floatValue]/valueDivider;
                    NSString *yVal = [self formatNumberWithUnits:value withFractionDigits:2];
                    
                    CGSize yValSize = [self sizeOfString:yVal withFont:boldFont];
                    
                    CGRect yValRect = {point.x-yValSize.width/2, 2, yValSize.width + 10, yValSize.height +3};
                    
                    // if goes out on right
                    if(point.x+-yValSize.width/2+yValSize.width+12 > self.chartWidth+self.leftMargin)
                        yValRect.origin.x = self.chartWidth+self.leftMargin-yValSize.width-2;
                    // if goes out on left
                    if(yValRect.origin.x < self.leftMargin)
                        yValRect.origin.x = self.leftMargin-(self.leftMargin/2);
                    
                    // rectangle for the label
                    [self drawRoundedRect:context rect:yValRect radius:5 color:self.baseColorProperty];
                    // value string
                    [self drawString:yVal at:CGPointMake(yValRect.origin.x+(yValRect.size.width-yValSize.width)/2,yValRect.origin.y+1.0f) withFont:boldFont andColor:whiteColor];
                    
                    }
            }
        }
        else
        {
            // draw a loding spinner while loading the data
            [self drawLoading];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception debugDescription]);
    }
    @finally {
        
    }
    
}


- (void)drawScatter: (CGRect) rect {
    
    
    @try
    {
        if([self.dictDispPoint count] > 0)
        {
            // remove loading animation
            [self stopLoading];
            
            float range = self.max-self.min;
            
            float intervalHlines = (self.chartHeight)/MIN(intervalLinesHorizontal, self.dictDispPoint.count - 1);    //5.0f;
            float intervalValues = range/MIN(intervalLinesHorizontal, self.dictDispPoint.count - 1);     //5.0f;
            
            // horizontal lines
            for(int i=intervalLinesHorizontal;i>0;i--)
            {
                [self setContextWidth:0.5f andColor:linesColor];
                
                CGPoint start = CGPointMake(self.leftMargin, self.chartHeight+topMarginInterior-i*intervalHlines);
                CGPoint end = CGPointMake(self.chartWidth+self.leftMargin, self.chartHeight+topMarginInterior-i*intervalHlines);
                
                // draw the line
                if(self.gridLinesOn) [self drawLineFrom:start to:end];
                
                // draw yVals on the axis
                NSString *yVal = [self formatNumberWithUnits:(self.min+i*intervalValues)/valueDivider withFractionDigits:1];
                
                CGPoint yValPoint = CGPointMake(self.leftMargin - [self sizeOfString:yVal withFont:systemFont].width - 5,(self.chartHeight+topMarginInterior-i*intervalHlines-6));
                [self drawString:yVal at:yValPoint withFont:systemFont andColor:linesColor];
                [self endContext];
                
            }
        
        
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
                CGContextRef context = UIGraphicsGetCurrentContext();
                CGFloat deltaX = self.xUnitWidth * (ind + 1);
                CGPoint circlePoint = CGPointMake(self.curPoint.x, self.curPoint.y);
                CGFloat randNumber = arc4random_uniform(self.dictDispPoint.count);
            
                NSLog(@"here is the rand number %f and here is the cutoff %f", randNumber, self.countDown);
                if(randNumber < self.countDown)[self drawCircleAt:circlePoint ofRadius:self.scatterRadiusProperty];
                [self endContext];
                
            }];
       
        
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
        //}
        
        //  X and Y axys
        [self setContextWidth:1.0f andColor:linesColor];
        //  y
        [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior) to:CGPointMake(self.leftMargin, self.chartHeight+topMarginInterior)];
        //  x
        [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior+self.chartHeight) to:CGPointMake(self.leftMargin+self.chartWidth, self.chartHeight+topMarginInterior)];
        
        // vertical closure
        CGPoint startLine = CGPointMake(self.leftMargin+self.chartWidth, topMarginInterior);
        CGPoint endLine = CGPointMake(self.leftMargin+self.chartWidth, topMarginInterior+self.chartHeight);
        [self drawLineFrom:startLine to:endLine];
        
        // horizontal closure
        [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior) to:CGPointMake(self.chartWidth+self.leftMargin, topMarginInterior)];
        [self endContext];
        
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        // popup when moving
        if(self.isMovement)
        {
            

            NSUInteger pointSlot = [self.xClickIndices
                                    indexOfObject:[NSNumber numberWithFloat: self.currentLoc.x + self.leftMargin ]
                                    inSortedRange:NSMakeRange(0, [self.xIndices count])
                                    options:NSBinarySearchingInsertionIndex
                                    usingComparator:^(id lhs, id rhs) {
                                        return [lhs compare:rhs];
                                    }
                                    ];

            if(pointSlot >= 0 && pointSlot < [self.dictDispPoint count])
            {
                NSDictionary *dict = [self.dictDispPoint objectAtIndex:pointSlot];
                
                // Calculate Point to draw Circle
                CGPoint point = CGPointMake([[dict valueForKey:fzPoint] CGPointValue].x,[[dict valueForKey:fzPoint] CGPointValue].y);
                
                
                [self setContextWidth:1.0f andColor:self.baseColorProperty];
                
                // Line at current Point
                [self drawLineFrom:CGPointMake(point.x, topMarginInterior-10) to:CGPointMake(point.x, self.chartHeight+topMarginInterior)];
                [self endContext];
                
                // Circle at point
                [self setContextWidth:1.0f andColor:self.baseColorProperty];
                [self drawCircleAt:point ofRadius:8];
                
                [self endContext];
                
                
                // draw the dynamic value
                float value = [[dict objectForKey:fzValue] floatValue]/valueDivider;
                float xValue = [[dict objectForKey:fzXValue] floatValue];
                NSString *stringToUse = [self formatPairNumberX:xValue andNumberY:value withFractionDigits:1];
                
                
                CGSize yValSize = [self sizeOfString:stringToUse withFont:boldFont];
                
                CGRect yValRect = {point.x-yValSize.width/2, 2, yValSize.width + 10, yValSize.height +3};
                
                // if goes out on right
                if(point.x+-yValSize.width/2+yValSize.width+12 > self.chartWidth+self.leftMargin)
                    yValRect.origin.x = self.chartWidth+self.leftMargin-yValSize.width-2;
                // if goes out on left
                if(yValRect.origin.x < self.leftMargin)
                    yValRect.origin.x = self.leftMargin-(self.leftMargin/2);
                
                // rectangle for the label
                [self drawRoundedRect:context rect:yValRect radius:5 color:self.baseColorProperty];
                // value string
                

                
                [self drawString:stringToUse at:CGPointMake(yValRect.origin.x+(yValRect.size.width-yValSize.width)/2,yValRect.origin.y+1.0f) withFont:boldFont andColor:whiteColor];
                // [self drawString:yVal at:CGPointMake(yValRect.origin.x+(yValRect.size.width-yValSize.width)/2,yValRect.origin.y+1.0f) withFont:boldFont andColor:whiteColor];
                
            }
        }
    }
    else
    {
        // draw a loding spinner while loading the data
        [self drawLoading];
    }
    }
    @catch (NSException *exception) {
    NSLog(@"%@",[exception debugDescription]);
    }
    @finally {
        
    }

}

- (void)drawLineChart:(CGRect)rect{
    @try
    {
        if([self.dictDispPoint count] > 0)
        {
            // remove loading animation
            [self stopLoading];
            
            float range = self.max-self.min;
            
            float intervalHlines = (self.chartHeight)/MIN(intervalLinesHorizontal, self.dictDispPoint.count - 1);    //5.0f;
            float intervalValues = range/MIN(intervalLinesHorizontal, self.dictDispPoint.count - 1);     //5.0f;
            
            // horizontal lines
            for(int i=intervalLinesHorizontal;i>0;i--)
            {
                [self setContextWidth:0.5f andColor:linesColor];
                
                CGPoint start = CGPointMake(self.leftMargin, self.chartHeight+topMarginInterior-i*intervalHlines);
                CGPoint end = CGPointMake(self.chartWidth+self.leftMargin, self.chartHeight+topMarginInterior-i*intervalHlines);
                
                // draw the line
                if(self.gridLinesOn)[self drawLineFrom:start to:end];
                
                // draw yVals on the axis
                NSString *yVal = [self formatNumberWithUnits:(self.min+i*intervalValues)/valueDivider withFractionDigits:1];
                CGPoint yValPoint = CGPointMake(self.leftMargin - [self sizeOfString:yVal withFont:systemFont].width - 5,(self.chartHeight+topMarginInterior-i*intervalHlines-6));
                [self drawString:yVal at:yValPoint withFont:systemFont andColor:linesColor];
                [self endContext];
                
            }
            
            
            /*** Draw points ***/
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
                if(ind < self.countDown) [self drawCurveFrom:self.prevPoint to:self.curPoint];
                
                [self endContext];
                
                
                long linesRatio;
                
                if([self.dictDispPoint count] < intervalLinesVertical + 1){
                    linesRatio = [self.dictDispPoint count]/MAX(([self.dictDispPoint count]-1), 1);
                }
                else    linesRatio  = [self.dictDispPoint count]/intervalLinesVertical ;
                
                
                
                if(ind%linesRatio == 0) {
                    [self setContextWidth:0.5f andColor:linesColor];
                    // Vertical Lines
                    if(ind!=0) {
                        CGPoint lower = CGPointMake(self.curPoint.x, topMarginInterior+self.chartHeight);
                        CGPoint higher = CGPointMake(self.curPoint.x, topMarginInterior);
                        if(self.gridLinesOn) [self drawLineFrom:lower to: higher];
                    }
                    
                    [self endContext];
                    
                    // draw x-axis values
                    CGPoint datePoint = CGPointMake(self.curPoint.x-15, topMarginInterior + self.chartHeight + 2);
                    if(self.useDates == 0.0){
                        [self drawString:[NSString stringWithFormat:@"%d", ind] at:datePoint withFont:systemFont andColor:linesColor];
                    }
                    else if(self.useDates == 1.0){
                        NSString* date = [self dateFromString: [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue]];
                        [self drawString:date at:datePoint withFont:systemFont andColor:linesColor];
                    }
                    else{
                        NSString *xUse;
                        if(self.xUnits) xUse = [NSString stringWithFormat:@"%@ %@", [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue], self.xUnits];
                        else xUse = [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue];
                        [self drawString: xUse at:datePoint withFont:systemFont andColor:linesColor];
                    }
                    
                    [self endContext];
                    
                }
                
            }];
            
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
            if(self.countDown >= self.dictDispPoint.count - 1)[self gradientizefromPoint:CGPointMake(0, self.yMax) toPoint:CGPointMake(0, topMarginInterior+self.chartWidth) forPath:path];
            
            CGPathRelease(path);
            
            
            //  X and Y axis
            [self setContextWidth:1.0f andColor:linesColor];
            
            //  y
            [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior) to:CGPointMake(self.leftMargin, self.chartHeight+topMarginInterior)];
            //  x
            [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior+self.chartHeight) to:CGPointMake(self.leftMargin+self.chartWidth, self.chartHeight+topMarginInterior)];
            
            // vertical closure
            CGPoint startLine = CGPointMake(self.leftMargin+self.chartWidth, topMarginInterior);
            CGPoint endLine = CGPointMake(self.leftMargin+self.chartWidth, topMarginInterior+self.chartHeight);
            [self drawLineFrom:startLine to:endLine];
            
            // horizontal closure
            [self drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior) to:CGPointMake(self.chartWidth+self.leftMargin, topMarginInterior)];
            
            [self endContext];
            
            CGContextRef context = UIGraphicsGetCurrentContext();
            
            // popup when moving
            if(self.isMovement)
            {
                float xGapBetweenTwoPoints = self.chartWidth/[self.dictDispPoint count];
                int pointSlot = self.currentLoc.x/(signed)xGapBetweenTwoPoints;
                
                if(pointSlot >= 0 && pointSlot < [self.dictDispPoint count] && pointSlot < self.countDown)
                {
                    NSDictionary *dict = [self.dictDispPoint objectAtIndex:pointSlot];
                    
                    // Calculate Point to draw Circle
                    CGPoint point = CGPointMake([[dict valueForKey:fzPoint] CGPointValue].x,[[dict valueForKey:fzPoint] CGPointValue].y);
                    
                    // Line at current Point
                    [self setContextWidth:1.0f andColor:self.baseColorProperty];
                    [self drawLineFrom:CGPointMake(point.x, topMarginInterior-10) to:CGPointMake(point.x, self.chartHeight+topMarginInterior)];
                    [self endContext];
                    
                    // Circle at point
                    [self setContextWidth:1.0f andColor:self.baseColorProperty];
                    [self drawCircleAt:point ofRadius:8];
                    [self endContext];
                    
                    
                    // Draw the value corresponding to user touch
                    float value = [[dict objectForKey:fzValue] floatValue]/valueDivider;
                    NSString *yVal = [self formatNumberWithUnits:value withFractionDigits:2];
                    
                    CGSize yValSize = [self sizeOfString:yVal withFont:boldFont];
                    
                    CGRect yValRect = {point.x-yValSize.width/2, 2, yValSize.width + 10, yValSize.height +3};
                    
                    // if goes out on right
                    if(point.x+-yValSize.width/2+yValSize.width+12 > self.chartWidth+self.leftMargin)
                        yValRect.origin.x = self.chartWidth+self.leftMargin-yValSize.width-2;
                    // if goes out on left
                    if(yValRect.origin.x < self.leftMargin)
                        yValRect.origin.x = self.leftMargin-(self.leftMargin/2);
                    
                    // rectangle for the label
                    [self drawRoundedRect:context rect:yValRect radius:5 color:self.baseColorProperty];
                    // value string
                    [self drawString:yVal at:CGPointMake(yValRect.origin.x+(yValRect.size.width-yValSize.width)/2,yValRect.origin.y+1.0f) withFont:boldFont andColor:whiteColor];
                }
            }
        }
        ////
        else
        {
            // draw a loding spinner while loading the data
            [self drawLoading];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception debugDescription]);
    }
    @finally {
        
    }
    
}

#pragma mark - Graphic Utilities

-(void)drawLoading {
    self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.loadingSpinner startAnimating];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    self.loadingSpinner.center = CGPointMake(screenWidth/2, self.frame.size.height/2);
    self.loadingSpinner.hidesWhenStopped = YES;
    [self addSubview:self.loadingSpinner];
}

-(void)stopLoading {
    [self.loadingSpinner stopAnimating];
}

-(void)gradientizefromPoint:(CGPoint) startPoint toPoint:(CGPoint) endPoint forPath:(CGMutablePathRef) path{
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat redUpper, greenUpper, blueUpper, alpha;
    UIColor *baseColorUpper = self.baseColorProperty;
    [baseColorUpper getRed: &redUpper
                green: &greenUpper
                 blue: &blueUpper
                alpha: &alpha];

    
    CGFloat redLower, greenLower, blueLower;
    UIColor *baseColorLower = self.lowerGradientColorProperty;
    [baseColorLower getRed: &redLower
                green: &greenLower
                 blue: &blueLower
                alpha: &alpha];
    
    CGFloat colors [] = {
        redUpper, greenUpper, blueUpper, 0.9,  //darkblue
        redLower, greenLower, blueLower, 0.2,  // white clear
    };
    
    CGColorSpaceRef baseSpace = CGColorSpaceCreateDeviceRGB(); // gray colors want gray color space
    CGGradientRef gradient = CGGradientCreateWithColorComponents(baseSpace, colors, NULL, 2);
    CGColorSpaceRelease(baseSpace), baseSpace = NULL;
    
    CGContextSaveGState(context);
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    CGRect boundingBox = CGPathGetBoundingBox(path);
    CGPoint gradientStart = CGPointMake(0, CGRectGetMinY(boundingBox));
    CGPoint gradientEnd   = CGPointMake(0, CGRectGetMaxY(boundingBox));
    
    CGContextDrawLinearGradient(context, gradient, gradientStart, gradientEnd, 0);
    CGGradientRelease(gradient), gradient = NULL;
    CGContextRestoreGState(context);
   
}
-(void)drawMessage:(NSString*)string {
    
    float stringWidth = [self sizeOfString:string withFont:boldFont].width;
    [self drawString:string at:CGPointMake(self.center.x-stringWidth/2, self.center.y) withFont:boldFont andColor:linesColor];
}
// set the context with a specified widht and color
-(void) setContextWidth:(float)width andColor:(UIColor*)color {
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, width);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
}
// end context
-(void)endContext {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextStrokePath(context);
}
// line between two points
-(void) drawLineFrom:(CGPoint) start to: (CGPoint)end {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, start.x, start.y);
    CGContextAddLineToPoint(context,end.x,end.y);
    
}
// curve between two points
-(void) drawCurveFrom:(CGPoint)start to:(CGPoint)end {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, start.x, start.y);
    CGContextAddQuadCurveToPoint(context, start.x, start.y, end.x, end.y);
    CGContextSetLineCap(context, kCGLineCapRound);
}
// draws a string given a point, font and color
-(void) drawString:(NSString*)string at:(CGPoint)point withFont:(UIFont*)font andColor:(UIColor*)color{
    
    NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    [string drawAtPoint:point withAttributes:attributes];
}
// draw a circle given center and radius
-(void) drawCircleAt:(CGPoint)point ofRadius:(int)radius {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect myOval = {point.x-radius/2, point.y-radius/2, radius, radius};
    CGContextAddEllipseInRect(context, myOval);
    CGContextFillPath(context);
}
// rounded corners rectangle
- (void) drawRoundedRect:(CGContextRef)c rect:(CGRect)rect radius:(int)corner_radius color:(UIColor *)color
{
    int x_left = rect.origin.x;
    int x_left_center = rect.origin.x + corner_radius;
    int x_right_center = rect.origin.x + rect.size.width - corner_radius;
    int x_right = rect.origin.x + rect.size.width;
    
    int y_top = rect.origin.y;
    int y_top_center = rect.origin.y + corner_radius;
    int y_bottom_center = rect.origin.y + rect.size.height - corner_radius;
    int y_bottom = rect.origin.y + rect.size.height;
    
    /* Begin! */
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, x_left, y_top_center);
    
    /* First corner */
    CGContextAddArcToPoint(c, x_left, y_top, x_left_center, y_top, corner_radius);
    CGContextAddLineToPoint(c, x_right_center, y_top);
    
    /* Second corner */
    CGContextAddArcToPoint(c, x_right, y_top, x_right, y_top_center, corner_radius);
    CGContextAddLineToPoint(c, x_right, y_bottom_center);
    
    /* Third corner */
    CGContextAddArcToPoint(c, x_right, y_bottom, x_right_center, y_bottom, corner_radius);
    CGContextAddLineToPoint(c, x_left_center, y_bottom);
    
    /* Fourth corner */
    CGContextAddArcToPoint(c, x_left, y_bottom, x_left, y_bottom_center, corner_radius);
    CGContextAddLineToPoint(c, x_left, y_top_center);
    
    /* Done */
    CGContextClosePath(c);
    
    CGContextSetFillColorWithColor(c, color.CGColor);
    
    CGContextFillPath(c);
}
// size of a string given a specific font
-(CGSize) sizeOfString:(NSString *)string withFont:(UIFont *)font {
    NSDictionary *attributes = @{ NSFontAttributeName: font};
    return [string sizeWithAttributes:attributes];
}
#pragma mark - Graphic Routines from graphic utilities

-(NSString *) stringToUse:(NSInteger)ind {
    if(self.useDates == 0.0){
        return [NSString stringWithFormat:@"%ld", ind + 1];
    }
    else if(self.useDates == 1.0){
        return [self dateFromString: [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue]];
       
    }
    else{
        NSString *xUse;
        if(self.xUnits) return [NSString stringWithFormat:@"%@ %@", [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue], self.xUnits];
        else return [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue];
    }
    
}

#pragma mark - Graph conversion utilities
- (float) convertXToGraphNumber: (float)xVal{
    CGFloat xDiff = self.xMax - xVal;
    CGFloat xRange = self.xMax - self.xMin;
    return (self.chartWidth)*(1-xDiff/xRange) + self.leftMargin;
}


- (float) convertYToGraphNumber: (float)yVal{
    float diff = self.max-yVal;
    float range = self.max - self.min;
    return (self.chartHeight*diff)/range + topMarginInterior;
}

#pragma mark - String utilities

// format a string as a date (italian convention)
-(NSString*) dateFromString:(NSDate*) date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    NSInteger day = [components day];
    NSInteger month = [components month];
    
    return [NSString stringWithFormat:@"%d/%d", month, day];
}


#pragma mark - Handle Touch Events


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"disableScrolling" object:nil];
    
    UITouch *touch = [touches anyObject];
    self.currentLoc = [touch locationInView:self];
    self.currentLoc = CGPointMake(self.currentLoc.x - self.leftMargin, self.currentLoc.y);
    //self.currentLoc.x -= self.leftMargin;
    self.isMovement = YES;
    
    [self setNeedsDisplay];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    self.currentLoc = [touch locationInView:self];
    self.currentLoc = CGPointMake(self.currentLoc.x - self.leftMargin, self.currentLoc.y);
    //self.currentLoc.x -= self.leftMargin;
    [self setNeedsDisplay];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"enableScrolling" object:nil];
    
    UITouch *touch = [touches anyObject];
    self.currentLoc = [touch locationInView:self];
   // self.currentLoc.x -= self.leftMargin;
    self.currentLoc = CGPointMake(self.currentLoc.x - self.leftMargin, self.currentLoc.y);
    self.isMovement = NO;
    [self setNeedsDisplay];
}


-(NSString*)formatNumberWithUnits:(float)number withFractionDigits: (int)digits {

    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    [currencyFormatter setMaximumFractionDigits:digits];
    [currencyFormatter setMinimumFractionDigits:digits];
    NSString *numberAsString = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat:number]];
    
    if(self.units){
        return [NSString stringWithFormat:@"%@ %@", numberAsString, self.units];
    }
    return numberAsString;
}


-(NSString*)formatPairNumberX:(float)numberX andNumberY:(float)numberY withFractionDigits: (int)digits {
    
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    [currencyFormatter setMaximumFractionDigits:digits];
    [currencyFormatter setMinimumFractionDigits:digits];
    NSString *numberYAsString = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat:numberY]];
    NSString *numberXAsString = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat:numberX]];
    
    if(self.units) numberYAsString = [NSString stringWithFormat:@"%@ %@", numberYAsString, self.units];
    if(self.xUnits) numberXAsString = [NSString stringWithFormat:@"%@ %@", numberXAsString, self.xUnits];
        
    return [NSString stringWithFormat:@"(%@, %@)", numberXAsString, numberYAsString];
}


@end