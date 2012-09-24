//
//  PlayLayer.m
//  supercell
//
//  Created by Feixue Yang on 12-01-23.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GameLayer.h"

#import "DataModel.h"
#import "GameHUD.h"
#import "SceneManager.h"

#import "riVerletRope.h"
#import "riActor.h"
#import "riLevelLoader.h"

#import "riJoystick.h"
#import "Player.h"

void bulletStopCallback(cpSpace *space, void *obj, void *data)
{
    GameLayer *game = data;
    riActor * bullet = (riActor *)obj;
    [game bulletStop:bullet];
    
}

void hitButterflyCallback(cpSpace *space, void *obj, void *data)
{
    GameLayer *game = data;
    riActor * actor = (riActor *)obj;
    
    if(actor.health <= actor.demage){
        [actor stopAction:actor.curMovement];
        
        int n = actor.score;
        for(int i = 1;i <= n; i++){
            riActor * coin = [riActor spriteWithFile:@"gold_coin_128_128.png"];
            coin.position = actor.position;
            coin.scale = 0.3;
            
            CCParticleSystemQuad * coinParticle = [CCParticleSystemQuad particleWithFile:@"CoinParticle.plist"];
            coinParticle.position = actor.position;
            coinParticle.autoRemoveOnFinish = YES;
            
            coin.curParticle = coinParticle;
            coin.curParticleToFollow = YES;
            
            [game addChild:coin z:kCoinZ];
            [game addChild:coinParticle z:kCoinParticleZ];
            
            float duration = 1.0 + 0.5 *i;
            
            [coin runAction:[CCSequence actions:[CCSpawn actions:[CCSequence actions:[CCScaleTo actionWithDuration:0.05 scale:0.3], [CCScaleTo actionWithDuration:1.45 scale:0.1],nil],[CCMoveTo actionWithDuration:duration position:ccp(abs(game.position.x),kWinHeight)],nil],
                             [CCCallFuncND actionWithTarget:game selector:@selector(coinStop:) data:coin],
                             nil]];
        }
        
        CCActionInterval * butterflyDead = [CCSpawn actions:
                                            [CCRepeat actionWithAction:[CCAnimate actionWithAnimation:[[CCAnimationCache sharedAnimationCache] animationByName:[NSString stringWithFormat:@"%@_dead",[actor name]]]] times:20],
                                            [CCFadeOut actionWithDuration:0.7],
                                            nil];
        
        [actor runAction:[CCSequence actions:butterflyDead,[CCCallFuncND actionWithTarget:game selector:@selector(butterflyDead:) data:actor], nil]];
        
        
        if([actor countType] == kCountLimitFinity)
            [[game levelLoader] increaseActorWithName:actor.name count:1 delay:2.0];
        
        [[game levelLoader] removeShapeOfActor:actor];
    }

}


@interface GameLayer (PrivateMethods)
- (void) handleCollisionWithhandleCollisionWithButterfly:(CollisionMoment)moment arbiter:(cpArbiter*)arb space:(cpSpace*)space;
@end


@implementation GameLayer

@synthesize gameTime = _gameTime;
@synthesize levelLoader = _levelLoader;

@synthesize spaceManager = _spaceManager;
@synthesize space = _space;

@synthesize parallaxNode = _parallaxNode;

@synthesize background = _background;

@synthesize currentLevel = _currentLevel;

@synthesize actorsArray = _actorsArray;
@synthesize player = _player;

enum {
    kTagSpriteSheet = 1,
};

