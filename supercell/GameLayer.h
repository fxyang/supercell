//
//  PlayLayer.h
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "SpaceManager.h"

#import "BaseLayer.h"
#import "DataModel.h"

#import "SceneManager.h"
#import "GameHUD.h"

#import "Projectile.h"
#import "Tower.h"
#import "WayPoint.h"
#import "Wave.h"
#import "Creep.h"

#import "riVerletRope.h"
#import "riActor.h"

#import "riLevelLoader.h"


@interface GameLayer : BaseLayer {
    
    ccTime _gameTime;
    SpaceManagerCocos2d * _spaceManager;
    CCSpriteBatchNode *ropeSegmentSpriteBatchNode ;
    CCSpriteBatchNode *actorSpriteBatchNode ;
    riActor *_actorSprite;
    NSMutableArray *_actorActionArray;

    
    
    CCTMXTiledMap *_tileMap;
    CCTMXLayer *_background;	

	GameHUD * gameHUD;
    
    
    cpBody * ropeNodeA;
    riVerletRope * verletRope;
    NSMutableArray *_touchPos;
    
    CGPoint _touchBeginPos;
    CGPoint _touchEndPos;
    cpShapeNode * _curSeg;

    
    riLevelLoader* levelLoader;
	cpSpace *space;


}

@property (nonatomic, assign) ccTime gameTime;


@property (nonatomic, retain) SpaceManagerCocos2d *spaceManager;
@property (nonatomic, retain) CCTMXTiledMap *tileMap;
@property (nonatomic, retain) CCTMXLayer *background;
@property (nonatomic, retain) riActor *actorSprite;
@property (nonatomic, retain) NSMutableArray *actorActionArray;


@property (nonatomic, assign) int currentLevel;


@property (nonatomic, retain) NSMutableArray *flyActionArray;
@property (nonatomic, retain) CCSprite *dragon;
@property (nonatomic, retain) CCAction *flyAction;
@property (nonatomic, retain) CCAction *moveAction;

- (void)addActorAt:(CGPoint)pt;
- (void)addWaves;
- (void)addWaypoint;
- (void)addTower: (CGPoint)pos: (int)towerTag;
- (BOOL) canBuildOnTilePosition:(CGPoint) pos;

- (void) back: (id) sender;

@end