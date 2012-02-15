//
//  Pig.h
//  supercell
//
//  Created by Feixue Yang on 12-02-03.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#ifndef riActor_h
#define riActor_h
#import "SpaceManagerCocos2d.h"

@class GameLayer;
@class GameHUD;

#define kActorLifeDefault  INFINITY
#define kActorHealthDefault  100
#define kActorPowerDefault  100
#define kActorScoreDefault  0


#define kActorActionArrayCapacityDefault  100
#define kActorWaypointArrayCapacityDefault  10

#define kActorUpdateIntervalDefault 0.2
#define kActorLogicIntervalDefault 0.2
#define kActorAnimationIntervalDefault 0.05

typedef 
enum { 
	MOVEMENT_STATIC = 0, 
	MOVEMENT_LINE = 1, 
	MOVEMENT_CIRCLE = 3, 
	MOVEMENT_BEZIER
} MovementType;

@interface riActor : cpCCSprite <NSCopying> {
    NSString * _actorName;
    int _actorId;
    cpFloat _life;
    int _health;
    int _power;	
    int _score;	

    cpFloat _updateInterval;
    cpFloat _logicInterval;
    cpFloat _animationInterval;

    
    GameLayer * _gameLayer;
    GameHUD * _gameHUD;
    SpaceManager * _spaceManager;

    NSMutableArray * _waypointArray;
    MovementType _movementType;
    
    NSMutableArray *_actionArray;
}

@property (readwrite, assign) NSString * actorName;
@property (readwrite, assign) int actorId;
@property (readwrite, assign) cpFloat life;
@property (readwrite, assign) int health;
@property (readwrite, assign) int power;
@property (readwrite, assign) int score;

@property (readwrite, assign) cpFloat updateInterval;
@property (readwrite, assign) cpFloat logicInterval;
@property (readwrite, assign) cpFloat animationInterval;


@property (readwrite, assign) GameLayer * gameLayer;
@property (readwrite, assign) SpaceManager * spaceManager;
@property (readwrite, retain) NSMutableArray * actionArray;
@property (readwrite, retain) NSMutableArray * waypointArray;
@property (readwrite, assign) MovementType movementType;



- (riActor *) init;
- (riActor *) initWithTexture:(CCTexture2D *)texture width:(int)w height:(int)h column:(int)c row:(int)r;
- (riActor *) initWithActor:(riActor *) copyFrom;
-(void)actorLogic:(ccTime)dt;
-(void)update:(ccTime)dt;


@end

#endif