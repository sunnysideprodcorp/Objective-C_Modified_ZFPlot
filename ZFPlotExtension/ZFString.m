//
//  ZFString.m
//  ZFPlotExtension
//
//  Created by Aileen Nielsen on 11/9/15.
//  Copyright © 2015 SunnysideProductions. All rights reserved.
//

#import "ZFString.h"

@implementation NSString (ZFPlotExtensions)


// format a string as a date (italian convention)
+(NSString*) dateFromString:(NSDate*) date {
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
    int day = (int)[components day];
    int month = (int)[components month];
    return [NSString stringWithFormat:@"%d/%d", month, day];
}




+(NSString*)formatNumberWithUnits:(float)number withFractionDigits: (int)digits withUnits: (NSString *)units{
    
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    [currencyFormatter setMaximumFractionDigits:digits];
    [currencyFormatter setMinimumFractionDigits:digits];
    NSString *numberAsString = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat:number]];
    
    if(units){
        return [NSString stringWithFormat:@"%@ %@", numberAsString, units];
    }
    return numberAsString;
}


+(NSString*)formatPairNumberX:(float)numberX andNumberY:(float)numberY withFractionDigits: (int)digits
                    withUnits: (NSString *)units withXUnits: (NSString *)xUnits{
    
    NSNumberFormatter *currencyFormatter = [[NSNumberFormatter alloc] init];
    [currencyFormatter setMaximumFractionDigits:digits];
    [currencyFormatter setMinimumFractionDigits:digits];
    NSString *numberYAsString = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat:numberY]];
    NSString *numberXAsString = [currencyFormatter stringFromNumber:[NSNumber numberWithFloat:numberX]];
    
    if(units) numberYAsString = [NSString stringWithFormat:@"%@ %@", numberYAsString, units];
    if(xUnits) numberXAsString = [NSString stringWithFormat:@"%@ %@", numberXAsString, xUnits];
    
    return [NSString stringWithFormat:@"(%@, %@)", numberXAsString, numberYAsString];
}


@end
