//
//  WayPoint.h
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
@class riActor;

@interface riTiledMapWaypoint : CCNode {
    NSString * _waypointName;
    NSMutableDictionary * _infoDict;
    riTiledMapWaypoint * _nextWaypoint;
    
}
@property (nonatomic, retain) NSString * waypointName;
@property (nonatomic, retain) NSMutableDictionary * infoDict;
@property (nonatomic, assign) riTiledMapWaypoint * nextWaypoint;



+(id) WaypointWithInfoDictionary:(NSMutableDictionary *)dict;

- (id) initWaypointWithInfoDictionary:(NSMutableDictionary*)dict;

-(riTiledMapWaypoint *) initWithWaypointName:(NSString *) name_;
-(CCActionInterval *) getAdjustmentActionFor:(riActor*)actor;
-(CCActionInterval *) getNextActionFor:(riActor*)actor;
-(float) distanceToWaypointWithName:(NSString *)wname;
-(float) distanceToWaypoint:(riTiledMapWaypoint *)wp;


@end