//
//  main.m
//  GraphVisualizer
//
//  Created by Kai Lu on 2/9/15.
//  Copyright (c) 2015 Kai Lu. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SJSAppDelegate.h"

int main(int argc, char * argv[])
{
    @autoreleasepool {
        @try {
            return UIApplicationMain(argc, argv, nil, NSStringFromClass([SJSAppDelegate class]));
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception.reason);
        }
    }
}
