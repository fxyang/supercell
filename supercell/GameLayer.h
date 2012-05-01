//
//  PlayLayer.h
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "SpaceManagerCocos2d.h"
#import "BaseLayer.h"

#import "Projectile.h"
#import "Tower.h"
#import "riTiledMapWaypoint.h"

@class DataModel;
@class SceneManager;
@class GameHUD;
@class riActor;
@class riLevelLoader;
@class riVerletRope;
@class Player;

#define kWinWidth ([[CCDirector sharedDirector] winSize].width)
#define kWinHeight ([[CCDirector sharedDirector] winSize].height)

#define kFingerMovementFactor 40
#define kFingerMovementFactorX 40
#define kFingerMovementFactorY 80
#define kFingerNoMovementFactor 40
#define kFingerTouchTimeFactor 1.5


typedef enum {
    kHeroCollisionType = 1,
    kBorderCollisionType = 2,
    kGardenCollisionType = 3,
    kButterflyCollisionType = 4,
    kBulletCollisionType = 5,
    kNetCollisionType = 6
} CollisionType;

typedef enum {
    kBatchNodeTag = 0,
    kStaticBackgroundTag = 1000,
	kParallaxNodeTag = 1001,
    kBackgroundActionTag = 1002,
    kHeroTag = 2000,
    kBulletTag = 2001,
    kNetTag = 2002
} TagType;

typedef enum {
    kStaticBackgroundZ = 0,
    kParallaxNodeZ = 1,
    kHeroZ = 1002,
    kBulletZ = 1003,
    kBulletParticleZ =1004,
    kCoinZ = 1005,
    kCoinParticleZ =1006,
    kDandelionParticleZ = 1007
} ZType;


@interface GameLayer : BaseLayer {
    
    ccTime _gameTime;
    riLevelLoader* _levelLoader;
    SpaceManagerCocos2d * _spaceManager;
    cpSpace *_space;
    
    CGSize _winSize;

    CCSpriteBatchNode *actorSpriteBatchNode ;
    
    
    NSMutableArray *_tiledMaps;
    CCTMXLayer *_background;	
	GameHUD * gameHUD;
    

    CCSpriteBatchNode *ropeSegmentSpriteBatchNode ;
    
    riVerletRope * verletRope;
    NSMutableArray *_touchPos;
    
    CGPoint _touchBeginPos;
    CGPoint _touchEndPos;
    
    double _touchBeginTime;
    double _touchEndTime;
        
    riActor * _weapon;

    CCParallaxNode * _parallaxNode;
    
    NSMutableArray * _actorsArray;
    NSMutableArray * _bulletsArray;

    Player * _player;

}

@property (nonatomic, assign) ccTime gameTime;
@property (nonatomic, retain) riLevelLoader *levelLoader;

@property (nonatomic, assign) cpSpace *space;
@property (nonatomic, retain) SpaceManagerCocos2d *spaceManager;

@property (nonatomic, readonly) CCParallaxNode *parallaxNode;

@property (nonatomic, retain) CCTMXLayer *background;
@property (nonatomic, assign) int currentLevel;

@property (nonatomic, readonly) NSMutableArray * actorsArray;
@property (nonatomic, readonly) Player * player;


- (void)addWeaponAt:(CGPoint)pt;

-(void)addTower: (CGPoint)pos: (int)towerTag tileMap: (CCTMXTiledMap*)tiledMap;
- (BOOL) canBuildOnTilePosition:(CGPoint) pos tiledMap:(CCTMXTiledMap *) tiledMap;

- (void) back: (id) sender;

-(void) bulletStop:(riActor*)bullet;


@end