-(id) init{
	self = [super init];
	if (!self) {
		return nil;
	}
    
    self.isTouchEnabled = YES;
    
    _gameTime = 0;
    _winSize = [[CCDirector sharedDirector] winSize];
    
    
    gameHUD = [GameHUD sharedHUD];
    [gameHUD schedule:@selector(updateMoney) interval: 2.0];
    
	_spaceManager = [[SpaceManagerCocos2d alloc] init];
	_spaceManager.constantDt = 1.0/55.0;
    _spaceManager.damping = 1.0;
    _spaceManager.rehashStaticEveryStep = YES;
    
    self.space = [_spaceManager space];
    
    _actorsArray = [[NSMutableArray alloc] init];
    _bulletsArray = [[NSMutableArray alloc] init];
    _deadActorsSet = [[NSMutableSet alloc] init];
    _deadBulletsSet = [[NSMutableSet alloc] init];
    
    _player = [[Player alloc] init];
    
    //Load TiledMAP
    _levelLoader = [[riLevelLoader alloc] initWithContentOfFile:@"Level0"];
    _levelLoader.spaceManager = _spaceManager;
    _levelLoader.space = _space;
    _levelLoader.gameLayer = self;
    
    if([_levelLoader hasSpaceBoundaries])
        [_levelLoader createSpaceBoundaries:_space];
    
    [_levelLoader addEverythingToSpace:_space gameLayer:self];
    
    _tiledMaps = [DataModel sharedDataModel].tiledMaps;
    _background = [[[_tiledMaps objectAtIndex:0] objectForKey:@"TiledMap"] layerNamed:@"Background"];

    
    _parallaxNode = [CCParallaxNode node];
    for(NSDictionary * tm in _tiledMaps){
        CCTMXTiledMap * tiledMap = [tm objectForKey:@"TiledMap"];
        int z = [[tm objectForKey:@"OrderZ"] intValue];
        CGPoint ratio = CGPointFromString([tm objectForKey:@"Ratio"]);
        CGPoint offset = CGPointFromString([tm objectForKey:@"Offset"]);
        tiledMap.tag = z;
        [_parallaxNode addChild:tiledMap z:z parallaxRatio:ratio positionOffset:offset];
    }

    [self addChild:_parallaxNode z:kParallaxNodeZ tag:kParallaxNodeTag];
    
    self.position = ccp(0,0);

    ropeSegmentSpriteBatchNode = [CCSpriteBatchNode batchNodeWithFile:@"rope.png" ]; 
    [ropeSegmentSpriteBatchNode retain];
    [self addChild:ropeSegmentSpriteBatchNode z:10]; 

    self.currentLevel = 0;

    
	CCMenuItemFont *back = [CCMenuItemFont itemFromString:@"back" target:self selector: @selector(back:)];
	CCMenu *menu = [CCMenu menuWithItems: back, nil];
	menu.position = ccp(160, 150);
	[gameHUD addChild: menu];
    
    
    
    [self schedule:@selector(update:)];
    [self schedule:@selector(gameLogic:) interval:0.2];	
    
    [_spaceManager addCollisionCallbackBetweenType:kButterflyCollisionType 
								otherType:kBulletCollisionType 
								   target:self 
								 selector:@selector(handleCollisionWithButterfly:arbiter:space:)
                                  moments:COLLISION_BEGIN, nil];
    
	[_spaceManager start]; 
    
	return self;
}

- (void) dealloc
{
    [_spaceManager stop];

    self.levelLoader = nil;
    
    [self removeAllChildrenWithCleanup:YES];

    [verletRope release];
    verletRope = nil;

    [ropeSegmentSpriteBatchNode release];
    ropeSegmentSpriteBatchNode = nil;

    
    [actorSpriteBatchNode release];
    actorSpriteBatchNode = nil;
    
    [_spaceManager release];
    _spaceManager = nil;
    
    
    [[CCSpriteFrameCache sharedSpriteFrameCache] removeUnusedSpriteFrames];
    
    
    [[DataModel sharedDataModel].waypoints removeAllObjects];
    [[DataModel sharedDataModel].tiledMaps removeAllObjects];


    [[gameHUD joystick] resetJoystick];
    
    [_actorsArray release];
    _actorsArray = nil;
    
    [_bulletsArray release];
    _bulletsArray = nil;
    
    [_deadActorsSet release];
    _deadActorsSet = nil;
    
    [_deadBulletsSet release];
    _deadBulletsSet = nil;
    
    [_player release];
    _player = nil;
    
	[super dealloc];
}

- (void) addBackgroundParticle
{
    CCParticleSystemQuad * dandelionParticle = [CCParticleSystemQuad particleWithFile:@"DandelionParticle.plist"];
    dandelionParticle.position = ccp(_winSize.width/2,_winSize.height/2);
    dandelionParticle.autoRemoveOnFinish = YES;
    [self addChild:dandelionParticle z:kDandelionParticleZ];
}

- (CGPoint) tileCoordForPosition:(CGPoint) position tiledMap:(CCTMXTiledMap *) tiledMap
{
	int x = position.x / tiledMap.tileSize.width;
	int y = ((tiledMap.mapSize.height * tiledMap.tileSize.height) - position.y) / tiledMap.tileSize.height;
	
	return ccp(x,y);
}

- (BOOL) canBuildOnTilePosition:(CGPoint) pos tiledMap:(CCTMXTiledMap *) tiledMap
{
	CGPoint towerLoc = [self tileCoordForPosition: pos tiledMap:tiledMap];
	
	int tileGid = [self.background tileGIDAt:towerLoc];
	NSDictionary *props = [tiledMap propertiesForGID:tileGid];
	NSString *type = [props valueForKey:@"buildable"];
	
	if([type isEqualToString: @"1"]) {
		return YES;
	}
	
	return NO;
}

