//
//  Pig.m
//  supercell
//
//  Created by Feixue Yang on 12-02-03.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riActor.h"
#import "riTiledMapWaypoint.h"

@implementation riActor

@synthesize actorType = _actorType;
@synthesize name = _name;
@synthesize countType = _countType;

@synthesize life = _life;
@synthesize age = _age;
@synthesize speed = _speed;

@synthesize health = _health;
@synthesize demage = _demage;

@synthesize power = _power;
@synthesize score = _score;

@synthesize updateInterval = _updateInterval;
@synthesize logicInterval = _logicInterval;
@synthesize speedVar = _speedVar;


@synthesize curWaypoint = _curWaypoint;
@synthesize waypoints = _waypoints;
@synthesize positions = _positions;

@synthesize curAnimate = _curAnimate;
@synthesize runningCurAnimate = _runningCurAnimate;
@synthesize curMovement = _curMovement;
@synthesize curParticle = _curParticle;
@synthesize curParticleToFollow = _curParticleToFollow;


@synthesize bodyType = _bodyType;

@synthesize gameLayer = _gameLayer;

- (riActor *)init{
    if ((self = [super init])) {
        
        _actorType = nil;
        _name = nil;
        _countType = 0;
        
        _life = kActorLifeDefault;
        _age = kActorAgeDefault;
        
        _speed = kActorSpeedDefault;
        _speedVar = kActorSpeedVarDefault;

        _health = kActorHealthDefault;
        _demage = kActorDemageDefault;

        _power = kActorPowerDefault;
        _score = kActorScoreDefault;
        
        _updateInterval = kActorUpdateIntervalDefault;
        _logicInterval = kActorLogicIntervalDefault;
        
        _gameLayer = nil;
        
        _curAnimate = nil;
        _curMovement = nil;
        _curParticle = nil;
        _runningCurAnimate = NO;
        _curParticleToFollow = YES;
        
        _curWaypoint = nil;
        positionAdjusted = NO;
        _waypoints = nil;
        _positions = nil;
        
        _lastPos = [self position];
        _lastRot = 0;
        
        _bodyType = kBodyStatic;
        
        [self schedule:@selector(update:) interval:_updateInterval];
        [self schedule:@selector(actorLogic:) interval:_logicInterval];
    }
    

    return self;                    
}

-(void)dealloc{
    
    self.actorType = nil;
    self.name = nil;
    
    self.waypoints = nil;
    self.positions = nil;
    
    [self stopAllActions];
    
    [self removeAllChildrenWithCleanup:YES];
    
    self.curAnimate = nil;
    self.curMovement = nil;
    self.curParticle = nil;

    
    [super dealloc];
    
}

- (riActor *) initWithActor:(riActor *) copyFrom {
    if ((self = [[super init] autorelease])) {
        self.actorType = copyFrom.actorType;
        self.name = copyFrom.name;
        self.countType = copyFrom.countType;

        self.life = copyFrom.life;
        self.age = copyFrom.age;

        self.health = copyFrom.health;
        self.demage = copyFrom.demage;

        self.power = copyFrom.power;
        self.score = copyFrom.score;
        
        self.speedVar = copyFrom.speedVar;
        
        self.gameLayer = copyFrom.gameLayer;
        self.spaceManager = copyFrom.spaceManager;
        
        
        self.curAnimate = copyFrom.curAnimate;
        self.runningCurAnimate = copyFrom.runningCurAnimate;
        self.curMovement = copyFrom.curMovement;
        self.curParticle = copyFrom.curParticle;
        self.curParticleToFollow = copyFrom.curParticleToFollow;

        
        self.curWaypoint = copyFrom.curWaypoint;
        
        self.bodyType = copyFrom.bodyType;

	}
	[self retain];
	return self;
}

- (id) copyWithZone:(NSZone *)zone {
	riActor *copy = [[[self class] allocWithZone:zone] initWithActor:self];
	return copy;
}

-(void)runActionFollow:(riTiledMapWaypoint *)waypoint{
    CCActionInterval * move = nil;
    if(waypoint !=nil){
        if(positionAdjusted || cpveql(self.position, waypoint.position)){
            self.curWaypoint = [waypoint nextWaypoint];
            move = [waypoint getNextActionFor:self];
        }else{
            self.curWaypoint = waypoint;
            move = [_curWaypoint getAdjustmentActionFor:self];            
        }
        
        positionAdjusted = YES;
        if(move != nil){            
            
                self.curMovement = [CCSequence actions:move,
                        [CCCallFuncO actionWithTarget:self selector:@selector(runActionFollow:) object:_curWaypoint], 
                                nil];
                self.curMovement = [CCSpeed actionWithAction:self.curMovement speed:_speedVar];
                [self runAction:_curMovement];

        }
    }
    
}

-(void)perform{

    [self runActionFollow:_curWaypoint];
    if(_curAnimate != nil){
        self.curAnimate = [CCSpeed actionWithAction:(CCActionInterval*)_curAnimate speed:_speedVar];

        [self runAction:_curAnimate];
        _runningCurAnimate = YES;
    }
}

             
-(void)actorLogic:(ccTime)dt {


}

-(void)update:(ccTime)dt{

    _age = _age + dt;
    if(_demage >0)
        _demage = _demage - dt;
    if(_demage <0)
        _demage = 0;
    
/* Rotate to the direction of movement... */
    if(_bodyType == kBodyKinematic){
        CGPoint pos = self.position;
        CGPoint faceVector = ccpSub(pos, _lastPos);
        CGFloat faceAngle = ccpToAngle(faceVector);
        CGFloat cocosAngle = 90 + CC_RADIANS_TO_DEGREES(-1 * faceAngle);
        float rotateSpeed = 0.1 / M_PI; // 0.1 second to roate 180 degrees
        float rotateDuration = fabs(faceAngle * rotateSpeed);    
        [self runAction:[CCSequence actions:[CCRotateTo actionWithDuration:rotateDuration angle:cocosAngle],nil]];
        _lastPos = pos;
    }
/* End of rotation */
    
    if(_curParticleToFollow)
        _curParticle.position = self.position;

}

-(void)speedUp:(float)s{
    
    if(_curMovement != nil && [[_curMovement class] isSubclassOfClass:[CCSpeed class]])
        [(CCSpeed*)_curMovement setSpeed:s];
    
    if(_curAnimate != nil && [[_curAnimate class] isSubclassOfClass:[CCSpeed class]])
        [(CCSpeed*)_curAnimate setSpeed:s];
    
    _speedVar = s;

}

-(BOOL)isMature{
    return YES;
}

-(BOOL)touchedInLayer:(CCLayer *)layer withTouchs:(NSSet *)touches{
    
    CGRect box = [self boundingBox];
    for(id touch in touches){
        if(layer != nil){
            CGPoint pt = [layer convertTouchToNodeSpace:touch];            
            if(CGRectContainsPoint(box, pt)){
                NSLog(@"Touched.............");
                return YES;
            }
        }
    }
    return NO;
}


@end
