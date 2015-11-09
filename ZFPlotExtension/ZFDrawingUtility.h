//
//  ZFDrawingUtility.h
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface ZFDrawingUtility : NSObject
-(void) drawCircleAt:(CGPoint)point ofRadius:(int)radius;
-(void)gradientizefromPoint:(CGPoint) startPoint toPoint:(CGPoint) endPoint forPath:(CGMutablePathRef) path forBaseColor: (UIColor *) baseColorProperty forLowerGradientColorProperty: (UIColor *) lowerGradientColorProperty;
-(void)drawMessage:(NSString*)string;
-(void) setContextWidth:(float)width andColor:(UIColor*)color ;
-(void)endContext;
-(void) drawLineFrom:(CGPoint) start to: (CGPoint)end ;
-(void) drawCurveFrom:(CGPoint)start to:(CGPoint)end ;
-(void) drawString:(NSString*)string at:(CGPoint)point withFont:(UIFont*)font andColor:(UIColor*)color;
- (void) drawRoundedRect:(CGContextRef)c rect:(CGRect)rect radius:(int)corner_radius color:(UIColor *)color;
@end
