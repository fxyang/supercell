//
//  Pig.m
//  supercell
//
//  Created by Feixue Yang on 12-02-03.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "riActor.h"

@implementation riActor

@synthesize actorName = _actorName;
@synthesize actorId = _actorId;
@synthesize life = _life;
@synthesize health = _health;
@synthesize power = _power;
@synthesize score = _score;

@synthesize updateInterval = _updateInterval;
@synthesize logicInterval = _logicInterval;
@synthesize animationInterval = _animationIntervale;


@synthesize gameLayer = _gameLayer;
@synthesize spaceManager = _spaceManager;
@synthesize actionArray = _actionArray;
@synthesize waypointArray = _waypointArray;
@synthesize movementType = _movementType;


- (riActor *)init{
    if ((self = [super init])) {
        _actorName = nil;
        _actorId = -1;
        _life = kActorLifeDefault;
        _health = kActorHealthDefault;
        _power = kActorPowerDefault;
        _score = kActorScoreDefault;

        _updateInterval = kActorUpdateIntervalDefault;
        _logicInterval = kActorLogicIntervalDefault;
        _animationIntervale = kActorAnimationIntervalDefault;
        
        _gameLayer = nil;
        _spaceManager = nil;
        _actionArray = [[NSMutableArray alloc] initWithCapacity:kActorActionArrayCapacityDefault];
        _waypointArray = [[NSMutableArray alloc] initWithCapacity:kActorWaypointArrayCapacityDefault];
        _movementType = MOVEMENT_STATIC;
        
        [self schedule:@selector(update:) interval:kActorUpdateIntervalDefault];
        [self schedule:@selector(actorLogic:) interval:kActorLogicIntervalDefault];

    }
    return self;                    
}

- (riActor *) initWithTexture:(CCTexture2D *)texture width:(int)w height:(int)h column:(int)c row:(int)r {
    [self init];
    
    NSMutableArray *actorAnimFrames = [NSMutableArray array];
    for (int i = 0; i < r; i++) {
        [actorAnimFrames removeAllObjects];
        for (int j = 0; j < c; j++) {
            CCSpriteFrame *frame = [CCSpriteFrame frameWithTexture:texture rect:CGRectMake(j*w, i*h, w, h)];
            [actorAnimFrames addObject:frame];
        }
        CCAnimation *actorAnimation = [CCAnimation animationWithFrames:actorAnimFrames delay:_animationIntervale];
        CCAnimate *actorAnimate = [CCAnimate actionWithAnimation:actorAnimation restoreOriginalFrame:NO];
        CCSequence *seq = [CCSequence actions: actorAnimate,nil];
        
        [_actionArray addObject:[CCRepeatForever actionWithAction: seq ]];
    }
    
    return self;
}


- (riActor *) initWithActor:(riActor *) copyFrom {
    if ((self = [[super init] autorelease])) {
        self.actorName = copyFrom.actorName;
        self.actorId = copyFrom.actorId;
        self.life = copyFrom.life;
        self.health = copyFrom.health;
        self.power = copyFrom.power;
        self.score = copyFrom.score;

        self.gameLayer = copyFrom.gameLayer;
        self.spaceManager = copyFrom.spaceManager;
        
        _actionArray = [NSMutableArray arrayWithArray:copyFrom.actionArray];
        _waypointArray = [NSMutableArray arrayWithArray:copyFrom.waypointArray];
        _movementType = copyFrom.movementType;

	}
	[self retain];
	return self;
}

- (id) copyWithZone:(NSZone *)zone {
	riActor *copy = [[[self class] allocWithZone:zone] initWithActor:self];
	return copy;
}


-(void)actorLogic:(ccTime)dt {

}

-(void)update:(ccTime)dt{
    _life = _life - dt;
}

-(void)dealloc{
    
    [self removeAllChildrenWithCleanup:YES];
    [_actorName release];
    _actorName = nil;
    [_actionArray release];
    _actionArray = nil;
    [_waypointArray release];
    _waypointArray = nil;
    [super dealloc];

}
@end