-(void)addTower: (CGPoint)pos: (int)towerTag tileMap: (CCTMXTiledMap*)tiledMap{
	
	Tower *target = nil;
    
	CGPoint towerLoc = [self tileCoordForPosition: pos tiledMap:tiledMap];
	
	int tileGid = [self.background tileGIDAt:towerLoc];
	NSDictionary *props = [tiledMap propertiesForGID:tileGid];
	NSString *type = [props valueForKey:@"buildable"];
	
	
	NSLog(@"Buildable: %@", type);
	if([type isEqualToString: @"1"]) {
        
        
        switch (towerTag) {
            case 1:
                if (gameHUD.money >= 25) {
                    target = [MachineGunTower tower];
                    [gameHUD updateMoney:-25];
                }
                else
                    return;
                break;
            case 2:
                if (gameHUD.money >= 35) {
                    target = [FreezeTower tower];
                    [gameHUD updateMoney:-35];
                }
                else
                    return;
                break;
            case 3:
                if (gameHUD.money >= 25) {
                    target = [MachineGunTower tower];
                    [gameHUD updateMoney:-25];
                }
                else
                    return;
                break;
            case 4:
                if (gameHUD.money >= 25) {
                    target = [MachineGunTower tower];
                    [gameHUD updateMoney:-25];
                }  
                else
                    return;
                break;
            default:
                break;
        }
        
		target.position = ccp((towerLoc.x * 32) + 16, tiledMap.contentSize.height - (towerLoc.y * 32) - 16);
		[self addChild:target z:1];
		
		target.tag = 1;        
		
	} else {
		NSLog(@"Tile Not Buildable");
	}
	
}


-(void)gameLogic:(ccTime)dt {

    _gameTime = _gameTime + dt;
    [_levelLoader step];
    
    if(_bulletsArray != nil && [_bulletsArray count] > 0){
        NSLog(@"BulletsArray count = %d",[_bulletsArray count]);
        NSLog(@"ActorsArray count = %d",[_actorsArray count]);

        for(riActor * b in _bulletsArray){
            int w = [b boundingBox].size.width;
            
            BOOL hitted = NO;
            if(_actorsArray != nil && [_actorsArray count] > 0){
                for(riActor * a in _actorsArray){
                    int dis = cpvdist(a.position, b.position);
                    if (dis <= (w/2 + kBulletAccuracyFactor)) {
                        [_deadActorsSet addObject:a];
                        hitted = YES;

                    }
                }
            }
                
            if (hitted) {
                [_deadBulletsSet addObject:b];

                for(riActor * a in _deadActorsSet){
                    [_levelLoader removeActor:a cleanupShape:YES];
                    [[GameHUD sharedHUD] updateMoney:a.score];
                }
                hitted = NO;
            }
        }
        
        for(riActor * a in _deadBulletsSet){
            [self bulletStop:a];
        }
        
        [_deadActorsSet removeAllObjects];
        [_deadBulletsSet removeAllObjects];
        
    }
}

- (void)update:(ccTime)dt {
    if(verletRope != nil)
        [verletRope update:dt];
}


- (CGPoint)boundLayerPos:(CGPoint)newPos tiledMap:(CCTMXTiledMap*)tiledMap {

    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CGPoint retval = newPos;
    retval.x = MIN(retval.x, 0);
    retval.x = MAX(retval.x, -tiledMap.contentSize.width+winSize.width); 
    retval.y = MIN(0, retval.y);
    retval.y = MAX(-tiledMap.contentSize.height+winSize.height, retval.y); 
    return retval;
}

- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer {
    CCTMXTiledMap * tiledMap = [[_tiledMaps objectAtIndex:0] objectForKey:@"TiledMap"];
    if (recognizer.state == UIGestureRecognizerStateBegan) {    
        
        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];                
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {    
        
        CGPoint translation = [recognizer translationInView:recognizer.view];
        translation = ccp(translation.x, -translation.y);
        CGPoint newPos = ccpAdd(self.position, translation);
        self.position = [self boundLayerPos:newPos tiledMap:tiledMap ];  
        [recognizer setTranslation:CGPointZero inView:recognizer.view];    
        
    } else if (recognizer.state == UIGestureRecognizerStateEnded) {
        
		float scrollDuration = 0.2;
		CGPoint velocity = [recognizer velocityInView:recognizer.view];
		CGPoint newPos = ccpAdd(self.position, ccpMult(ccp(velocity.x, velocity.y * -1), scrollDuration));
		newPos = [self boundLayerPos:newPos tiledMap:tiledMap];
        
		[self stopAllActions];
		CCMoveTo *moveTo = [CCMoveTo actionWithDuration:scrollDuration position:newPos];            
		[self runAction:[CCEaseOut actionWithAction:moveTo rate:1]];            
        
    }        
}

-(void)draw
{
	[super draw];
    if(verletRope != nil)
        [verletRope updateSprites];
    
}

