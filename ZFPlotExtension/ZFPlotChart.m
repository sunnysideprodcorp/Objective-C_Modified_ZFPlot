//
//  ZFPlotChart.m
//
//  Created by Zerbinati Francesco
//  Copyright (c) 2014-2015
//
//  Modified by Sunnyside Productions September 2015

#import "ZFPlotChart.h"
#import "ZFString.h"
@implementation ZFPlotChart


#pragma mark - Initialization/LifeCycle Method

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // get display constraints
        self.chartHeight = frame.size.height - vMargin;
        self.chartWidth = frame.size.width - hMargin;
        
        // set defaults for appearance parameters
        self.baseColorProperty = baseColor;
        self.lowerGradientColorProperty = lowerGradientColor;
        self.scatterRadiusProperty = scatterCircleRadius;
        self.stringOffsetHorizontal = stringOffset;
        self.gridLinesOn = YES;
        self.animatePlotDraw = YES;
        self.timeBetweenPoints = .3;
        self.convertX = FALSE;
        self.backgroundColor = whiteColor;
        self.isMovement = NO;
        self.draw = [[ZFDrawingUtility alloc] init];
        
        
        [self setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
        [self setAutoresizesSubviews:YES];
        
        // get ready to receive data
        self.dictDispPoint = [[ZFData alloc] init];
        self.dictDispPoint.chart = self;
    }
    return self;
}


- (void) setupLimits: (NSMutableOrderedSet *)orderSet{
    // Find Min & Max of Chart
    self.dictDispPoint.max = [[[orderSet valueForKey:fzValue] valueForKeyPath:@"@max.floatValue"] floatValue];
    self.dictDispPoint.min = [[[orderSet valueForKey:fzValue] valueForKeyPath:@"@min.floatValue"] floatValue];
    
    // Enhance Upper & Lower Limit for Flexible Display, based on average of min and max
    self.dictDispPoint.max = ceilf((self.dictDispPoint.max+maxMinOffsetBuffer*self.dictDispPoint.max )/ 1)*1;
    self.dictDispPoint.min = floor((self.dictDispPoint.min-maxMinOffsetBuffer*self.dictDispPoint.max)/1)*1;
    self.dictDispPoint.max = MIN(maxY, self.dictDispPoint.max);
    self.dictDispPoint.min = MAX(minY, self.dictDispPoint.min);
    
    // Calculate left space given by the lenght of the string on the axis
    self.leftMargin = [self sizeOfString:[NSString formatNumberWithUnits:self.dictDispPoint.max/valueDivider withFractionDigits:1 withUnits:self.units] withFont:systemFont].width + leftSpace;
    self.chartWidth -= self.leftMargin;
}


- (NSMutableOrderedSet *) clearDispDictAndReturnNewOrderedSet: (NSOrderedSet *)data {
    [self.dictDispPoint removeAllObjects];
    NSMutableOrderedSet *orderSet = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    // Add data to the orderSet
    [data enumerateObjectsUsingBlock:^(id obj, NSUInteger ind, BOOL *stop){
        [orderSet addObject:obj];
    }];
    return orderSet;
}


#pragma mark - Chart Creation Method

- (void)drawRect:(CGRect)rect{
    @try
    {
        if([self.dictDispPoint count] > 0)
        {
            [self stopLoading];           // remove loading animation
            [self drawHorizontalLines];   // draw horizontal grid lines where desired
            
            [self drawPoints];            // draw actual data points in particula way for particular graph type (ALWAYS OVERRIDE BY SUBCLASS)
            // note that drawPoints is also responsible for drawing vertical grid lines and/or x-axis labels as appropriate
            // this is to avoid looping through data elements twice
            
            [self drawSpecial];           // draw whatever other features are unique to a particular kind of graph
            // currently only used by line graph to fill in gradient below line graph
            
            [self setupAxesAndClosures];  // draw axes and lines to complete square around graph
            
            // if user has touched the chart, show an informational point reflecting nearest data point
            if(self.isMovement)
            {
                int pointSlot = [self getPointSlot];  // this depends on graph type
                if([self goodPointSlot:pointSlot]) {  // this also depends on graph type
                    [self movementSetup : pointSlot withPoint:[self getPointForPointSlot:pointSlot]]; // this is a universal
                }
            }
        }
        else
        {
            // draw a loding spinner while loading the data
            [self drawLoading]; // this is a universal
        }
    }
    @catch (NSException *exception) {}
}

