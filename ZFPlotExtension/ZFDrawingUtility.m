//
//  ZFDrawingUtility.m
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import "ZFDrawingUtility.h"

@implementation ZFDrawingUtility


-(void) drawCircleAt:(CGPoint)point ofRadius:(int)radius {
    // draws a circle at a given point
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect myOval = {point.x-radius/2, point.y-radius/2, radius, radius};
    CGContextAddEllipseInRect(context, myOval);
    CGContextFillPath(context);
}

-(void)gradientizefromPoint:(CGPoint) startPoint toPoint:(CGPoint) endPoint forPath:(CGMutablePathRef) path forBaseColor: (UIColor *) baseColorProperty forLowerGradientColorProperty: (UIColor *) lowerGradientColorProperty{
    //draws a gradient within a path
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGFloat redUpper, greenUpper, blueUpper, alpha;
    UIColor *baseColorUpper = baseColorProperty;
    [baseColorUpper getRed: &redUpper
                     green: &greenUpper
                      blue: &blueUpper
                     alpha: &alpha];
    
    
    CGFloat redLower, greenLower, blueLower;
    UIColor *baseColorLower = lowerGradientColorProperty;
    [baseColorLower getRed: &redLower
                     green: &greenLower
                      blue: &blueLower
                     alpha: &alpha];
    
    CGFloat colors [] = {
        redUpper, greenUpper, blueUpper, 0.9,
        redLower, greenLower, blueLower, 0.2,
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


-(void) setContextWidth:(float)width andColor:(UIColor*)color {
// set the context with a specified widht and color
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, width);
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextSetStrokeColorWithColor(context, color.CGColor);
}

-(void)endContext {
    // end context
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextStrokePath(context);
}


-(void) drawLineFrom:(CGPoint) start to: (CGPoint)end {
    // line between two points
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, start.x, start.y);
    CGContextAddLineToPoint(context,end.x,end.y);
    
}

-(void) drawCurveFrom:(CGPoint)start to:(CGPoint)end {
    // curve between two points
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextMoveToPoint(context, start.x, start.y);
    CGContextAddQuadCurveToPoint(context, start.x, start.y, end.x, end.y);
    CGContextSetLineCap(context, kCGLineCapRound);
}

-(void) drawString:(NSString*)string at:(CGPoint)point withFont:(UIFont*)font andColor:(UIColor*)color{
    // draws a string given a point, font and color
    NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: color};
    [string drawAtPoint:point withAttributes:attributes];
}

- (void) drawRoundedRect:(CGContextRef)c rect:(CGRect)rect radius:(int)corner_radius color:(UIColor *)color{
// rounded corners rectangle
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


@end
