//
//  Creep.m
//  supercell
//
//  Created by Feixue Yang on 12-01-28.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Creep.h"

@implementation Creep

@synthesize hp = _curHp;
@synthesize moveDuration = _moveDuration;

@synthesize curWaypoint = _curWaypoint;
@synthesize lastWaypoint = _lastWaypoint;

float setRedHp = 9;
float setRedSpeed = 6;
float setGreenHp = 18;
float setGreenSpeed = 12;

- (id) copyWithZone:(NSZone *)zone {
	Creep *copy = [[[self class] allocWithZone:zone] initWithCreep:self];
	return copy;
}

- (Creep *) initWithCreep:(Creep *) copyFrom {
    if ((self = [[[super init] initWithFile:@"Enemy1.png"] autorelease])) {
        self.hp = copyFrom.hp;
        self.moveDuration = copyFrom.moveDuration;
        self.curWaypoint = copyFrom.curWaypoint;
        
        
	}
	[self retain];
	return self;
}

- (WayPoint *)getCurrentWaypoint{
	
	DataModel *m = [DataModel getModel];
	
	WayPoint *waypoint = (WayPoint *) [m._waypoints objectAtIndex:self.curWaypoint];
	
	return waypoint;
}

- (WayPoint *)getNextWaypoint{
	
	DataModel *m = [DataModel getModel];
    
	self.curWaypoint++;
	
	if (self.curWaypoint >= m._waypoints.count){
        self.curWaypoint--;
        gameHUD = [GameHUD sharedHUD];
        if (gameHUD.baseHpPercentage > 0) {
            [gameHUD updateBaseHp:-10];
        }
        
        Creep *target = (Creep *) self;
        
        NSMutableArray *endtargetsToDelete = [[NSMutableArray alloc] init];
        [endtargetsToDelete addObject:target];
        for (CCSprite *target in endtargetsToDelete) {
            [m._targets removeObject:target];
            [self.parent removeChild:target cleanup:YES];
        }
        return NULL;
    }
	
	WayPoint *waypoint = (WayPoint *) [m._waypoints objectAtIndex:self.curWaypoint];
	
	return waypoint;
}

- (WayPoint *)getLastWaypoint{
	
	DataModel *m = [DataModel getModel];
    
	self.lastWaypoint = self.curWaypoint -1;
	
	WayPoint *waypoint = (WayPoint *) [m._waypoints objectAtIndex:self.lastWaypoint];
	
	return waypoint;
}

-(void)creepLogic:(ccTime)dt {
	
	
	// Rotate creep to face next waypoint
	WayPoint *waypoint = [self getCurrentWaypoint ];
	
	CGPoint waypointVector = ccpSub(waypoint.position, self.position);
	CGFloat waypointAngle = ccpToAngle(waypointVector);
	CGFloat cocosAngle = CC_RADIANS_TO_DEGREES(-1 * waypointAngle);
	
	float rotateSpeed = 0.5 / M_PI; // 1/2 second to roate 180 degrees
	float rotateDuration = fabs(waypointAngle * rotateSpeed);    
	
	[self runAction:[CCSequence actions:
					 [CCRotateTo actionWithDuration:rotateDuration angle:cocosAngle],
					 nil]];		
}

@end

@implementation FastRedCreep

+ (id)creep {
    
    FastRedCreep *creep = nil;
    if ((creep = [[[super alloc] initWithFile:@"Enemy1.png"] autorelease])) {
        creep.hp = setRedHp;
        creep.moveDuration = setRedSpeed;
		creep.curWaypoint = 0;
    }
	
	[creep schedule:@selector(creepLogic:) interval:0.2];
	
    return creep;
}

@end

@implementation StrongGreenCreep

+ (id)creep {
    
    StrongGreenCreep *creep = nil;
    if ((creep = [[[super alloc] initWithFile:@"Enemy2.png"] autorelease])) {
        creep.hp = setGreenHp;
        creep.moveDuration = setGreenSpeed;
		creep.curWaypoint = 0;
    }
	
	[creep schedule:@selector(creepLogic:) interval:0.2];
    
	return creep;
}

@end
