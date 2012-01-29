//
//  PlayLayer.h
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BaseLayer.h"

#import "SceneManager.h"
#import "GameHUD.h"
#import "DataModel.h"

#import "Creep.h"
#import "Projectile.h"
#import "Tower.h"
#import "WayPoint.h"
#import "Wave.h"

@interface GameLayer : BaseLayer {
    CCTMXTiledMap *_tileMap;
    CCTMXLayer *_background;	

	GameHUD * gameHUD;
}

@property (nonatomic, retain) CCTMXTiledMap *tileMap;
@property (nonatomic, retain) CCTMXLayer *background;

@property (nonatomic, assign) int currentLevel;


- (void)addWaves;
- (void)addWaypoint;
- (void)addTower: (CGPoint)pos: (int)towerTag;
- (BOOL) canBuildOnTilePosition:(CGPoint) pos;

- (void) back: (id) sender;

@end