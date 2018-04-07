//
//  GLKitPolyfill.h
//  MyPianoiOS
//
//  Created by Pranay Neelagiri on 4/6/18.
//  Copyright © 2018 Pranay Neelagiri. All rights reserved.
//

#ifndef GLKitPolyfill_h
#define GLKitPolyfill_h

#import <MyoKit/MyoKit.h>

@interface AccelerationData: NSObject
@property (nonatomic) float magnitude;
@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;
@end

@implementation AccelerationData
@end

@interface OrientationData: NSObject
@property (nonatomic) TLMAngle *pitch;
@property (nonatomic) TLMAngle *yaw;
@property (nonatomic) TLMAngle *roll;
@end

@implementation OrientationData
@end

@interface GyroData: NSObject
@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;
@end

@implementation GyroData
@end

@interface GLKitPolyfill: NSObject
+ (AccelerationData *) getAcceleration:(TLMAccelerometerEvent *)accelerometerEvent;
+ (OrientationData *) getOrientation:(TLMOrientationEvent *)orientationEvent;
+ (GyroData *) getGyro:(TLMGyroscopeEvent *)gyroEvent;
@end

#endif /* GLKitPolyfill_h */
