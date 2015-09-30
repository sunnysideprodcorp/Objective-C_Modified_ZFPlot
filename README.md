
## Enhancements to [ZFPlot](https://github.com/zerbfra/ZFPlotChart)


I found Francesco's ZFPlot class on CocoaControls while looking for a lightweight alternative to CorePlot. He had created a nice line-chart plotting custom UIView. While working with it, I realized that it could very easily be extended to basic bar plots and scatter plots. These features have been added. Additionally, some properties of the plots have been migrated to class properties rather than defined constants in the case of multiple plots per application. Future users may want to continue this migration so that plots are highly customizable.

This first screen shot shows the line plot, bar plot, and scatter plot respectively. Color, presence of grid lines, type of chart, type of x-axis labeling can all be set dynamically. 

![ "screenshot1" ](https://github.com/sunnysideprodcorp/Modified_ZFPlot/blob/master/images/screen1.png)

These three plots were created with the following code, which first sets the aesthetic properties:

```
   CGRect frame = CGRectMake(0, self.height*.15, screenWidth, self.height*.25);
    
    // initialization
    // Line Plot
    self.distancePlot = [[ZFPlotChart alloc] initWithFrame:frame];
    self.distancePlot.units = @"miles";
    self.distancePlot.chartType = 1.0;
    self.distancePlot.useDates = 0.0;
    self.distancePlot.stringOffsetHorizontal = 15.0;
    self.distancePlot.baseColorProperty = [UIColor blueColor];
    self.distancePlot.lowerGradientColorProperty = [UIColor redColor];
    self.distancePlot.gridLinesOn = YES;
    [self.view addSubview:self.distancePlot];
    
    // Bar Plot
    frame.origin.y += self.height*.05 + frame.size.height;
    self.timePlot = [[ZFPlotChart alloc] initWithFrame:frame];
    self.timePlot.units = @"seconds";
    self.timePlot.chartType = 0.0;
    self.timePlot.useDates = 0.0;
    self.timePlot.baseColorProperty = [UIColor blueColor];
    self.timePlot.stringOffsetHorizontal = 5.0;
    self.timePlot.gridLinesOn = YES;
    [self.view addSubview:self.timePlot];
    
    // Scatter Plot
    frame.origin.y += self.height*.05 + frame.size.height;
    self.ratePlot = [[ZFPlotChart alloc] initWithFrame:frame];
    self.ratePlot.units = @"hr";
    self.ratePlot.xUnits = @"units";
    self.ratePlot.chartType = 2.0;
    self.ratePlot.useDates = 2.0;
    self.ratePlot.stringOffsetHorizontal = 15.0;
    self.ratePlot.baseColorProperty = [UIColor blackColor];
    self.ratePlot.gridLinesOn = YES;
    self.ratePlot.scatterRadiusProperty = 3;
    [self.view addSubview:self.ratePlot];
  ```

And then finally we generate the plots by providing data:

```
    // draw data
    [self.distancePlot createChartWith:[self generateDataForNumberPoints:100]];
    [self.timePlot createChartWith:[self generateDataForNumberPoints:20]];
    [self.ratePlot createChartWith:[self generateDataForNumberPoints:255]];
    [UIView animateWithDuration:0.5 animations:^{
        self.distancePlot.alpha = 1.0;
        self.timePlot.alpha = 1.0;
        self.ratePlot.alpha = 1.0;
        distanceLabel.alpha = 1.0;
        timeLabel.alpha = 1.0;
        rateLabel.alpha = 1.0;
    }];
    
```
Clearly there is no need to do an animation, but it keeps things neater. You can also see the `isMovement` feature illustrated below. When the user touches the plot, the nearest point will be highlighted, and more precise information given. This feature works for all three kinds of plots
![ "screenshot2" ](https://github.com/sunnysideprodcorp/Modified_ZFPlot/blob/master/images/screen2.png)

On the to-do list:
1. Animate the drawing
2. Migrate more settings to class properties 
3. Refactor the code into a more modular format

The aim of this project is to provide basic plotting functionality without the steep learning curve of CorePlot or the inconveniene of expense of buying or writing a package when all you need is a simple plot. 