//
//  WayPoint.m
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WayPoint.h"


@implementation WayPoint

@synthesize wayPointName = _wayPointName;
@synthesize nextWayPoint = _nextWayPoint;
@synthesize travelSpeed = _travelSpeed;
@synthesize travelAnimation = _travelAnimation;
@synthesize travelAction = _travelAction;

- (id) init
{
	if ((self = [super init])) {
        _wayPointName = nil;
        _nextWayPoint = nil;
        _travelSpeed = 0;
        _travelAnimation = nil;
        _travelAction = nil;
	}
 
	return self;
}

-(WayPoint *) initWithWayPointName:(NSString *) name_{
    [self init];
    if(self != nil)
        self.wayPointName = name_;
    return self;
}

- (void) dealloc{
    [_wayPointName release];
    _wayPointName = nil;
    [_travelAnimation release];
    _travelAnimation = nil;
    [_travelAction release];
    _travelAction = nil;
    [super dealloc];
}




@end