- (void)createChartWith:(NSOrderedSet *)data
{
    
    NSMutableOrderedSet *orderSet = [self clearDispDictAndReturnNewOrderedSet:data];
    
    if(self.convertX){
        orderSet = [self orderIndicesSetLimits:orderSet];

    }

    [self setupLimits:orderSet];
    
    // Calculate x-axis point locations accordig to line chart type
    float xGapBetweenTwoPoints = [self gapBetweenPoints:orderSet];
    float x = [self returnX:xGapBetweenTwoPoints];
    
    self.xUnitWidth = xGapBetweenTwoPoints;

    // Parameters to calculate y-axis positions
    float y = topMarginInterior;
    self.yMax = self.yMin;
    
    float xRange;
    xRange = self.dictDispPoint.xMax - self.dictDispPoint.xMin;
    
    // Adding points to values
    for(NSDictionary *dictionary in orderSet)
    {
        if(self.convertX) {
            // for graph types that scale x values, retrieve x from array of converted values, rejecting arithmetic computation at end of loop
            x =  [self.dictDispPoint convertXToGraphNumber:[[dictionary valueForKey:fzXValue] floatValue]];
            [self.dictDispPoint.xIndices addObject:[NSNumber numberWithFloat:x]];
        }

        y = [self.dictDispPoint convertYToGraphNumber:[[dictionary valueForKey:fzValue] floatValue]];
        
        // Get max y value
        if(y > self.yMax) self.yMax = y;
        
        CGPoint point = CGPointMake(x,y);
        
        NSDictionary *dictPoint = [NSDictionary dictionaryWithObjectsAndKeys:[NSValue valueWithCGPoint:point], fzPoint,
                                   [dictionary valueForKey:fzValue], fzValue,
                                   [dictionary valueForKey:fzXValue], fzXValue, nil];
        
        [self.dictDispPoint addObject:dictPoint];
        
        x+= xGapBetweenTwoPoints;
    }
    
    // More scatter plot book-keeping
    if(self.convertX)[self.dictDispPoint convertXMakeBins];


    if(self.animatePlotDraw)
    {
        [self startDrawingPaths];
        [self resetInclusionArray];
    }
    else{
        [self allTrueInclusionArray];
        self.countDown = (int)self.dictDispPoint.count + 1;
        [self setNeedsDisplay];
    }
}

#pragma mark - Animated Drawing


- (void)startDrawingPaths
{
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


#pragma mark - Graphic Utilities

-(void) drawCircleAt:(CGPoint)point ofRadius:(int)radius {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect myOval = {point.x-radius/2, point.y-radius/2, radius, radius};
    CGContextAddEllipseInRect(context, myOval);
    CGContextFillPath(context);
}

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

#pragma mark - Graphic Routines from graphic utilities

-(NSString *) stringToUse:(NSInteger)ind {
    if(self.useDates == 0.0){
        return [NSString stringWithFormat:@"%ld", ind + 1];
    }
    else if(self.useDates == 1.0){
        return [NSString dateFromString: [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue]];
       
    }
    else{
        if(self.xUnits) return [NSString stringWithFormat:@"%@ %@", [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue], self.xUnits];
        else return [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue];
    }
    
}
/*
#pragma mark - Graph conversion utilities
- (float) convertXToGraphNumber: (float)xVal{
    CGFloat xDiff = self.dictDispPoint.xMax - xVal;
    CGFloat xRange = self.dictDispPoint.xMax - self.dictDispPoint.xMin;
    return (self.chartWidth)*(1-xDiff/xRange) + self.leftMargin;
}


- (float) convertYToGraphNumber: (float)yVal{
    float diff = self.dictDispPoint.max-yVal;
    float range = self.dictDispPoint.max - self.dictDispPoint.min;
    return (self.chartHeight*diff)/range + topMarginInterior;
}*/


#pragma mark - String utilities

// size of a string given a specific font
-(CGSize) sizeOfString:(NSString *)string withFont:(UIFont *)font {
    NSDictionary *attributes = @{ NSFontAttributeName: font};
    return [string sizeWithAttributes:attributes];
}


#pragma mark - Handle Touch Events

- (int)getPointSlot{
    // determine which data point to use based on user touch location
    // some subclasses override this
    float xGapBetweenTwoPoints = self.chartWidth/[self.dictDispPoint count];
    return self.currentLoc.x/(signed)xGapBetweenTwoPoints;
}

- (CGPoint)getPointForPointSlot:(int)pointSlot{
    // get appropriate data point given point slot determine by user touch
    // some subclasses override this
    NSDictionary *dict = [self.dictDispPoint objectAtIndex:pointSlot];
    return CGPointMake([[dict valueForKey:fzPoint] CGPointValue].x,[[dict valueForKey:fzPoint] CGPointValue].y);
}

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

#pragma mark  (Effectively) Abstract Methods that Can Be Overridden

- (void) drawPoints {
    // this method should draw data in preferred representation as well as all x-axis information (labels, vertical lines)
    // x-axis information is coupled with drawing data to avoid double repetition through data
}

- (void)drawSpecial{
    // anything that needs to be added after data is drawn
    // line chart draws its gradient here; bar and scatter charts do not currently make use of drawSpecial
}


#pragma mark  Drawing Setup Functions Not Overridden

- (void) drawHorizontalLines {
    float range = self.dictDispPoint.max-self.dictDispPoint.min;
    
    float intervalHlines = (self.chartHeight)/MIN(intervalLinesHorizontal, self.dictDispPoint.count - 1);    //5.0f;
    float intervalValues = range/MIN(intervalLinesHorizontal, self.dictDispPoint.count - 1);     //5.0f;
    
    // horizontal lines
    for(int i=intervalLinesHorizontal;i>0;i--)
    {
        [self.draw setContextWidth:0.5f andColor:linesColor];
        
        CGPoint start = CGPointMake(self.leftMargin, self.chartHeight+topMarginInterior-i*intervalHlines);
        CGPoint end = CGPointMake(self.chartWidth+self.leftMargin, self.chartHeight+topMarginInterior-i*intervalHlines);
        
        // draw the line
        if(self.gridLinesOn)[self.draw drawLineFrom:start to:end];
        
        // draw yVals on the axis
        NSString *yVal = [NSString formatNumberWithUnits:(self.dictDispPoint.min+i*intervalValues)/valueDivider withFractionDigits:1 withUnits:self.units];
        CGPoint yValPoint = CGPointMake(self.leftMargin - [self sizeOfString:yVal withFont:systemFont].width - 5,(self.chartHeight+topMarginInterior-i*intervalHlines-6));
        [self.draw drawString:yVal at:yValPoint withFont:systemFont andColor:linesColor];
        [self.draw endContext];
    }
}

- (void) setupAxesAndClosures{
    //  X and Y axis
    [self.draw setContextWidth:1.0f andColor:linesColor];
    
    //  y
    [self.draw drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior) to:CGPointMake(self.leftMargin, self.chartHeight+topMarginInterior)];
    //  x
    [self.draw drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior+self.chartHeight) to:CGPointMake(self.leftMargin+self.chartWidth, self.chartHeight+topMarginInterior)];
    
    // vertical closure
    CGPoint startLine = CGPointMake(self.leftMargin+self.chartWidth, topMarginInterior);
    CGPoint endLine = CGPointMake(self.leftMargin+self.chartWidth, topMarginInterior+self.chartHeight);
    [self.draw drawLineFrom:startLine to:endLine];
    
    // horizontal closure
    [self.draw drawLineFrom:CGPointMake(self.leftMargin, topMarginInterior) to:CGPointMake(self.chartWidth+self.leftMargin, topMarginInterior)];
    
    [self.draw endContext];

}

