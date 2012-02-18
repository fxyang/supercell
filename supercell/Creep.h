//
//  Creep.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

#import "DataModel.h"
#import "WayPoint.h"
#import "GameHUD.h"
#import "riActor.h"

@interface Creep : riActor {

	int _moveDuration;
	
	int _curWaypoint;
    int _lastWaypoint;
    
}

@property (nonatomic, assign) int moveDuration;

@property (nonatomic, assign) int curWaypoint;
@property (nonatomic, assign) int lastWaypoint;



- (WayPoint *)getCurrentWaypoint;
- (WayPoint *)getNextWaypoint;
- (WayPoint *)getLastWaypoint;


@end

@interface FastRedCreep : Creep {
}
+(id)creep;
@end

@interface StrongGreenCreep : Creep {
}
+(id)creep;
@end