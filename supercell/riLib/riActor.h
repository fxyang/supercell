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
@class CCAnimation;
@class riTiledMapWaypoint;
@class Garden;

#define kActorLifeDefault  INFINITY
#define kActorAgeDefault 0
#define kActorSpeedDefault 10
#define kActorSpeedVarDefault 1.0

#define kActorHealthDefault  1
#define kActorDamageDefault 0
#define kActorPowerDefault  1
#define kActorScoreDefault  1


#define kActorActionArrayCapacityDefault  100
#define kActorWaypointArrayCapacityDefault  10

#define kActorUpdateIntervalDefault 0.1
#define kActorLogicIntervalDefault 0.2
#define kActorAnimationIntervalDefault 0.05

typedef enum { 
	kBodyStatic = 0, 
	kBodyKinematic = 1,
    kBodyDynamic = 2,
    kBodyNoPhysic = 3
} BodyType;

@interface riActor : cpCCSprite <NSCopying> {
    
    NSString * _actorType;
    NSString * _name;
    int _countType;
    
    float _life;
    float _age;
    int _speed;
	float _speedVar;

    float _health;
    float _damage;

    float _power;	
    int _score;	

    
    float _updateInterval;
    float _logicInterval;
    
    riTiledMapWaypoint * _curWaypoint;
    NSArray * _waypoints;
    NSArray * _positions;

    
    CCActionInterval * _curAnimate;
    CCActionInterval * _curMovement;
    CCParticleSystemQuad * _curParticle;

    BOOL _runningCurAnimate;
    BOOL _curParticleToFollow;

    BOOL positionAdjusted;
    
    CGPoint _lastPos;
    float _lastRot;
    BodyType _bodyType;
    
    GameHUD * _gameHUD;
    GameLayer * _gameLayer;

}

@property (nonatomic, retain) NSString * actorType;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, assign) int countType;

@property (nonatomic, assign) float life;
@property (nonatomic, assign) float age;
@property (nonatomic, assign) int speed;

@property (nonatomic, assign) float health;
@property (nonatomic, assign) float damage;

@property (nonatomic, assign) float power;
@property (nonatomic, assign) int score;

@property (nonatomic, assign) float updateInterval;
@property (nonatomic, assign) float logicInterval;

@property (nonatomic, assign) float speedVar;

@property (nonatomic, retain) CCActionInterval * curAnimate;
@property (nonatomic, assign) BOOL runningCurAnimate;
@property (nonatomic, retain) CCActionInterval * curMovement;
@property (nonatomic, retain) CCParticleSystemQuad * curParticle;
@property (nonatomic, assign) BOOL curParticleToFollow;

@property (nonatomic, assign) riTiledMapWaypoint * curWaypoint;
@property (nonatomic, retain) NSArray * waypoints;
@property (nonatomic, retain) NSArray * positions;

@property (nonatomic, assign) BodyType  bodyType;
@property (nonatomic, assign) GameLayer * gameLayer;





- (riActor *) init;

- (riActor *) initWithActor:(riActor *) copyFrom;
-(void) perform;
-(void) runActionFollow:(riTiledMapWaypoint *)waypoint;
-(void)actorLogic:(ccTime)dt;
-(void)update:(ccTime)dt;

-(void)speedUp:(float)s;
-(BOOL)touchedInLayer:(CCLayer *)layer withTouchs:(NSSet *)touches;

@end

#endif