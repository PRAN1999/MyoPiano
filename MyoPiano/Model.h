//
//  Model.h
//  MyoPiano
//
//  Created by Pranay Neelagiri on 4/7/18.
//  Copyright © 2018 Pranay Neelagiri. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Model : NSObject
+ (void)loadGraph;
+ (BOOL)loadGraphFromPath:(NSString *)path;
+ (BOOL)createSession;
+ (int)predict:(float *)example;
+ (int)test;
@end