- (void) movementSetup : (int)pointSlot withPoint:(CGPoint)point{

    CGContextRef context = UIGraphicsGetCurrentContext();
    NSDictionary *dict = [self.dictDispPoint objectAtIndex:pointSlot];

    // Line at current Point
    [self.draw setContextWidth:1.0f andColor:self.baseColorProperty];
    [self.draw drawLineFrom:CGPointMake(point.x, topMarginInterior-10) to:CGPointMake(point.x, self.chartHeight+topMarginInterior)];
    [self.draw endContext];
       
    // Circle at point
    [self.draw setContextWidth:1.0f andColor:self.baseColorProperty];
    [self.draw drawCircleAt:point ofRadius:8];
    [self.draw endContext];
        
    NSString *yVal = [self getStringForLabel:dict];
    
    CGSize yValSize = [self sizeOfString:yVal withFont:boldFont];
        
    CGRect yValRect = {point.x-yValSize.width/2, 2, yValSize.width + 10, yValSize.height +3};
        
    // if goes out on right
    if(point.x+-yValSize.width/2+yValSize.width+12 > self.chartWidth+self.leftMargin)
        yValRect.origin.x = self.chartWidth+self.leftMargin-yValSize.width-2;
    // if goes out on left
    if(yValRect.origin.x < self.leftMargin)
        yValRect.origin.x = self.leftMargin-(self.leftMargin/2);
        
    // rectangle for the label
    [self.draw drawRoundedRect:context rect:yValRect radius:5 color:self.baseColorProperty];
    // value string
    [self.draw drawString:yVal at:CGPointMake(yValRect.origin.x+(yValRect.size.width-yValSize.width)/2,yValRect.origin.y+1.0f) withFont:boldFont andColor:whiteColor];
}

# pragma mark Functions Varying by Chart Type

- (float) gapBetweenPoints: (NSMutableOrderedSet *)orderSet{
    // determine what distance between points, overridden by bar graph and ignored by  scatter graph
    return self.chartWidth/MAX(([orderSet count] - 1), 1);
}

- (float) returnX : (float) toAdd  {
    // set beginning x point with chart (to control whatever buffer you want between points and y-axis)
    return self.leftMargin;
}

- (NSString *) getStringForLabel : (NSDictionary *)dict {
    float value = [[dict objectForKey:fzValue] floatValue]/valueDivider;
    return [NSString formatNumberWithUnits:value withFractionDigits:2 withUnits:self.units];
}

# pragma mark Functions Specialized by Scatter Plot

- (NSMutableOrderedSet *) orderIndicesSetLimits: (NSMutableOrderedSet *) orderSet{
    // overridden by scatter plot
    return orderSet;
}

- (BOOL) goodPointSlot : (int) pointSlot {
    // this works for bar chart and line chart; scatter chart implements its own
    return (pointSlot < [self.dictDispPoint count] && pointSlot < self.countDown);
}

- (void)resetInclusionArray {
    // overridden by scatter chart to manage animation by keeping track of which randomly selected points have already been drawn
}

- (void) allTrueInclusionArray {
    // overridden by scatter chart to manage animation by keeping track of which randomly selected points have already been drawn
}




@end