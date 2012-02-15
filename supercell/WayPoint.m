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

- (id) init
{
	if ((self = [super init])) {
		
	}
    _wayPointName = nil;
	return self;
}

- (void) dealloc{
    [_wayPointName release];
    _wayPointName = nil;
    [super dealloc];
}

@end