-(void) back: (id) sender{
	[SceneManager goMenu];
}

-(void) bulletStop:(riActor*)bullet{
    if(bullet != nil){
        CCParticleSystemQuad * bulletExplosionParticle = [CCParticleSystemQuad particleWithFile:@"BulletExplosionParticle.plist"];
        bulletExplosionParticle.position = bullet.position;
        bulletExplosionParticle.autoRemoveOnFinish = YES;
        [self addChild:bulletExplosionParticle z:kBulletParticleZ];
        
        if ([bullet shape] != nil) 
            [[self spaceManager] removeAndFreeShape:[bullet shape]];
        [_bulletsArray removeObject:bullet];
        [self removeChild:bullet cleanup:YES]; 
    }
}

-(void) butterflyDead:(riActor*)actor{
    if(actor != nil){
        [[GameHUD sharedHUD] updateMoney:actor.score];
        [_levelLoader removeActor:actor cleanupShape:NO];
    }
}

-(void) coinStop:(riActor*)coin{
    [self removeChild:coin cleanup:YES];
}



#pragma mark Touch Functions
- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{	
	CGPoint pt = [self convertTouchToNodeSpace:[touches anyObject]];
    _touchBeginPos = pt;
    _touchBeginTime = [[NSDate date] timeIntervalSince1970];

    
	//Reset Scene
    if ([touches count] > 1)
    {
        CCScene *scene = [CCScene node];
        [scene addChild:[GameLayer node]];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:.4 scene:scene  withColor:ccBLUE]];
    }
}

- (void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{	
    
    UITouch * touch = [touches anyObject];
    
    CGPoint pt = [self convertTouchToNodeSpace:touch];
    _touchEndPos = pt;
    _touchEndTime = [[NSDate date] timeIntervalSince1970];

    
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{	
    CGPoint pt = [self convertTouchToNodeSpace:[touches anyObject]];
    
    _touchEndPos = pt;
    _touchEndTime = [[NSDate date] timeIntervalSince1970];

    float touchTime = _touchEndTime - _touchBeginTime;
    CGPoint touchMove = ccpSub(_touchEndPos, _touchBeginPos);
    float touchDistance = ccpLength(touchMove);
    if (touchTime < 0.001) touchTime = 0.001;
    
    
    CGPoint bulletPos = ccp(kBulletAccuracyFactor*(int)(pt.x/kBulletAccuracyFactor + 0.5),kBulletAccuracyFactor*(int)(pt.y/kBulletAccuracyFactor + 0.5));
    
    if(touchDistance < kFingerNoMovementFactor || touchTime > kFingerTouchTimeFactor){
        
        riActor * bullet = [riActor spriteWithFile:@"Circle_1024_1024.png"];
        bullet.gameLayer = self;
        bullet.scale = 0.01;
        bullet.power = 1;
        bullet.life = 30;
        bullet.position = bulletPos;
        
        [bullet runAction:[CCSequence actions:[CCEaseOut actionWithAction:[CCScaleTo actionWithDuration:bullet.life scale:0.5] rate:2] ,[CCCallFuncND actionWithTarget:self selector:@selector(bulletStop:) data:bullet],nil]];
        
//        [gameHUD updateMoney:bullet.score - 1];
//        
//        cpShape * bulletShape = [_spaceManager addCircleAt:_touchEndPos mass:INFINITY radius:6];
//        bulletShape->collision_type = kBulletCollisionType;
//        bulletShape->group = 1;
//        bullet.shape = bulletShape;
        
        CCParticleSystemQuad * bulletParticle = [CCParticleSystemQuad particleWithFile:@"BulletParticle.plist"];
        bulletParticle.position = bulletPos;
        bulletParticle.autoRemoveOnFinish = YES;
        bullet.curParticle = bulletParticle;
        [self addChild:bullet z:kBulletZ tag:kBulletTag];
        [_bulletsArray addObject:bullet];
        [self addChild:bulletParticle z:kBulletParticleZ];

    }else{
        for(riActor * b in _bulletsArray){
            if([b touchedInLayer:self withTouchs:touches])
                break;
        }
        
    }
	
}

- (void) handleCollisionWithButterfly:(CollisionMoment)moment arbiter:(cpArbiter*)arb space:(cpSpace*)space
{	
    CP_ARBITER_GET_SHAPES(arb,a,b);
    cpSpaceAddPostStepCallback(_space, hitButterflyCallback, a->data, self);
    cpSpaceAddPostStepCallback(_space, bulletStopCallback, b->data, self);

    riActor * actor = (riActor *)a->data;
    riActor * bullet = (riActor *)b->data;
    
    actor.demage = actor.demage + bullet.power;
    bullet.score ++;

    
}



@end