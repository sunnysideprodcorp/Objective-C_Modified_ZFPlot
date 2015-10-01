//
//  ViewController.m
//  ZFPlotChart
//
//  Created by Francesco Zerbinati on 21/06/15.
//  Copyright (c) 2015 Francesco Zerbinati. All rights reserved.
//
//  Modified by Sunnyside Productions September 2015

#import "ViewController.h"
#import "prefs.h"
@interface ViewController ()
@property CGFloat height;
@property CGFloat width;
@end

@implementation ViewController

- (NSMutableOrderedSet *) generateDataForNumberPoints: (int)numPoints {
    NSMutableArray *orderedArray = [[NSMutableArray alloc] init];
    for(int i = 0; i < numPoints; i++){
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        dict = @{
            @"xValue" : [NSNumber numberWithInt: arc4random_uniform(100)], @"value": [NSNumber numberWithInt: arc4random_uniform(100)]
        };
        [orderedArray addObject:dict];
    }
    return [NSMutableOrderedSet orderedSetWithArray:orderedArray];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Your recent runs";
    /********** Creating an area for the graph ***********/
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    self.width = screenWidth;
    self.height = screenRect.size.height;
    
    CGRect frame = CGRectMake(0, self.height*.15, screenWidth, self.height*.25);
    
    // initialization
    self.distancePlot = [[ZFPlotChart alloc] initWithFrame:frame];
    self.distancePlot.units = @"miles";
    self.distancePlot.chartType = 1.0;
    self.distancePlot.useDates = 0.0;
    self.distancePlot.stringOffsetHorizontal = 15.0;
    self.distancePlot.baseColorProperty = [UIColor blueColor];
    self.distancePlot.lowerGradientColorProperty = [UIColor redColor];
    self.distancePlot.gridLinesOn = YES;
    self.distancePlot.animatePlotDraw = YES;
    self.distancePlot.timeBetweenPoints = 1;
    [self.view addSubview:self.distancePlot];
    
    frame.origin.y += self.height*.05 + frame.size.height;
    self.timePlot = [[ZFPlotChart alloc] initWithFrame:frame];
    self.timePlot.units = @"seconds";
    self.timePlot.chartType = 0.0;
    self.timePlot.useDates = 0.0;
    self.timePlot.baseColorProperty = [UIColor blueColor];
    self.timePlot.stringOffsetHorizontal = 5.0;
    self.timePlot.gridLinesOn = YES;
    self.timePlot.animatePlotDraw = YES;
    self.timePlot.timeBetweenPoints = .5;
    [self.view addSubview:self.timePlot];
    
    frame.origin.y += self.height*.05 + frame.size.height;
    self.ratePlot = [[ZFPlotChart alloc] initWithFrame:frame];
    self.ratePlot.units = @"hr";
    self.ratePlot.xUnits = @"units";
    self.ratePlot.chartType = 2.0;
    self.ratePlot.useDates = 2.0;
    self.ratePlot.stringOffsetHorizontal = 15.0;
    self.ratePlot.baseColorProperty = [UIColor blueColor];
    self.ratePlot.gridLinesOn = YES;
    self.ratePlot.scatterRadiusProperty = 2.2;
    self.ratePlot.timeBetweenPoints = .2;
    self.ratePlot.animatePlotDraw = YES;
    [self.view addSubview:self.ratePlot];
    
    self.distancePlot.alpha = 0;
    self.timePlot.alpha = 0;
    self.ratePlot.alpha = 0;
    
    CGFloat heightAdd = frame.size.height;
    frame = CGRectMake(0, self.height*.12, self.width, self.height*.03);
    
    UILabel *distanceLabel = [[UILabel alloc] initWithFrame:frame];
    distanceLabel.text = @"Distance";
    distanceLabel.textColor = [UIColor blueColor];
    distanceLabel.alpha = 0;
    distanceLabel.font = [UIFont fontWithName:SYSTEM_FONT_TYPE size:SYSTEM_FONT_SIZE];
    distanceLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:distanceLabel];
    
    frame.origin.y += self.height*.05 + heightAdd;
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:frame];
    timeLabel.text = @"Duration";
    timeLabel.textColor = [UIColor blueColor];
    timeLabel.alpha = 0;
    timeLabel.font = [UIFont fontWithName:SYSTEM_FONT_TYPE size:SYSTEM_FONT_SIZE];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:timeLabel];
    
    frame.origin.y += self.height*.05 + heightAdd;
    UILabel *rateLabel = [[UILabel alloc] initWithFrame:frame];
    rateLabel.text = @"Rate";
    rateLabel.textColor = [UIColor blueColor];
    rateLabel.alpha = 0;
    rateLabel.font = [UIFont fontWithName:SYSTEM_FONT_TYPE size:SYSTEM_FONT_SIZE];
    rateLabel.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:rateLabel];
    
    // draw data
    [self.distancePlot createChartWith:[self generateDataForNumberPoints:10]];
    [self.timePlot createChartWith:[self generateDataForNumberPoints:10]];
    [self.ratePlot createChartWith:[self generateDataForNumberPoints:2000]];
    [UIView animateWithDuration:0.5 animations:^{
        self.distancePlot.alpha = 1.0;
        self.timePlot.alpha = 1.0;
        self.ratePlot.alpha = 1.0;
        distanceLabel.alpha = 1.0;
        timeLabel.alpha = 1.0;
        rateLabel.alpha = 1.0;
    }];
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
