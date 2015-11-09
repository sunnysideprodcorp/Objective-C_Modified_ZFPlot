//
//  ZFPlotChart.m
//
//  Created by Zerbinati Francesco
//  Copyright (c) 2014-2015
//
//  Modified by Sunnyside Productions September 2015

#import "ZFPlotChart.h"

@implementation ZFPlotChart

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
        
        [self setAutoresizingMask: UIViewAutoresizingFlexibleWidth];
        [self setAutoresizesSubviews:YES];
        
        // get ready to receive data
        self.dictDispPoint = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    }
    return self;
}


- (void) setupLimits: (NSMutableOrderedSet *)orderSet{
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


- (NSMutableOrderedSet *) orderIndicesSetLimits: (NSMutableOrderedSet *) orderSet{
    return orderSet;
}

#pragma mark - Chart Creation Method
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
    xRange = self.xMax - self.xMin;
    
    // Adding points to values
    for(NSDictionary *dictionary in orderSet)
    {
        if(self.convertX) {
            // for graph types that scale x values, retrieve x from array of converted values, rejecting arithmetic computation at end of loop
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
        
        x+= xGapBetweenTwoPoints;
    }
    
    // More scatter plot book-keeping
    if(self.convertX)[self convertXMakeBins];


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

#pragma mark - Graphic Routines from graphic utilities

-(NSString *) stringToUse:(NSInteger)ind {
    if(self.useDates == 0.0){
        return [NSString stringWithFormat:@"%ld", ind + 1];
    }
    else if(self.useDates == 1.0){
        return [self dateFromString: [[self.dictDispPoint objectAtIndex:ind] valueForKey:fzXValue]];
       
    }
    else{
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

#pragma mark - String utilities

// format a string as a date (italian convention)
-(NSString*) dateFromString:(NSDate*) date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    int day = (int)[components day];
    int month = (int)[components month];
    return [NSString stringWithFormat:@"%d/%d", month, day];
}

// size of a string given a specific font
-(CGSize) sizeOfString:(NSString *)string withFont:(UIFont *)font {
    NSDictionary *attributes = @{ NSFontAttributeName: font};
    return [string sizeWithAttributes:attributes];
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

#pragma mark  (effectively) abstract methods that should be overridden

- (void) drawPoints {}

- (void)drawSpecial{}


#pragma mark  extras




#pragma mark  shared without overriding

- (void) drawHorizontalLines {
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
}




- (void) setupAxesAndClosures{
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

}




- (void) movementSetup : (int)pointSlot withPoint:(CGPoint)point{

    CGContextRef context = UIGraphicsGetCurrentContext();

    

        NSDictionary *dict = [self.dictDispPoint objectAtIndex:pointSlot];

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

# pragma overridden sometimes

- (CGPoint)getPointForPointSlot:(int)pointSlot{
    NSDictionary *dict = [self.dictDispPoint objectAtIndex:pointSlot];
    return CGPointMake([[dict valueForKey:fzPoint] CGPointValue].x,[[dict valueForKey:fzPoint] CGPointValue].y);
}


- (int)getPointSlot{
    float xGapBetweenTwoPoints = self.chartWidth/[self.dictDispPoint count];
    return self.currentLoc.x/(signed)xGapBetweenTwoPoints;
}

- (float) gapBetweenPoints: (NSMutableOrderedSet *)orderSet{
    return self.chartWidth/MAX(([orderSet count] - 1), 1);
}

- (float) returnX : (float) toAdd  {
    return self.leftMargin;
}

// this works for bar chart and line chart; scatter chart implements its own
- (BOOL) goodPointSlot : (int) pointSlot {
    return (pointSlot < [self.dictDispPoint count] && pointSlot < self.countDown);
}

# pragma mark to display non-ordered data animated drawing

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



# pragma mark to scale x-axis data where desired (non-ordinal display)

@end