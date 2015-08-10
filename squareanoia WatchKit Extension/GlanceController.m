//
//  GlanceController.m
//  squareanoia WatchKit Extension
//
//  Created by Clay Smith  on 6/24/15.
//
//

#import "GlanceController.h"


@interface GlanceController()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *crimeCountLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *logginsGroup;

@end


@implementation GlanceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];

    [GlanceController openParentApplication:@{@"crimeCount": @"true"} reply:^(NSDictionary *replyInfo, NSError *error) {
        NSNumber *count = replyInfo[@"count"];
        self.crimeCountLabel.text = [NSString stringWithFormat:@"%@ crimes nearby", count];
        if ([count intValue] > 0) {
            [self.logginsGroup setAlpha:[count doubleValue]*0.3];
        }
    }];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



