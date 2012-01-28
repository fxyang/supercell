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

@interface Creep : CCSprite <NSCopying> {
    int _curHp;
	int _moveDuration;
	
	int _curWaypoint;
    int _lastWaypoint;
    
    GameHUD * gameHUD;
}

@property (nonatomic, assign) int hp;
@property (nonatomic, assign) int moveDuration;

@property (nonatomic, assign) int curWaypoint;
@property (nonatomic, assign) int lastWaypoint;


- (Creep *) initWithCreep:(Creep *) copyFrom; 
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